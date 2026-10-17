package dev.tvman.bvb;

import com.google.gson.*;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.command.*;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;
import java.net.InetSocketAddress;
import java.security.SecureRandom;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public final class BedrockVoiceBridge extends JavaPlugin {
 private final SecureRandom random = new SecureRandom();
 private final Map<UUID, PairCode> codes = new ConcurrentHashMap<>();
 private final Map<WebSocket, UUID> clients = new ConcurrentHashMap<>();
 private final Gson gson = new Gson();
 private VoiceSocket socket;
 private int port, range;
 @Override public void onEnable() {
  saveDefaultConfig(); port=getConfig().getInt("websocket-port",24454); range=getConfig().getInt("proximity-range",32);
  try { socket=new VoiceSocket(new InetSocketAddress("0.0.0.0",port)); socket.setReuseAddr(true); socket.start(); }
  catch(Exception e){getLogger().severe("Could not start voice WebSocket on "+port+": "+e);getServer().getPluginManager().disablePlugin(this);return;}
  getLogger().info("Bedrock Voice Bridge 1.0.0 listening on port "+port+"; proximity range "+range+" blocks.");
 }
 @Override public void onDisable(){ if(socket!=null)try{socket.stop(1000);}catch(Exception ignored){} clients.clear(); codes.clear(); }
 @Override public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
  if(!(sender instanceof Player p)){sender.sendMessage("Run this command in-game.");return true;}
  if(args.length==1 && args[0].equalsIgnoreCase("pair")) {
   String code=String.format("%06d",random.nextInt(1_000_000)); codes.put(p.getUniqueId(),new PairCode(code,System.currentTimeMillis()+120_000));
   p.sendMessage("§aBedrock Voice Bridge code: §e"+code+" §7(expires in 120 seconds)");
   p.sendMessage("§7App server: ws://YOUR_SERVER_IP:"+port+" (use WSS via a TLS proxy on public servers)");
   return true;
  }
  if(args.length==1 && args[0].equalsIgnoreCase("status")) {
   p.sendMessage("§aBVB 1.0.0 §7— "+(clients.containsValue(p.getUniqueId())?"microphone connected":"microphone not connected")+"; range "+range+" blocks.");return true;
  }
  p.sendMessage("§eBedrock Voice Bridge 1.0.0 §7— /bvb pair or /bvb status");return true;
 }
 private record PairCode(String value,long expiresAt){}
 private final class VoiceSocket extends WebSocketServer {
  VoiceSocket(InetSocketAddress address){super(address);}
  @Override public void onOpen(WebSocket conn, ClientHandshake handshake){conn.send("{\"type\":\"hello\",\"version\":\"1.0.0\"}");}
  @Override public void onMessage(WebSocket conn,String message) {
   Bukkit.getScheduler().runTask(BedrockVoiceBridge.this, () -> handleMessage(conn, message));
  }
  private void handleMessage(WebSocket conn,String message) {
   try {
    JsonObject j=JsonParser.parseString(message).getAsJsonObject(); String type=j.has("type")?j.get("type").getAsString():"";
    if(type.equals("auth")) {
     String code=j.get("code").getAsString(); UUID playerId=null; PairCode found=null;
     for(var e:codes.entrySet())if(e.getValue().value.equals(code)&&e.getValue().expiresAt>System.currentTimeMillis()){playerId=e.getKey();found=e.getValue();break;}
     if(playerId==null){sendError(conn,"Invalid or expired pairing code. Run /bvb pair again.");return;}
     final UUID authenticatedPlayerId = playerId;
     Player p=Bukkit.getPlayer(authenticatedPlayerId); if(p==null||!p.isOnline()){sendError(conn,"Minecraft player is no longer online.");return;}
     codes.remove(authenticatedPlayerId,found);
     clients.entrySet().removeIf(e -> e.getValue().equals(authenticatedPlayerId));
     clients.put(conn,authenticatedPlayerId); JsonObject ok=new JsonObject();ok.addProperty("type","connected");ok.addProperty("player",p.getName());ok.addProperty("version","1.0.0");conn.send(gson.toJson(ok));return;
    }
    UUID senderId=clients.get(conn); if(senderId==null){sendError(conn,"Authenticate first using a pairing code.");return;}
    if(type.equals("pcm")) {
     if(!j.has("data")||j.get("data").getAsString().length()>24000){sendError(conn,"Invalid or oversized audio frame.");return;}
     Player source=Bukkit.getPlayer(senderId); if(source==null||!source.isOnline())return;
     String encoded=j.get("data").getAsString(); JsonObject frame=new JsonObject();frame.addProperty("type","audio");frame.addProperty("player",source.getName());frame.addProperty("data",encoded);
     String payload=gson.toJson(frame); Location from=source.getLocation();
     for(var entry:clients.entrySet()) {
      if(entry.getKey()==conn||!entry.getKey().isOpen())continue;
      Player target=Bukkit.getPlayer(entry.getValue()); if(target==null||!target.isOnline()||!target.getWorld().equals(source.getWorld()))continue;
      if(target.getLocation().distanceSquared(from)<=range*range)entry.getKey().send(payload);
     }
    }
   }catch(Exception e){sendError(conn,"Malformed message.");}
  }
  @Override public void onClose(WebSocket conn,int code,String reason,boolean remote){clients.remove(conn);}
  @Override public void onError(WebSocket conn,Exception ex){if(ex!=null)getLogger().warning("Voice socket error: "+ex.getMessage());}
  @Override public void onStart(){getLogger().info("Voice relay ready.");}
  private void sendError(WebSocket c,String message){try{JsonObject e=new JsonObject();e.addProperty("type","error");e.addProperty("message",message);c.send(gson.toJson(e));}catch(Exception ignored){}}
 }
}
