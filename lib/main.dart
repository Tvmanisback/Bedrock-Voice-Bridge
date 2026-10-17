import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main()=>runApp(const BvbApp());
class BvbApp extends StatelessWidget{const BvbApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(title:'Bedrock Voice Bridge',theme:ThemeData.dark(useMaterial3:true),home:const MicPage());}
class MicPage extends StatefulWidget{const MicPage({super.key});@override State<MicPage> createState()=>_MicPageState();}
class _MicPageState extends State<MicPage>{
 final server=TextEditingController(text:'ws://YOUR_SERVER_IP:24454');
 final playerName=TextEditingController(),pairCode=TextEditingController();
 final recorder=AudioRecorder(); final playback=FlutterSoundPlayer();
 WebSocketChannel? channel; StreamSubscription<Uint8List>? microphone; StreamSubscription<dynamic>? messages;
 String status='Disconnected'; bool connected=false,muted=false,busy=false,playerReady=false;
 Future<void> connect() async {
  final url=server.text.trim();
  if(busy||connected)return;
  if(playerName.text.trim().isEmpty||pairCode.text.trim().isEmpty||!(url.startsWith('wss://')||url.startsWith('ws://'))){setState(()=>status='Enter server URL, Minecraft name, and pairing code.');return;}
  setState(()=>busy=true);
  try{
   if(!await recorder.hasPermission())throw Exception('Microphone permission denied');
   await playback.openPlayer();playerReady=true;
   await playback.startPlayerFromStream(codec:Codec.pcm16,numChannels:1,sampleRate:48000,bufferSize:8192);
   final c=WebSocketChannel.connect(Uri.parse(url));channel=c;await c.ready.timeout(const Duration(seconds:12));
   messages=c.stream.listen((raw){try{final j=jsonDecode(raw as String) as Map<String,dynamic>;if(j['type']=='error'){if(mounted)setState(()=>status='Server error: '+j['message'].toString());}else if(j['type']=='connected'){if(mounted)setState(()=>status='Connected as '+j['player'].toString());}else if(j['type']=='audio'&&j['data'] is String){final bytes=base64Decode(j['data'] as String);if(playerReady)playback.feedFromStream(Uint8List.fromList(bytes));}}catch(e){if(mounted)setState(()=>status='Audio decode error: '+e.toString());}},onError:(e){if(mounted)setState(()=>status='Socket error: '+e.toString());disconnect();},onDone:disconnect);
   c.sink.add(jsonEncode({'type':'auth','player':playerName.text.trim(),'code':pairCode.text.trim()}));
   final stream=await recorder.startStream(const RecordConfig(encoder:AudioEncoder.pcm16bits,sampleRate:48000,numChannels:1,echoCancel:true,noiseSuppress:true));
   connected=true;
   microphone=stream.listen((bytes){if(!connected||muted)return;try{c.sink.add(jsonEncode({'type':'pcm','format':'s16le','sampleRate':48000,'channels':1,'data':base64Encode(bytes)}));}catch(_){}});
   setState(()=>status='Connected. Voice is proximity-based.');
  }catch(e){if(mounted)setState(()=>status='Could not connect: '+e.toString());await disconnect();}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> disconnect()async{
  connected=false;await microphone?.cancel();microphone=null;await messages?.cancel();messages=null;
  try{if(await recorder.isRecording())await recorder.stop();}catch(_){}
  try{await channel?.sink.close();}catch(_){}channel=null;
  if(playerReady){try{await playback.stopPlayer();await playback.closePlayer();}catch(_){}playerReady=false;}
  if(mounted)setState(()=>status='Disconnected');
 }
 @override void dispose(){disconnect();recorder.dispose();server.dispose();playerName.dispose();pairCode.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bedrock Voice Bridge 1.0.0')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
  const Icon(Icons.mic,size:64),const Text('Proximity voice chat',style:TextStyle(fontSize:22)),const Text('Android • iOS • Windows'),
  TextField(controller:server,decoration:const InputDecoration(labelText:'Server WebSocket URL')),
  TextField(controller:playerName,decoration:const InputDecoration(labelText:'Minecraft player name')),
  TextField(controller:pairCode,decoration:const InputDecoration(labelText:'Pairing code from /bvb pair'),keyboardType:TextInputType.number),
  const SizedBox(height:16),FilledButton(onPressed:connected||busy?null:connect,child:Text(busy?'Connecting…':'Connect microphone')),
  OutlinedButton(onPressed:connected?()=>setState(()=>muted=!muted):null,child:Text(muted?'Unmute microphone':'Mute microphone')),
  TextButton(onPressed:connected?disconnect:null,child:const Text('Disconnect')),Text(status),
  const SizedBox(height:16),const Text('All players need this companion app and a paired server account. Keep the app open while playing. Use WSS behind TLS on public servers.')
 ])));
}
