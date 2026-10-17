package dev.tvman.bvb;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import java.security.SecureRandom;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/** Pairing scaffold only. No voice audio relay is implemented in this version. */
public final class BedrockVoiceBridge extends JavaPlugin {
 private final SecureRandom random=new SecureRandom();
 private final Map<UUID,PairCode> codes=new ConcurrentHashMap<>();
 @Override public void onEnable(){getLogger().warning("Pairing scaffold only: voice relay is not implemented. A compatible Geyser/Simple Voice Chat adapter is required.");}
 @Override public boolean onCommand(CommandSender sender,Command command,String label,String[] args){
  if(!(sender instanceof Player p)){sender.sendMessage("Run this command in-game.");return true;}
  if(args.length==1&&args[0].equalsIgnoreCase("pair")){
   String code=String.format("%06d",random.nextInt(1_000_000));
   codes.put(p.getUniqueId(),new PairCode(code,System.currentTimeMillis()+120_000));
   p.sendMessage("§aBVB pairing code: §e"+code+" §7(expires in 120 seconds)");
   p.sendMessage("§cPairing scaffold only; audio relay is not active.");return true;
  }
  if(args.length==1&&args[0].equalsIgnoreCase("status")){p.sendMessage("§eBVB: pairing scaffold; voice relay not active.");return true;}
  p.sendMessage("§cUsage: /bvb pair or /bvb status");return true;
 }
 private record PairCode(String value,long expiresAt){}
}
