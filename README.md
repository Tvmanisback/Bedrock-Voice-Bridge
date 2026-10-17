# Bedrock Voice Bridge

**Downloads: use GitHub Releases, not Actions artifacts.**

Open [Releases](https://github.com/Tvmanisback/Bedrock-Voice-Bridge/releases) and download the published assets there. The workflow is configured to publish assets when a version tag such as `v1.0.0` is pushed.

## Project components
- Bedrock add-on package (`.mcaddon`) for in-game companion information.
- Windows microphone companion installer (`.exe`).
- Android microphone companion APK.
- Unsigned iOS IPA build (requires Apple signing to install).
- Paper/Geyser server-side voice relay.

## Important technical limitation
A Bedrock resource/behavior pack cannot directly access the operating system microphone. The microphone must be captured by a separate native app. This repository is **not yet a verified, drop-in port of Simple Voice Chat**; the add-on cannot magically connect Bedrock's voice to Simple Voice Chat without a compatible server-side bridge and protocol implementation. The current server relay is a separate prototype, not Simple Voice Chat protocol support. Do not advertise this as a finished working mod until the complete flow is tested.

## Publishing a release
Create and push a version tag (for example `v1.0.0`). GitHub Actions builds the platforms and attaches available assets to the GitHub Release. Users should download from the **Releases** page, not the Actions artifact page.

For public servers, use TLS/WSS, short-lived pairing codes, rate limits, and server-side identity validation before allowing real users to connect.
