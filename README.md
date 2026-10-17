# Bedrock Voice Bridge

Native microphone companion app source (Android, iOS, Windows) and a Paper server-plugin build scaffold.

## Status — not a finished voice port yet
The native app captures microphone audio and sends PCM16 chunks to a WebSocket endpoint. The plugin in this starter only provides pairing/status scaffolding; it does **not** yet relay audio through Simple Voice Chat. A working Bedrock voice port needs a compatible Geyser/Simple Voice Chat adapter and a tested bidirectional audio relay. Do not treat the resulting JAR as a complete voice-chat mod.

## Build
Push to main or run Actions → Build apps and plugin. Artifacts include an Android debug APK, unsigned iOS archive, Windows ZIP, and plugin JAR. iOS requires Apple signing for installation.

## Native client protocol
The app sends JSON messages `auth` and `pcm` to a configured WebSocket URL. Use WSS and short-lived pairing codes in production.
