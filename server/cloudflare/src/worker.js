/**
 * Bloom Relay Server - Cloudflare Worker & Durable Objects
 * Zero-knowledge, stateless encrypted peer-to-peer WebSocket relay
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const upgradeHeader = (request.headers.get('Upgrade') || request.headers.get('upgrade') || '').toLowerCase();
    const isWebSocket = upgradeHeader === 'websocket';

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

    // In-memory maps for fast lookups
    this.devices = new Map(); // deviceId -> WebSocket
    this.wsToDeviceId = new Map(); // WebSocket -> deviceId
    this.pairingCodes = new Map(); // pairingCode -> { deviceId, deviceName, createdAt }
    this.pendingRequests = new Map(); // requestId -> { from, to, dataTypes, timestamp }
  }

  getSocket(deviceId) {
    if (this.devices.has(deviceId)) {
      const s = this.devices.get(deviceId);
      try {
        if (s.readyState === 1) return s;
      } catch (_) {}
    }
    // Search across all accepted WebSockets using attachments
    for (const ws of this.ctx.getWebSockets()) {
      try {
        const att = ws.deserializeAttachment();
        if (att && att.deviceId === deviceId) {
          this.devices.set(deviceId, ws);
          return ws;
        }
      } catch (_) {}
    }
    return null;
  }

  getPairingCodeOwner(code) {
    if (this.pairingCodes.has(code)) {
      return this.pairingCodes.get(code);
    }
    for (const ws of this.ctx.getWebSockets()) {
      try {
        const att = ws.deserializeAttachment();
        if (att && att.pairingCode === code && att.deviceId) {
          return { deviceId: att.deviceId, deviceName: att.deviceName || 'Bloom User' };
        }
      } catch (_) {}
    }
    return null;
  }

  async fetch(request) {
    const upgradeHeader = (request.headers.get('Upgrade') || request.headers.get('upgrade') || '').toLowerCase();
    if (upgradeHeader !== 'websocket') {
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
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'Invalid JSON payload' }));
      } catch (_) {}
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
        try {
          ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
        } catch (_) {}
        break;
      default:
        console.log(`[Bloom DO] Unknown message type: ${message.type}`);
    }
  }

  handleRegister(ws, message) {
    const { deviceId } = message;
    if (!deviceId) return;

    this.devices.set(deviceId, ws);
    this.wsToDeviceId.set(ws, deviceId);

    try {
      const prev = ws.deserializeAttachment() || {};
      ws.serializeAttachment({ ...prev, deviceId });
    } catch (_) {}

    try {
      ws.send(
        JSON.stringify({
          type: 'registered',
          deviceId: deviceId,
          timestamp: Date.now(),
        })
      );
    } catch (_) {}

    this.broadcastDeviceList();
  }

  handlePairRequest(ws, message) {
    const { pairingCode, deviceId, deviceName } = message;
    if (!pairingCode || !deviceId) {
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'pairingCode and deviceId required' }));
      } catch (_) {}
      return;
    }

    const code = pairingCode.toUpperCase();
    this.devices.set(deviceId, ws);
    this.wsToDeviceId.set(ws, deviceId);

    try {
      const prev = ws.deserializeAttachment() || {};
      ws.serializeAttachment({ ...prev, deviceId, pairingCode: code, deviceName: deviceName || 'Bloom User' });
    } catch (_) {}

    const owner = this.getPairingCodeOwner(code);

    if (owner && owner.deviceId !== deviceId) {
      const partnerWs = this.getSocket(owner.deviceId);
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

      try {
        ws.send(
          JSON.stringify({
            type: 'pair_request_sent',
            partnerDeviceId: owner.deviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    } else {
      this.pairingCodes.set(code, {
        deviceId: deviceId,
        deviceName: deviceName,
        createdAt: Date.now(),
      });

      try {
        ws.send(
          JSON.stringify({
            type: 'pair_code_registered',
            code: code,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }
  }

  handlePairAccept(ws, message) {
    const { fromDeviceId, deviceId } = message;

    const partnerWs = this.getSocket(fromDeviceId);
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

    try {
      ws.send(
        JSON.stringify({
          type: 'pair_accepted',
          partnerDeviceId: fromDeviceId,
          timestamp: Date.now(),
        })
      );
    } catch (_) {}
  }

  handleSyncRequest(ws, message) {
    const { fromDeviceId, toDeviceId, requestId, dataTypes } = message;
    if (!fromDeviceId || !toDeviceId) {
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'fromDeviceId and toDeviceId required' }));
      } catch (_) {}
      return;
    }

    const reqId = requestId || crypto.randomUUID();
    this.pendingRequests.set(reqId, {
      from: fromDeviceId,
      to: toDeviceId,
      dataTypes: dataTypes || ['cycles', 'notes'],
      timestamp: Date.now(),
    });

    const targetWs = this.getSocket(toDeviceId);
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
        try {
          ws.send(JSON.stringify({ type: 'error', message: 'Failed to notify partner device' }));
        } catch (_) {}
      }
    } else {
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'Partner device not connected' }));
      } catch (_) {}
    }
  }

  handleSyncApproved(ws, message) {
    const { requestId, deviceId } = message;
    const request = this.pendingRequests.get(requestId);

    if (!request) {
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'Request not found' }));
      } catch (_) {}
      return;
    }

    const sourceWs = this.getSocket(request.from);
    if (sourceWs) {
      try {
        sourceWs.send(
          JSON.stringify({
            type: 'sync_approved',
            requestId: requestId,
            fromDeviceId: deviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }
  }

  handleSyncDenied(ws, message) {
    const { requestId } = message;
    const request = this.pendingRequests.get(requestId);

    if (request) {
      const sourceWs = this.getSocket(request.from);
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
    const { toDeviceId, payload, iv } = message;
    const targetWs = this.getSocket(toDeviceId);

    if (targetWs) {
      try {
        targetWs.send(
          JSON.stringify({
            type: 'sync_data',
            fromDeviceId: message.fromDeviceId,
            payload: payload,
            iv: iv,
            timestamp: Date.now(),
          })
        );
      } catch (_) {
        try {
          ws.send(JSON.stringify({ type: 'error', message: 'Failed to deliver sync data to partner' }));
        } catch (_) {}
      }
    }
  }

  handleSyncComplete(ws, message) {
    const { toDeviceId } = message;
    const targetWs = this.getSocket(toDeviceId);

    if (targetWs) {
      try {
        targetWs.send(
          JSON.stringify({
            type: 'sync_complete',
            fromDeviceId: message.fromDeviceId,
            timestamp: Date.now(),
          })
        );
      } catch (_) {}
    }
  }

  broadcastDeviceList() {
    const activeDeviceIds = [];
    for (const ws of this.ctx.getWebSockets()) {
      try {
        const att = ws.deserializeAttachment();
        if (att && att.deviceId) {
          activeDeviceIds.push(att.deviceId);
        }
      } catch (_) {}
    }

    const payload = JSON.stringify({
      type: 'device_list',
      count: activeDeviceIds.length,
      timestamp: Date.now(),
    });

    for (const ws of this.ctx.getWebSockets()) {
      try {
        ws.send(payload);
      } catch (_) {}
    }
  }

  async webSocketClose(ws, code, reason, wasClean) {
    const deviceId = this.wsToDeviceId.get(ws);
    if (deviceId) {
      this.devices.delete(deviceId);
      this.wsToDeviceId.delete(ws);
    }
    this.broadcastDeviceList();
  }

  async webSocketError(ws, error) {
    const deviceId = this.wsToDeviceId.get(ws);
    if (deviceId) {
      this.devices.delete(deviceId);
      this.wsToDeviceId.delete(ws);
    }
  }
}
