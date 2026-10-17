import { world, system } from "@minecraft/server";
import { ActionFormData, ModalFormData } from "@minecraft/server-ui";

const mutedPlayers = new Set();
const voiceSettings = new Map();

function settingsFor(player) {
  if (!voiceSettings.has(player.id)) voiceSettings.set(player.id, { enabled: true, showStatus: true });
  return voiceSettings.get(player.id);
}

async function showVoiceMenu(player) {
  const settings = settingsFor(player);
  const muted = mutedPlayers.has(player.id);
  const form = new ActionFormData()
    .title("Bedrock Voice Bridge")
    .body("Voice chat settings\n\nThe required server add-on controls your in-game options. Keep the Bedrock Voice Bridge app open for microphone access.")
    .button(muted ? "Unmute voice" : "Mute voice")
    .button(settings.enabled ? "Turn voice off" : "Turn voice on")
    .button("More settings")
    .button("How to connect");
  try {
    const response = await form.show(player);
    if (response.canceled || response.selection === undefined) return;
    if (response.selection === 0) {
      if (muted) mutedPlayers.delete(player.id); else mutedPlayers.add(player.id);
      player.sendMessage(muted ? "§a[Voice] You are unmuted in the add-on settings." : "§e[Voice] You are muted in the add-on settings.");
      return;
    }
    if (response.selection === 1) {
      settings.enabled = !settings.enabled;
      player.sendMessage(settings.enabled ? "§a[Voice] Voice enabled in settings." : "§e[Voice] Voice disabled in settings.");
      return;
    }
    if (response.selection === 2) { await showMoreSettings(player); return; }
    if (response.selection === 3) {
      player.sendMessage("§b[Voice] Install the Bedrock Voice Bridge app from the project's Releases page, allow microphone access, then pair with the supported server.");
      player.sendMessage("§7https://github.com/Tvmanisback/Bedrock-Voice-Bridge/releases");
    }
  } catch { player.sendMessage("§c[Voice] Could not open settings. Try again."); }
}

async function showMoreSettings(player) {
  const settings = settingsFor(player);
  const form = new ModalFormData()
    .title("Voice preferences")
    .toggle("Enable voice features", { defaultValue: settings.enabled })
    .toggle("Show voice status messages", { defaultValue: settings.showStatus });
  try {
    const result = await form.show(player);
    if (result.canceled || !result.formValues) return;
    settings.enabled = Boolean(result.formValues[0]);
    settings.showStatus = Boolean(result.formValues[1]);
    player.sendMessage("§a[Voice] Settings saved for this session.");
  } catch { player.sendMessage("§c[Voice] Could not save settings."); }
}

world.afterEvents.chatSend.subscribe((event) => {
  const message = event.message.trim().toLowerCase();
  if (message === "!voice" || message === "!vb") {
    system.run(() => showVoiceMenu(event.sender));
  }
});

world.afterEvents.playerSpawn.subscribe((event) => {
  if (!event.initialSpawn) return;
  system.runTimeout(() => {
    try {
      event.player.sendMessage("§bBedrock Voice Bridge§7: type §f!voice §7for voice settings. The add-on is required; get the microphone app from Releases.");
    } catch {}
  }, 40);
});

world.afterEvents.playerLeave.subscribe((event) => {
  mutedPlayers.delete(event.player.id);
  voiceSettings.delete(event.player.id);
});
