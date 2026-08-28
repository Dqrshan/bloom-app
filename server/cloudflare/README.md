# Deploying Bloom Relay to Cloudflare Workers

Bloom's zero-knowledge relay server can be deployed to **Cloudflare Workers** in under 2 minutes.

---

## Prerequisites
1. A free [Cloudflare Account](https://dash.cloudflare.com/sign-up).
2. [Node.js](https://nodejs.org) installed on your computer.

---

## 🚀 Quick Deploy (2 Steps)

### Step 1: Install Wrangler & Log in to Cloudflare
From your terminal:
```bash
# Navigate to the cloudflare directory
cd server/cloudflare

# Log in to your Cloudflare account (opens browser)
npx wrangler login
```

### Step 2: Deploy
```bash
npx wrangler deploy
```

Once deployment completes, Wrangler will output your live URL:
```
Published bloom-relay (0.85 sec)
  https://bloom-relay.<your-subdomain>.workers.dev
```

---

## 📱 Connecting the Bloom Flutter App

Your WebSocket endpoint is:
```
wss://bloom-relay.<your-subdomain>.workers.dev/ws
```

In the Flutter app ([`lib/services/sync_service.dart`](../../lib/services/sync_service.dart)):
Set `_serverUrl = 'wss://bloom-relay.<your-subdomain>.workers.dev/ws';` or configure it via developer settings.

---

## 🔒 Architecture & Security

* **Zero-Knowledge**: Cloudflare never decrypts or stores personal data; it only relays encrypted payloads between paired devices.
* **Global Edge Network**: Low-latency WebSocket connections via Cloudflare's 300+ edge locations.
* **Durable Objects & Hibernation**: Uses the Cloudflare Hibernation API to maintain persistent connections with zero idle compute costs (100% free tier friendly).
