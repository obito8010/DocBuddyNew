import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';
import '../services/firestore_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> messages = [];
  final FirestoreService _firestoreService = FirestoreService();
  String animatedBotResponse = "";

  @override
  void initState() {
    super.initState();
    loadChatHistory();
  }

  Future<void> loadChatHistory() async {
    final history = await _firestoreService.getChatHistory();
    setState(() {
      messages.addAll(history);
    });
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': message});
      animatedBotResponse = "";
      _messageController.clear();
    });

    await _firestoreService.addChatMessage('user', message);
    final response = await fetchDoctorResponse(message);

    setState(() {
      animatedBotResponse = response;
    });

    await Future.delayed(Duration(milliseconds: 10 * response.length), () {
      setState(() {
        messages.add({'sender': 'bot', 'text': response});
        animatedBotResponse = "";
      });
      _firestoreService.addChatMessage('bot', response);
    });
  }

  Future<String> fetchDoctorResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer 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",
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are DocBuddy, a friendly and professional AI doctor. Only answer medical-related questions. Based on symptoms, provide follow-up questions, possible diagnosis, suggested medicines, precautions, treatments, and diet tips. If the symptoms suggest something serious, gently tell the user to consult a real doctor. Avoid robotic tone."
            },
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 250
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        return "Sorry, something went wrong. Please try again.";
      }
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  Future<void> generateReport() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
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
            pw.Text("Note: Please consult a real doctor for serious conditions.",
                style: pw.TextStyle(fontSize: 12)),
          ],
        );
      },
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
      appBar: AppBar(
        title: const Text('DocBuddy Chat'),
        backgroundColor: isDark ? Colors.transparent : Colors.teal,
        elevation: isDark ? 0 : 4,
        actions: [
          IconButton(
            tooltip: 'Download Report',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: generateReport,
          ),
        ],
      ),
      extendBodyBehindAppBar: isDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
                : [Color(0xFFd0eaf5), Color(0xFFa5cfe8), Color(0xFF7fb1d6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length + (animatedBotResponse.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (animatedBotResponse.isNotEmpty && index == 0) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.grey.shade300,
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

                    final msg = messages[messages.length - index - 1];
                    final isUser = msg['sender'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(isUser ? 0.08 : 0.15)
                              : isUser
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                          ),
                          border: isDark
                              ? Border.all(color: Colors.white.withOpacity(0.2))
                              : null,
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : isUser
                                    ? Colors.white
                                    : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: const InputDecoration(
                            hintText: "Describe your symptoms...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => sendMessage(_messageController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
