import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';

class ChatAI extends StatefulWidget {
  const ChatAI({super.key});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  bool isLoading = false;

  ChatUser currentUser = ChatUser(id: "0", firstName: "user");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Learners AI",
    profileImage: "https://raw.githubusercontent.com/Onnesok/Learners/main/assets/icon/app_icon1.png",
  );

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    await dotenv.load(fileName: 'api_key.env');
    String? apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      Fluttertoast.showToast(msg: 'API Key is not set.');
      return;
    }
    Gemini.init(apiKey: apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background color
      appBar: AppBar(
        title: Text("Your AI Friend", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 0.0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.bubble_chart_outlined, color: Colors.blueGrey),
        ),
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: _buildUi(),
          ),
          if (isLoading)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: Lottie.asset(
                  'assets/animation/cube_loader.json',
                  repeat: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUi() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
        messageDecorationBuilder: (message, previousMessage, nextMessage) {
          bool isUser = message.user.id == currentUser.id;
          return _neomorphicDecoration(isUser: isUser);
        },
        textColor: Colors.white,
      ),
      inputOptions: InputOptions(
        inputTextStyle: TextStyle(color: Colors.white),
        inputDecoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          hintText: "Type your message here...",
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image, color: Colors.blueAccent),
          ),
        ],
        alwaysShowSend: true,
      ),
    );
  }

  // Neomorphic decoration builder
  BoxDecoration _neomorphicDecoration({bool isUser = false}) {
    return BoxDecoration(
      color: const Color(0xFF1E1E1E), // Dark color for neomorphic style
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5), // Dark shadow for depth
          offset: const Offset(10, 10),
          blurRadius: 20,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1), // Light shadow for neomorphic effect
          offset: const Offset(-10, -10),
          blurRadius: 20,
        ),
      ],
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      isLoading = true;
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List> images = [];
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
        if (messages.isNotEmpty && messages.first.user == geminiUser) {
          ChatMessage? lastMessage = messages.removeAt(0);
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage, ...messages];
            isLoading = false;
          });
        } else {
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
            isLoading = false;
          });
        }
      }).onError((error) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "An error occurred: $error");
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "An error occurred: $e");
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this image?",
        medias: [ChatMedia(url: file.path, fileName: "", type: MediaType.image)],
      );
      _sendMessage(chatMessage);
    }
  }
}
