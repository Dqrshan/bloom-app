/**
 * Bloom Relay Server - Cloudflare Worker & Durable Objects
 * Zero-knowledge, stateless encrypted peer-to-peer WebSocket relay
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const isWebSocket = (request.headers.get('Upgrade') || request.headers.get('upgrade') || '').toLowerCase() === 'websocket';

    // Route WebSocket connections to the singleton Durable Object
    if (isWebSocket) {
      const id = env.BLOOM_RELAY.idFromName('global-relay');
      const relayObject = env.BLOOM_RELAY.get(id);
      return relayObject.fetch(request);
    }

    // Health check endpoint for standard HTTP GET
    return new Response(
      JSON.stringify({
        status: 'ok',
        service: 'Bloom E2EE Relay',
        version: '1.0.0',
        websocket_url: `wss://${url.host}/ws`,
        time: new Date().toISOString(),
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    );
  },
};

export class BloomRelayDO {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;

    // In-memory maps for active peers
    this.devices = new Map(); // deviceId -> WebSocket
    this.wsToDeviceId = new Map(); // WebSocket -> deviceId
    this.pairingCodes = new Map(); // pairingCode -> { deviceId, deviceName, createdAt }
    this.pendingRequests = new Map(); // requestId -> { from, to, dataTypes, timestamp }
  }

  async fetch(request) {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected WebSocket upgrade', { status: 426 });
    }

    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);

    // Accept WebSocket with Cloudflare Hibernation API
    this.ctx.acceptWebSocket(server);

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async webSocketMessage(ws, message) {
    try {
      const data = JSON.parse(message);
      this.handleMessage(ws, data);
    } catch (e) {
      ws.send(JSON.stringify({ type: 'error', message: 'Invalid JSON payload' }));
    }
  }

  handleMessage(ws, message) {
    switch (message.type) {
      case 'register':
        this.handleRegister(ws, message);
        break;
      case 'pair_request':
        this.handlePairRequest(ws, message);
        break;
      case 'pair_accept':
        this.handlePairAccept(ws, message);
        break;
      case 'sync_request':
        this.handleSyncRequest(ws, message);
        break;
      case 'sync_approved':
        this.handleSyncApproved(ws, message);
        break;
      case 'sync_denied':
        this.handleSyncDenied(ws, message);
        break;
      case 'sync_data':
        this.handleSyncData(ws, message);
        break;
      case 'sync_complete':
        this.handleSyncComplete(ws, message);
        break;
      case 'ping':
        ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
        break;
      default:
        console.log(`[Bloom DO] Unknown message type: ${message.type}`);
    }
  }

  handleRegister(ws, message) {
    const { deviceId } = message;
    if (!deviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'deviceId required' }));
      return;
    }

    this.devices.set(deviceId, ws);
    this.wsToDeviceId.set(ws, deviceId);

    ws.send(
      JSON.stringify({
        type: 'registered',
        deviceId: deviceId,
        timestamp: Date.now(),
      })
    );

    this.broadcastDeviceList();
  }

  handlePairRequest(ws, message) {
    const { pairingCode, deviceId, deviceName } = message;
    if (!pairingCode || !deviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'pairingCode and deviceId required' }));
      return;
    }

    const code = pairingCode.toUpperCase();
    const existing = this.pairingCodes.get(code);

    if (existing && existing.deviceId !== deviceId) {
      const partnerWs = this.devices.get(existing.deviceId);
      if (partnerWs) {
        try {
          partnerWs.send(
            JSON.stringify({
              type: 'pair_request',
              fromDeviceId: deviceId,
              deviceName: deviceName || 'Partner',
              timestamp: Date.now(),
            })
          );
        } catch (_) {}
      }

      ws.send(
        JSON.stringify({
          type: 'pair_request_sent',
          partnerDeviceId: existing.deviceId,
          timestamp: Date.now(),
        })
      );
    } else {
      this.pairingCodes.set(code, {
        deviceId: deviceId,
        deviceName: deviceName,
        createdAt: Date.now(),
      });

      ws.send(
        JSON.stringify({
          type: 'pair_code_registered',
          code: code,
          timestamp: Date.now(),
        })
      );
    }
  }

  handlePairAccept(ws, message) {
    const { fromDeviceId, deviceId } = message;

    const partnerWs = this.devices.get(fromDeviceId);
    if (partnerWs) {
      try {
        partnerWs.send(
          JSON.stringify({
            type: 'pair_accepted',
            partnerDeviceId: deviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }

    ws.send(
      JSON.stringify({
        type: 'pair_accepted',
        partnerDeviceId: fromDeviceId,
        timestamp: Date.now(),
      })
    );
  }

  handleSyncRequest(ws, message) {
    const { fromDeviceId, toDeviceId, requestId, dataTypes } = message;
    if (!fromDeviceId || !toDeviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'fromDeviceId and toDeviceId required' }));
      return;
    }

    const reqId = requestId || crypto.randomUUID();
    this.pendingRequests.set(reqId, {
      from: fromDeviceId,
      to: toDeviceId,
      dataTypes: dataTypes || ['cycles', 'notes'],
      timestamp: Date.now(),
    });

    const targetWs = this.devices.get(toDeviceId);
    if (targetWs) {
      try {
        targetWs.send(
          JSON.stringify({
            type: 'sync_request',
            requestId: reqId,
            fromDeviceId: fromDeviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {
        ws.send(JSON.stringify({ type: 'error', message: 'Failed to notify partner device' }));
      }
    } else {
      ws.send(JSON.stringify({ type: 'error', message: 'Partner device not connected' }));
    }
  }

  handleSyncApproved(ws, message) {
    const { requestId, deviceId } = message;
    const request = this.pendingRequests.get(requestId);

    if (!request) {
      ws.send(JSON.stringify({ type: 'error', message: 'Request not found' }));
      return;
    }

    const sourceWs = this.devices.get(request.from);
    if (sourceWs) {
      try {
        sourceWs.send(
          JSON.stringify({
            type: 'sync_approved',
            requestId: requestId,
            toDeviceId: deviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }

    this.pendingRequests.delete(requestId);
  }

  handleSyncDenied(ws, message) {
    const { requestId } = message;
    const request = this.pendingRequests.get(requestId);

    if (request) {
      const sourceWs = this.devices.get(request.from);
      if (sourceWs) {
        try {
          sourceWs.send(
            JSON.stringify({
              type: 'sync_denied',
              requestId: requestId,
              timestamp: Date.now(),
            })
          );
        } catch (_) {}
      }
      this.pendingRequests.delete(requestId);
    }
  }

  handleSyncData(ws, message) {
    const { fromDeviceId, toDeviceId, payload, iv, timestamp } = message;
    if (!fromDeviceId || !toDeviceId || !payload) {
      ws.send(JSON.stringify({ type: 'error', message: 'Missing required sync payload' }));
      return;
    }

    const targetWs = this.devices.get(toDeviceId);
    if (targetWs) {
      try {
        targetWs.send(
          JSON.stringify({
            type: 'sync_data',
            fromDeviceId: fromDeviceId,
            payload: payload,
            iv: iv,
            timestamp: timestamp || Date.now(),
          })
        );

        ws.send(
          JSON.stringify({
            type: 'sync_data_sent',
            toDeviceId: toDeviceId,
            timestamp: Date.now(),
          })
        );
      } catch (e) {
        ws.send(JSON.stringify({ type: 'error', message: 'Failed to relay encrypted data' }));
      }
    } else {
      ws.send(JSON.stringify({ type: 'error', message: 'Target device not connected' }));
    }
  }

  handleSyncComplete(ws, message) {
    const { fromDeviceId, toDeviceId } = message;
    const targetWs = this.devices.get(toDeviceId);
    if (targetWs) {
      try {
        targetWs.send(
          JSON.stringify({
            type: 'sync_complete',
            fromDeviceId: fromDeviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }
  }

  broadcastDeviceList() {
    const deviceList = Array.from(this.devices.keys());
    const message = JSON.stringify({
      type: 'devices',
      deviceList: deviceList.join(','),
      count: deviceList.length,
    });

    for (const ws of this.devices.values()) {
      try {
        ws.send(message);
      } catch (_) {}
    }
  }

  async webSocketClose(ws, code, reason, wasClean) {
    const deviceId = this.wsToDeviceId.get(ws);
    if (deviceId) {
      this.devices.delete(deviceId);
      this.wsToDeviceId.delete(ws);
      this.broadcastDeviceList();
    }
  }

  async webSocketError(ws, error) {
    const deviceId = this.wsToDeviceId.get(ws);
    if (deviceId) {
      this.devices.delete(deviceId);
      this.wsToDeviceId.delete(ws);
    }
  }
}
