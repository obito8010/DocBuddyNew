import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:animated_text_kit/animated_text_kit.dart';
import '../services/firestore_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> chatSessions = [];
  String? currentChatId;
  String animatedBotResponse = "";
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  Future<void> initChat() async {
    final sessions = await _firestoreService.getAllChatSessions();
    setState(() => chatSessions = sessions);
    if (sessions.isNotEmpty) {
      await switchToChat(sessions.first['chatId']);
    } else {
      await createNewChat();
    }
  }

  Future<void> switchToChat(String chatId) async {
    final msgs = await _firestoreService.getMessages(chatId);
    setState(() {
      currentChatId = chatId;
      messages = msgs;
      animatedBotResponse = "";
    });
  }

  Future<void> createNewChat() async {
    final newId = await _firestoreService.createNewChatSession(title: "New Chat");
    if (newId != null) {
      await switchToChat(newId);
      final updatedSessions = await _firestoreService.getAllChatSessions();
      setState(() => chatSessions = updatedSessions);
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || currentChatId == null || isSending) return;

    setState(() {
      isSending = true;
      messages.add({'sender': 'user', 'text': message, 'timestamp': DateTime.now().toString()});
      _messageController.clear();
    });

    await _firestoreService.addMessageToChat(currentChatId!, 'user', message);
    final response = await fetchDoctorResponse(message);

    if (!mounted) return;
    setState(() {
      animatedBotResponse = response;
    });

    // Wait until animation roughly completes
    await Future.delayed(Duration(milliseconds: 12 * response.length));
    if (!mounted) return;

    setState(() {
      messages.add({'sender': 'bot', 'text': response, 'timestamp': DateTime.now().toString()});
      animatedBotResponse = "";
      isSending = false;
    });

    await _firestoreService.addMessageToChat(currentChatId!, 'bot', response);
  }

  Future<String> fetchDoctorResponse(String userMessage) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return "API key missing.";

    try {
      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "messages": [
            {
              "role": "system",
              "content": "You are DocBuddy, a professional AI doctor. Only medical queries. Always respond with complete and professional advice."
            },
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 400,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"].toString().trim();
      } else {
        return "Sorry, something went wrong.";
      }
    } catch (e) {
      return "An error occurred.";
    }
  }

  Future<void> renameChat(String chatId, String oldTitle) async {
    final controller = TextEditingController(text: oldTitle);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _firestoreService.renameChatSession(chatId, controller.text);
              Navigator.pop(context);
              await initChat();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Future<void> deleteChat(String chatId) async {
    await _firestoreService.deleteChatSession(chatId);
    await initChat();
  }

  Future<void> generateReport() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("DocBuddy - Medical Report",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          ...messages.map((msg) => pw.Text(
                "${msg['sender'] == 'user' ? 'You' : 'DocBuddy'}: ${msg['text']}",
                style: pw.TextStyle(fontSize: 14),
              )),
          pw.SizedBox(height: 20),
          pw.Text("Note: Consult a real doctor for serious conditions.",
              style: pw.TextStyle(fontSize: 12))
        ],
      ),
    ));

    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/DocBuddy_Report.pdf");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('DocBuddy Chat'),
        actions: [
          IconButton(
            tooltip: 'Download Report',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: generateReport,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(messages.length),
                reverse: true,
                itemCount: messages.length + (animatedBotResponse.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (animatedBotResponse.isNotEmpty && index == 0) {
                    return _buildAnimatedResponse(context);
                  }
                  final msg = messages[messages.length - index - 1];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? (isDark ? Colors.white10 : Colors.teal)
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : isUser
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (value) => sendMessage(value),
                    decoration: InputDecoration(
                      hintText: "Describe your symptoms...",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isSending ? Colors.grey : Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: isSending ? null : () => sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedResponse(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (animatedBotResponse.trim().isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              animatedBotResponse,
              textStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
              speed: const Duration(milliseconds: 8),
            ),
          ],
          isRepeatingAnimation: false,
          totalRepeatCount: 1,
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text("New Chat"),
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.pop(context);
                createNewChat();
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: chatSessions.length,
                itemBuilder: (context, index) {
                  final session = chatSessions[index];
                  return ListTile(
                    title: Text(session['title'] ?? 'Chat'),
                    selected: session['chatId'] == currentChatId,
                    onTap: () {
                      Navigator.pop(context);
                      switchToChat(session['chatId']);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          renameChat(session['chatId'], session['title']);
                        } else if (value == 'delete') {
                          deleteChat(session['chatId']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'rename', child: Text("Rename")),
                        const PopupMenuItem(value: 'delete', child: Text("Delete")),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
