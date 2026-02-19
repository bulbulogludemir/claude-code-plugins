---
name: chrome-extension
description: Chrome extension development with Manifest V3 and Plasmo
triggers:
  - chrome extension
  - manifest v3
  - content script
  - background script
  - plasmo
  - browser extension
  - eklenti
---

# Chrome Extension Development

Build Chrome extensions with Manifest V3 and optionally Plasmo framework.

## 1. Manifest V3 Template

```json
{
  "manifest_version": 3,
  "name": "My Extension",
  "version": "1.0.0",
  "description": "Description here",
  "permissions": ["storage", "activeTab"],
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/16.png",
      "48": "icons/48.png",
      "128": "icons/128.png"
    }
  },
  "background": {
    "service_worker": "background.js",
    "type": "module"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "css": ["content.css"]
    }
  ],
  "host_permissions": ["https://api.example.com/*"]
}
```

## 2. Background Service Worker

```typescript
// background.ts
chrome.runtime.onInstalled.addListener(() => {
  console.log('Extension installed')
})

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'FETCH_DATA') {
    fetch(message.url)
      .then((res) => res.json())
      .then((data) => sendResponse({ data }))
      .catch((error) => sendResponse({ error: error.message }))
    return true // Keep channel open for async response
  }
})

// Context menu
chrome.contextMenus.create({
  id: 'myAction',
  title: 'Do something',
  contexts: ['selection'],
})

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'myAction' && tab?.id) {
    chrome.tabs.sendMessage(tab.id, {
      type: 'CONTEXT_MENU_ACTION',
      text: info.selectionText,
    })
  }
})
```

## 3. Content Script

```typescript
// content.ts
function injectUI() {
  const container = document.createElement('div')
  container.id = 'my-extension-root'
  document.body.appendChild(container)
  // Render your UI into container
}

// Listen for messages from background
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'CONTEXT_MENU_ACTION') {
    console.log('Selected text:', message.text)
    sendResponse({ success: true })
  }
})

// Send message to background
async function fetchViaBackground(url: string) {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage({ type: 'FETCH_DATA', url }, (response) => {
      resolve(response.data)
    })
  })
}

// Run on page load
injectUI()
```

## 4. Popup

```html
<!-- popup.html -->
<!DOCTYPE html>
<html>
<head><link rel="stylesheet" href="popup.css" /></head>
<body>
  <div id="app"></div>
  <script src="popup.js" type="module"></script>
</body>
</html>
```

## 5. Storage API

```typescript
// Sync storage (small data, synced across devices)
await chrome.storage.sync.set({ key: 'value' })
const { key } = await chrome.storage.sync.get('key')

// Local storage (larger data, device-only)
await chrome.storage.local.set({ data: largeObject })
const { data } = await chrome.storage.local.get('data')

// Listen for changes
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'sync' && changes.key) {
    console.log('Changed:', changes.key.oldValue, '→', changes.key.newValue)
  }
})
```

## 6. Plasmo Framework

```bash
# Create Plasmo project
pnpm create plasmo my-extension
cd my-extension
pnpm dev  # Auto-reload in Chrome
```

### Plasmo Project Structure

```
my-extension/
├── src/
│   ├── popup.tsx          # Popup (React component)
│   ├── background.ts      # Background service worker
│   ├── content.tsx         # Content script (React)
│   ├── contents/           # Multiple content scripts
│   │   └── overlay.tsx
│   └── options.tsx         # Options page
├── assets/                 # Icons, images
├── package.json
└── tsconfig.json
```

### Plasmo Content Script (React)

```tsx
// src/contents/overlay.tsx
import type { PlasmoCSConfig } from 'plasmo'

export const config: PlasmoCSConfig = {
  matches: ['https://example.com/*'],
}

export default function Overlay() {
  return (
    <div style={{ position: 'fixed', bottom: 16, right: 16, zIndex: 99999 }}>
      <button onClick={() => console.log('Clicked!')}>
        My Extension
      </button>
    </div>
  )
}
```

### Plasmo Messaging

```typescript
// background/messages/getData.ts
import type { PlasmoMessaging } from '@plasmohq/messaging'

export type RequestBody = { url: string }
export type ResponseBody = { data: unknown }

const handler: PlasmoMessaging.MessageHandler<RequestBody, ResponseBody> = async (req, res) => {
  const response = await fetch(req.body.url)
  const data = await response.json()
  res.send({ data })
}

export default handler
```

## Dependencies

```bash
# Vanilla extension — no extra deps needed
# Plasmo
pnpm create plasmo my-extension
pnpm add @plasmohq/messaging @plasmohq/storage
```

## Gotchas

| Issue | Solution |
|-------|----------|
| Service worker inactive | Background scripts are event-driven in MV3, no persistent background |
| CORS in content script | Use background service worker for cross-origin fetches |
| Content script CSS leaks | Use Shadow DOM or CSS modules |
| `chrome.runtime.sendMessage` no response | Return `true` from listener for async |
| Popup closes on click outside | Use side panel API for persistent UI |
