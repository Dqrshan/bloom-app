const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const PORT = process.env.PORT || 3000;

const wss = new WebSocket.Server({ port: PORT });

// Connected devices: Map<deviceId, WebSocket>
const devices = new Map();

// Pairing codes: Map<pairingCode, {deviceId, createdAt}>
const pairingCodes = new Map();

// Pending sync requests: Map<requestId, {from, to, timestamp}>
const pendingRequests = new Map();

console.log(`[Bloom Relay] Server starting on port ${PORT}`);

wss.on('connection', (ws) => {
  const connectionId = uuidv4().slice(0, 8);
  console.log(`[Bloom Relay] New connection: ${connectionId}`);

  let registeredDeviceId = null;

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleMessage(ws, message, connectionId);
    } catch (e) {
      console.error(`[Bloom Relay] Invalid message from ${connectionId}:`, e.message);
      ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }));
    }
  });

  ws.on('close', () => {
    if (registeredDeviceId) {
      devices.delete(registeredDeviceId);
      console.log(`[Bloom Relay] Device disconnected: ${registeredDeviceId}`);
      broadcastDeviceList();
    }
    console.log(`[Bloom Relay] Connection closed: ${connectionId}`);
  });

  ws.on('error', (error) => {
    console.error(`[Bloom Relay] Error from ${connectionId}:`, error.message);
  });

  function handleMessage(ws, message, connId) {
    switch (message.type) {
      case 'register':
        handleRegister(ws, message, connId);
        break;
      case 'pair_request':
        handlePairRequest(ws, message, connId);
        break;
      case 'pair_accept':
        handlePairAccept(ws, message, connId);
        break;
      case 'sync_request':
        handleSyncRequest(ws, message, connId);
        break;
      case 'sync_approved':
        handleSyncApproved(ws, message, connId);
        break;
      case 'sync_denied':
        handleSyncDenied(ws, message, connId);
        break;
      case 'sync_data':
        handleSyncData(ws, message, connId);
        break;
      case 'sync_complete':
        handleSyncComplete(ws, message, connId);
        break;
      case 'ping':
        ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
        break;
      default:
        console.log(`[Bloom Relay] Unknown message type: ${message.type}`);
    }
  }

  function handleRegister(ws, message, connId) {
    const { deviceId } = message;
    if (!deviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'deviceId required' }));
      return;
    }

    registeredDeviceId = deviceId;
    devices.set(deviceId, ws);
    console.log(`[Bloom Relay] Device registered: ${deviceId}`);

    ws.send(JSON.stringify({
      type: 'registered',
      deviceId: deviceId,
      timestamp: Date.now()
    }));

    broadcastDeviceList();
  }

  function handlePairRequest(ws, message, connId) {
    const { pairingCode, deviceId, deviceName } = message;
    if (!pairingCode || !deviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'pairingCode and deviceId required' }));
      return;
    }

    const code = pairingCode.toUpperCase();
    const existing = pairingCodes.get(code);

    if (existing && existing.deviceId !== deviceId) {
      // Partner found - notify them
      const partnerWs = devices.get(existing.deviceId);
      if (partnerWs && partnerWs.readyState === WebSocket.OPEN) {
        partnerWs.send(JSON.stringify({
          type: 'pair_request',
          fromDeviceId: deviceId,
          deviceName: deviceName || 'Partner',
          timestamp: Date.now()
        }));
      }

      ws.send(JSON.stringify({
        type: 'pair_request_sent',
        partnerDeviceId: existing.deviceId,
        timestamp: Date.now()
      }));
    } else {
      // Store this device's pairing code
      pairingCodes.set(code, {
        deviceId: deviceId,
        deviceName: deviceName,
        createdAt: Date.now()
      });

      ws.send(JSON.stringify({
        type: 'pair_code_registered',
        code: code,
        timestamp: Date.now()
      }));
    }
  }

  function handlePairAccept(ws, message, connId) {
    const { fromDeviceId, deviceId } = message;

    const partnerWs = devices.get(fromDeviceId);
    if (partnerWs && partnerWs.readyState === WebSocket.OPEN) {
      partnerWs.send(JSON.stringify({
        type: 'pair_accepted',
        partnerDeviceId: deviceId,
        timestamp: Date.now()
      }));
    }

    ws.send(JSON.stringify({
      type: 'pair_accepted',
      partnerDeviceId: fromDeviceId,
      timestamp: Date.now()
    }));
  }

  function handleSyncRequest(ws, message, connId) {
    const { fromDeviceId, toDeviceId, requestId, dataTypes } = message;
    if (!fromDeviceId || !toDeviceId) {
      ws.send(JSON.stringify({ type: 'error', message: 'fromDeviceId and toDeviceId required' }));
      return;
    }

    const reqId = requestId || uuidv4();
    pendingRequests.set(reqId, {
      from: fromDeviceId,
      to: toDeviceId,
      dataTypes: dataTypes || ['cycles', 'notes'],
      timestamp: Date.now()
    });

    const targetWs = devices.get(toDeviceId);
    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
      targetWs.send(JSON.stringify({
        type: 'sync_request',
        requestId: reqId,
        fromDeviceId: fromDeviceId,
        timestamp: Date.now()
      }));
    } else {
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Partner device not connected'
      }));
    }
  }

  function handleSyncApproved(ws, message, connId) {
    const { requestId, deviceId } = message;
    const request = pendingRequests.get(requestId);

    if (!request) {
      ws.send(JSON.stringify({ type: 'error', message: 'Request not found' }));
      return;
    }

    const sourceWs = devices.get(request.from);
    if (sourceWs && sourceWs.readyState === WebSocket.OPEN) {
      sourceWs.send(JSON.stringify({
        type: 'sync_approved',
        requestId: requestId,
        toDeviceId: deviceId,
        timestamp: Date.now()
      }));
    }

    pendingRequests.delete(requestId);
  }

  function handleSyncDenied(ws, message, connId) {
    const { requestId, deviceId } = message;
    const request = pendingRequests.get(requestId);

    if (request) {
      const sourceWs = devices.get(request.from);
      if (sourceWs && sourceWs.readyState === WebSocket.OPEN) {
        sourceWs.send(JSON.stringify({
          type: 'sync_denied',
          requestId: requestId,
          timestamp: Date.now()
        }));
      }
      pendingRequests.delete(requestId);
    }
  }

  function handleSyncData(ws, message, connId) {
    const { fromDeviceId, toDeviceId, payload, iv, timestamp } = message;
    if (!fromDeviceId || !toDeviceId || !payload) {
      ws.send(JSON.stringify({ type: 'error', message: 'Missing required fields' }));
      return;
    }

    // Relay the encrypted data to the target device
    const targetWs = devices.get(toDeviceId);
    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
      targetWs.send(JSON.stringify({
        type: 'sync_data',
        fromDeviceId: fromDeviceId,
        payload: payload,
        iv: iv,
        timestamp: timestamp || Date.now()
      }));

      ws.send(JSON.stringify({
        type: 'sync_data_sent',
        toDeviceId: toDeviceId,
        timestamp: Date.now()
      }));
    } else {
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Target device not connected'
      }));
    }
  }

  function handleSyncComplete(ws, message, connId) {
    const { fromDeviceId, toDeviceId } = message;

    const targetWs = devices.get(toDeviceId);
    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
      targetWs.send(JSON.stringify({
        type: 'sync_complete',
        fromDeviceId: fromDeviceId,
        timestamp: Date.now()
      }));
    }
  }

  function broadcastDeviceList() {
    const deviceList = Array.from(devices.keys());
    const message = JSON.stringify({
      type: 'devices',
      deviceList: deviceList.join(','),
      count: deviceList.length
    });

    devices.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      }
    });
  }
});

// Cleanup old pairing codes every hour
setInterval(() => {
  const now = Date.now();
  const maxAge = 24 * 60 * 60 * 1000; // 24 hours

  for (const [code, data] of pairingCodes) {
    if (now - data.createdAt > maxAge) {
      pairingCodes.delete(code);
      console.log(`[Bloom Relay] Expired pairing code: ${code}`);
    }
  }

  // Cleanup old pending requests
  for (const [id, request] of pendingRequests) {
    if (now - request.timestamp > 5 * 60 * 1000) { // 5 minutes
      pendingRequests.delete(id);
      console.log(`[Bloom Relay] Expired pending request: ${id}`);
    }
  }
}, 60 * 60 * 1000);

// Health check endpoint
wss.on('listening', () => {
  console.log(`[Bloom Relay] Server is running on port ${PORT}`);
  console.log(`[Bloom Relay] WebSocket endpoint: ws://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[Bloom Relay] Shutting down...');
  wss.close(() => {
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('[Bloom Relay] Shutting down...');
  wss.close(() => {
    process.exit(0);
  });
});
