# Nightingale Architecture

## Overview

Nightingale consists of three main components:
1. **Runner (Ruby)**: Executes the user's script and generates a component tree.
2. **Server (Sinatra)**: Serves the frontend and manages WebSocket connections.
3. **Frontend (React)**: Renders the component tree and sends events back to the server.

## Communication Protocol

Nightingale uses WebSockets for real-time communication.

### Server -> Client (`render`)

The server sends the full component tree to the client.

```json
{
  "type": "render",
  "components": [
    { "type": "title", "props": { "text": "My App" } },
    { "type": "button", "id": "btn1", "props": { "label": "Click Me" } }
  ]
}
```

### Client -> Server (`event`)

The client sends user interactions to the server.

```json
{
  "type": "event",
  "id": "btn1",
  "event": "click",
  "value": true
}
```

## Execution Model

When the server receives an event (or on initial load):
1. The **Runner** loads the user's script.
2. It executes the script from top to bottom.
3. DSL methods (like `slider`, `button`) register components in the runner.
4. If an event matches a component, the component's return value is updated.
5. The resulting component tree is sent back to the client.

## State Management

`session_state` is preserved across reruns for a single session (WebSocket connection). It is currently stored in memory.

## Security

**Warning**: Nightingale executes arbitrary Ruby code. It is designed for local development. For deployment, ensure the environment is sandboxed (e.g., Docker) and access is restricted.
