# Bedrock Voice Bridge 1.0.0

A proximity voice-chat companion for Minecraft Bedrock players who join a Java server through Geyser. The phone/desktop app is a microphone and speaker client; the Paper plugin pairs clients to in-game players and relays audio to nearby paired clients.

## Build artifacts

GitHub Actions builds:
- Android release APK
- Unsigned iOS IPA archive (requires Apple signing to install)
- Windows release ZIP
- Paper server plugin JAR

Run Actions → **Build Bedrock Voice Bridge 1.0.0** or push a commit to `main`.

## Server setup

1. Use a compatible Paper server with Geyser configured for Bedrock players.
2. Install `bedrock-voice-bridge-1.0.0.jar` in `plugins/` and restart.
3. Open TCP port `24454` (or set `websocket-port` in `plugins/BedrockVoiceBridge/config.yml`).
4. In-game, run `/bvb pair`. The code expires in 120 seconds.
5. In the app, enter the server WebSocket URL, Minecraft player name (display only), and code. Pairing code identifies the player.
6. Keep the app open while playing. Only paired app clients within the configured proximity range receive each other's voice.

## Security

The plugin's WebSocket listener binds to all interfaces. For public servers, do not expose it directly to the internet: put it behind a TLS-enabled WebSocket reverse proxy and use `wss://`. The starter pairing codes are short-lived, but the current prototype does not include rate limiting, moderation controls, or a hardened identity/session system.

## Compatibility and testing status

This is a first test build, not a certified or production-hardened port of Simple Voice Chat. It implements an independent proximity voice relay between Bedrock/Java server players who also run this app; it does **not** inject audio into the Simple Voice Chat mod's native protocol. Every speaking/listening player must run the companion app. Verify the workflow builds successfully and test on a private server before distributing. iOS builds are unsigned.
