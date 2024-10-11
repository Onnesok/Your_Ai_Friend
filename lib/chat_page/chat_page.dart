import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

class ChatAI extends StatefulWidget {
  final Function(bool isDarkMode) onThemeChanged;

  const ChatAI({super.key, required this.onThemeChanged});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isDarkMode = true; // Toggle between dark and light mode
  late Future<void> _initializationFuture; // Future for initialization
  late Gemini gemini;
  final TextEditingController inputController = TextEditingController();

  ChatUser currentUser = ChatUser(id: "0", firstName: "user");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Learners AI",
    profileImage: "https://images-platform.99static.com//2---YZxVUu3ZgdOGT-olFMiXXCg=/0x0:1961x1961/fit-in/500x500/99designs-contests-attachments/132/132928/attachment_132928696",
  );

  String? selectedImagePath;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    await dotenv.load(fileName: 'api_key.env');
    String? apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      Fluttertoast.showToast(msg: 'API Key is not set.');
      throw Exception("API Key is not set.");
    }
    gemini = await Gemini.init(apiKey: apiKey); // Initialize gemini
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture, // Use FutureBuilder to manage the future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        // When the initialization is complete, build the chat UI
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text("Your AI Friend", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0.0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.bubble_chart_outlined, color: Theme.of(context).iconTheme.color),
            ),
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay, color: Colors.red),
                onPressed: () {
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                  widget.onThemeChanged(isDarkMode);
                },
              ),
            ],
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
      },
    );
  }

  Widget _buildUi() {
    return Column(
      children: [
        Expanded(
          child: DashChat(
            currentUser: currentUser,
            onSend: _sendMessage,
            messages: messages,
            messageOptions: MessageOptions(
              messageDecorationBuilder: (message, previousMessage, nextMessage) {
                bool isUser = message.user.id == currentUser.id;
                return _neomorphicDecoration(context, isUser: isUser);
              },
              textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              // Use the builder to render HTML formatted text  :)
              messageTextBuilder: (message, previousMessage, nextMessage) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  child: Html(data: message.text),
                );
              },
            ),
            inputOptions: InputOptions(
              leading: [
                IconButton(
                  onPressed: _sendMediaMessage,
                  icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
                ),
              ],
              textController: inputController,
              inputTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
              inputDecoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                hintText: "Type your message here...",
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              alwaysShowSend: true,
            ),
          ),
        ),
        if (selectedImagePath != null) _buildImagePreview(),
      ],
    );
  }


  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display the image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(selectedImagePath!),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Image selected",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                selectedImagePath = null; // Remove selected image
              });
            },
          ),
        ],
      ),
    );
  }



  BoxDecoration _neomorphicDecoration(BuildContext context, {bool isUser = false}) {
    final theme = Theme.of(context);

    // Define background color based on the user's message type and theme
    Color backgroundColor = isUser
        ? (theme.brightness == Brightness.dark ? const Color(0xFF2B2B2B) : const Color(0xFFF0F0F0)) // User's message
        : (theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF)); // AI's message

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(15), // Rounded corners
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
          offset: const Offset(4, 4), // Light shadow for depth
          blurRadius: 35, // Soft blur for a more gentle effect
          spreadRadius: 1, // Light spread for a lifted effect
        ),
        BoxShadow(
          color: theme.brightness == Brightness.dark ? Colors.grey.withOpacity(0.1) : Colors.white.withOpacity(0.7),
          offset: const Offset(-4, -4), // Light shadow in the opposite direction
          blurRadius: 15, // Consistent blur for softness
          spreadRadius: 1, // Light spread
        ),
      ],
    );
  }


  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      isLoading = true;

      // If there's an image selected, add it to the message as media
      if (selectedImagePath != null) {
        chatMessage.medias = [
          ChatMedia(
            url: selectedImagePath!,
            fileName: File(selectedImagePath!).path.split('/').last,
            type: MediaType.image,
          )
        ];
      }

      messages = [chatMessage, ...messages];
      inputController.clear();
      selectedImagePath = null;
    });

    try {
      String question = chatMessage.text;
      List<Uint8List> images = [];

      // If the message contains media, read the image file as bytes
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      gemini.streamGenerateContent(question, images: images).listen((event) {
        String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";

        // Format the response for better readability
        String formattedResponse = _formatResponse(response);

        if (messages.isNotEmpty && messages.first.user == geminiUser) {
          ChatMessage? lastMessage = messages.removeAt(0);
          lastMessage.text += formattedResponse; // Append formatted response
          setState(() {
            messages = [lastMessage, ...messages];
            isLoading = false;
          });
        } else {
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: formattedResponse, // Set formatted response as message text
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


// Helper function to format responses
  String _formatResponse(String response) {
    // First, ensure the response is trimmed of any leading/trailing whitespace
    response = response.trim();

    // Replace Markdown-like syntax with HTML or custom formatting
    response = response
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'<b>$1</b>') // Bold
        .replaceAll(RegExp(r'_(.*?)_'), r'<i>$1</i>') // Italics
        .replaceAll(RegExp(r'`(.*?)`'), r'<code>$1</code>') // Inline code
        .replaceAll(RegExp(r'```(.*?)```', dotAll: true), r'<pre>$1</pre>') // Code block
        .replaceAll(RegExp(r'\n'), r'<br>'); // Convert new lines to <br>

    // Replace common mathematical symbols
    response = response
        .replaceAll(RegExp(r'(\d+)\^2'), r'$1&sup2;') // Handle numbers squared
        .replaceAll(RegExp(r'\/'), r'&divide;') // Division
        .replaceAll(RegExp(r'\*'), r'&times;'); // Multiplication

    // Remove any potential artifacts that may occur during replacement
    response = response.replaceAll(RegExp(r'\$[0-9]+'), ''); // Remove dollar sign artifacts

    return response;
  }









  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedImagePath = file.path;
      });
    }
  }
}
