# Bloom Relay Server

Secure WebSocket relay server for Bloom period tracker app.

## Features
- Pure relay - no data stored on server
- Device pairing via 6-character codes
- Sync request/approval flow
- Automatic cleanup of old codes and requests

## Deploy to Render

1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Settings:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment**: Node

4. Set environment variable:
   - `PORT`: 3000 (or let Render assign)

## Local Development

```bash
npm install
npm run dev
```

## Protocol

### Messages

| Type | Direction | Description |
|------|-----------|-------------|
| `register` | Client → Server | Register device with ID |
| `pair_request` | Client → Server | Send pairing request to partner |
| `pair_accept` | Client → Server | Accept incoming pair request |
| `sync_request` | Client → Server | Request data sync from partner |
| `sync_approved` | Client → Server | Approve incoming sync request |
| `sync_denied` | Client → Server | Deny incoming sync request |
| `sync_data` | Client → Server | Send encrypted sync data |
| `sync_complete` | Client → Server | Confirm sync completion |

### Security
- All data is encrypted client-side with AES-256-GCM
- Server only relays encrypted payloads
- No plaintext data ever reaches the server
- Pairing codes expire after 24 hours
- Pending sync requests expire after 5 minutes
