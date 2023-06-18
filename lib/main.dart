import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_bubble.dart';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';


void main() {
  runApp(const MyApp());
}

const themeColor = Colors.blue;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "XiaoRuanBot",
      home: Chat(),
    );
  }
}

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _themeColors = [Colors.blue,Colors.green,Colors.red];
  final _bubbleColors = [Colors.blue[300],Colors.green[300],Colors.red[300]];
  final _titles = ["小软:智能家居控制助手","小软:车载语音助手","小软:通用聊天机器人"];
  final _textChatUrls = ["http://222.187.226.110:36895/text_chat","http://222.187.226.110:44867/text_chat","http://i-1.gpushare.com:10667/text_chat"];
  final _voiceChatUrls = ["http://222.187.226.110:36895/voice_chat_home","http://222.187.226.110:44867/voice_chat","http://222.187.226.110:36895/voice_chat_general"];

  final TextEditingController _textController = TextEditingController();
  final List _messageList = [];

  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
  late StreamSubscription _recorderSubscription;


  int _recordTime = 0;
  bool record = false;
  bool _isRecording = false;
  int _colorIdx = 0;
  int _voiceMsgIdx = 0;

  void _getPermission() async {
      final perms = [Permission.storage,Permission.microphone];
      for(int i = 0; i < perms.length;i++) {
        if(await perms[i].isDenied) {
          await perms[i].request();
        }
      }
  }

  void _createDir(String name) async {
    Directory documentDir = await getApplicationDocumentsDirectory();
    String path = '${documentDir.path}${Platform.pathSeparator}$name';
    var dir = Directory(path);
    var exists = dir.existsSync();
    if(!exists){
      dir.createSync();
    }

  }
  void _deleteDir(String name) async {
    Directory documentDir = await getApplicationDocumentsDirectory();
    String path = '${documentDir.path}${Platform.pathSeparator}$name';
    await Directory(path).delete();
  }
  void _initRecAndPlay() async {
    await _player.openPlayer();
    await _player.setSubscriptionDuration(const Duration(milliseconds: 30));
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 30));
  }


  @override
  void initState() {
    super.initState();
    _getPermission();
    if(_colorIdx == 1 || _colorIdx == 0){
      Map<String,String> data = {
        "sender":"user",
        "message":"开机"
      };
      Map<String,String> head = {
        "Content-Type":"application/json"
      };
      var body = json.encode(data);
      http.post(Uri.parse(_textChatUrls[_colorIdx]),body: body,headers: head).then(
              (res) {
            if(res.statusCode == 200){
              setState(() {
                var data = json.decode(res.body)['data'];
                for(int i = 0;i<data.length;i++){
                  _messageList.add(TextBubble(text: data[i], isCurrentUser: false));
                }
              });
            }
          }
      );
    }
    _initRecAndPlay();
    _createDir("input");
    _createDir("output");
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          record
              ? IconButton(onPressed: _toText, icon: const Icon(Icons.keyboard))
              : IconButton(onPressed:_toAudio, icon: const Icon(Icons.mic)),
          // 输入框
          Flexible(
            child: record
                ? Padding(
              padding: const EdgeInsets.all(10),
                child:InkWell(
                    onTapDown: (tapDown){
                      _record();
                    },
                    onTapUp: (tapUp){
                      _chatVoice();
                    },
                    child: Container(
                      alignment: const Alignment(0, 0),
                      color: Colors.white60,
                      height: 28,
                      width: 1000,
                      child: const Text("按住 说话"),
                    )
                ),
            )
                : TextField(
              controller: _textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: '输入消息',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                isDense: true,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: record ? null : ElevatedButton(
                onPressed: _chatText,
                style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(_themeColors[_colorIdx])),

                child: const Text(
                    "发送",
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                )
                )
            )
            ),
        ],
      ),
    );
  }
  void _toAudio() {
    setState(() {
      record = true;
    });
  }
  void _toText() {
    setState(() {
      record = false;
    });
  }
  Future<void> _chatText() async {
    var message = "";
    setState(() {
      if (_textController.text.trim().isNotEmpty) {
        message = _textController.text;
        _messageList.add(TextBubble(text: message,
            isCurrentUser: true,
            color: _bubbleColors[_colorIdx]));
        _textController.clear();
      }
    });
    Map data = {
      "sender":"user",
      "message": message
    };
    Map<String,String> head = {
      "Content-Type":"application/json"
    };
    var body = json.encode(data);
    var res = await http.post(Uri.parse(_textChatUrls[_colorIdx]),
        body: body,headers: head);
    if (res.statusCode == 200){
      setState(() {
        var data = json.decode(res.body)['data'];
        for(int i = 0;i < data.length;i++){
          _messageList.add(TextBubble(text: data[i], isCurrentUser: false,));
        }
      });
    }
  }

  void _record() async {
    Vibrate.feedback(FeedbackType.medium);
    setState(() {
      _isRecording = true;
    });

    Directory documentDir = await getApplicationDocumentsDirectory();
    String savePath = '${documentDir.path}${Platform.pathSeparator}input${Platform.pathSeparator}$_voiceMsgIdx.wav';

     await _recorder.startRecorder(
      toFile: savePath,
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 16000
    );
    _recorderSubscription = _recorder.onProgress!.listen((event) {
        var recordTime = DateTime.fromMillisecondsSinceEpoch(event.duration.inMilliseconds,isUtc: true);
        setState(() {
          _recordTime = recordTime.second;
        });
    });
  }
  void _saveAnswerAudio(binary,savePath) {
    File file = File(savePath);
    if(!file.existsSync()){
      file.createSync();
    }
    final bytes = base64.decode(binary);
    file.writeAsBytesSync(bytes);

  }
  void _chatVoice() async {
    setState(() {
      _isRecording = false;
    });
    _stopRecorder();
    Directory documentDir = await getApplicationDocumentsDirectory();
    String savePath = '${documentDir.path}${Platform.pathSeparator}output${Platform.pathSeparator}$_voiceMsgIdx.wav';
    String filePath = '${documentDir.path}${Platform.pathSeparator}input${Platform.pathSeparator}$_voiceMsgIdx.wav';
    setState(() {
     if(_recordTime > 0) {
       _messageList.add(
           VoiceBubble(isCurrentUser: true, time: _recordTime, filePath: filePath, player: _player, color: _bubbleColors[_colorIdx],)
       );
     }
    });
    if(File(filePath).existsSync()) {
      var url = Uri.parse(_voiceChatUrls[_colorIdx]);
      var request = http.MultipartRequest("POST", url);
      request.files.add(
          await http.MultipartFile.fromPath('input',filePath,contentType: MediaType("multipart","form-data"))
      );
      var response = await request.send();
      if(response.statusCode == 200) {
        var streamString = await response.stream.bytesToString();
        var resBody = json.decode(streamString);
        var time = resBody["length"];
        if (resBody["file"] != null){
          _saveAnswerAudio(resBody["file"], savePath);
        }
        final answer = VoiceBubble(isCurrentUser: false, time: time, filePath: savePath, player: _player);
        setState(() {
          if(resBody["data"].length > 0) {
            _messageList.add(answer);
            for (int i = 1; i < resBody["data"].length; i++) {
              _messageList.add(
                  TextBubble(text: resBody["data"][i], isCurrentUser: false));
            }
          }
        });
        if (resBody["file"] != null){
          answer.play();
        }
      }
    }
    setState(() {
      _voiceMsgIdx++;
    });
  }

  Widget _getRecordingWidget() {
    return _isRecording
        ? Container(
      alignment: Alignment.center,
      color: _themeColors[_colorIdx],
      child: const Text(
          "正在录音",
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
      ),
    )
    )
    : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: _themeColors[_colorIdx],
          centerTitle: true,
          title: Text(_titles[_colorIdx]),
          actions: <Widget>[
            PopupMenuButton(itemBuilder: (BuildContext context){
              return [
                const PopupMenuItem(value: 0,child: Text("智能家居控制助手"),),
                const PopupMenuItem(value: 1,child: Text("车载语音助手"),),
                const PopupMenuItem(value: 2,child: Text("通用聊天机器人"),)
              ];
            },
            icon: const Icon(Icons.menu),
            onSelected: (int idx){
              setState(() {
                _messageList.clear();
                _colorIdx = idx;
                if (_colorIdx == 1 || _colorIdx == 0){
                  Map data = {
                    "sender":"user",
                    "message":"开机"
                  };
                  Map<String,String> head = {
                    "Content-Type":"application/json"
                  };
                  var body = json.encode(data);
                  http.post(Uri.parse(_textChatUrls[_colorIdx]),body: body,headers: head).then(
                          (res) {
                        setState(() {
                          var data = json.decode(res.body)['data'];
                          for(int i = 0; i < data.length; i++){
                            _messageList.add(TextBubble(text: data[i], isCurrentUser: false));
                          }
                        });
                      }
                  );
                }
              });
            })
          ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: ListView.builder(
              itemCount: _messageList.length,
              itemBuilder: (BuildContext context,int index){
                  return _messageList[index];
              },
            )
            ),
            _getRecordingWidget(),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  void _cancelRecorderSubscriptions() {
    _recorderSubscription.cancel();
  }

  void _stopRecorder() async {
    await _recorder.stopRecorder().then((value) => _cancelRecorderSubscriptions());
  }

  void _closeRecorder() async {
    await _recorder.closeRecorder();
  }
  void _closePlayer() async {
    await _player.closePlayer();
  }


  @override
  void dispose() {
    _cancelRecorderSubscriptions();
    _closeRecorder();
    _closePlayer();
    _deleteDir("input");
    _deleteDir("output");
    super.dispose();
  }
}
