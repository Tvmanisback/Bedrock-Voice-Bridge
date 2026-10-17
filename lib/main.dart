import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const BvbApp());
class BvbApp extends StatelessWidget {
 const BvbApp({super.key});
 @override Widget build(BuildContext context) => MaterialApp(title:'Bedrock Voice Bridge', theme:ThemeData.dark(useMaterial3:true), home:const MicPage());
}
class MicPage extends StatefulWidget {
 const MicPage({super.key});
 @override State<MicPage> createState()=>_MicPageState();
}
class _MicPageState extends State<MicPage> {
 final server=TextEditingController(text:'wss://your-server.example/voice');
 final player=TextEditingController(), code=TextEditingController();
 final recorder=AudioRecorder();
 WebSocketChannel? channel;
 StreamSubscription<Uint8List>? audio;
 StreamSubscription<dynamic>? messages;
 String status='Disconnected';
 bool connected=false, muted=false, busy=false;
 Future<void> connect() async {
  final url=server.text.trim();
  if(busy||connected)return;
  if(player.text.trim().isEmpty||code.text.trim().isEmpty||!(url.startsWith('wss://')||url.startsWith('ws://'))){setState(()=>status='Enter server URL, player name, and pairing code.');return;}
  setState(()=>busy=true);
  try {
   if(!await recorder.hasPermission()) throw Exception('Microphone permission denied');
   final c=WebSocketChannel.connect(Uri.parse(url)); channel=c;
   await c.ready.timeout(const Duration(seconds:12));
   messages=c.stream.listen((m){try{final j=jsonDecode(m as String);if(j['type']=='error'&&mounted)setState(()=>status='Server error: ${j['message']}');}catch(_){}},onError:(e){if(mounted)setState(()=>status='Socket error: $e');disconnect();},onDone:disconnect);
   c.sink.add(jsonEncode({'type':'auth','player':player.text.trim(),'code':code.text.trim()}));
   final stream=await recorder.startStream(const RecordConfig(encoder:AudioEncoder.pcm16bits,sampleRate:48000,numChannels:1,echoCancel:true,noiseSuppress:true));
   connected=true;
   audio=stream.listen((bytes){if(!connected||muted)return;c.sink.add(jsonEncode({'type':'pcm','format':'s16le','sampleRate':48000,'channels':1,'data':base64Encode(bytes)}));});
   setState(()=>status='Microphone streaming; server relay must support the BVB PCM protocol.');
  } catch(e) {if(mounted)setState(()=>status='Could not connect: $e');await disconnect();}
  finally {if(mounted)setState(()=>busy=false);}
 }
 Future<void> disconnect() async {
  connected=false;await audio?.cancel();audio=null;await messages?.cancel();messages=null;
  try{if(await recorder.isRecording())await recorder.stop();}catch(_){}
  try{await channel?.sink.close();}catch(_){} channel=null;
  if(mounted)setState(()=>status='Disconnected');
 }
 @override void dispose(){disconnect();recorder.dispose();server.dispose();player.dispose();code.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bedrock Voice Bridge')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
  const Icon(Icons.mic,size:64),const Text('Native microphone companion',style:TextStyle(fontSize:22)),const Text('Android • iOS • Windows'),
  TextField(controller:server,decoration:const InputDecoration(labelText:'Voice server WebSocket URL')),
  TextField(controller:player,decoration:const InputDecoration(labelText:'Minecraft player name')),
  TextField(controller:code,decoration:const InputDecoration(labelText:'Pairing code')),
  const SizedBox(height:16),FilledButton(onPressed:connected||busy?null:connect,child:Text(busy?'Connecting…':'Connect microphone')),
  OutlinedButton(onPressed:connected?()=>setState(()=>muted=!muted):null,child:Text(muted?'Unmute microphone':'Mute microphone')),
  TextButton(onPressed:connected?disconnect:null,child:const Text('Disconnect')),Text(status),
  const SizedBox(height:16),const Text('Starter client only: incoming voice playback and the server audio relay are not implemented yet.')
 ])));
}
