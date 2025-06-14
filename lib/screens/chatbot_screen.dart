import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool isLoading = false;

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
      isLoading = true;
    });

    await _firestoreService.addChatMessage('user', message);
    final response = await fetchDoctorResponse(message);

    setState(() {
      messages.add({'sender': 'bot', 'text': response});
      isLoading = false;
    });

    await _firestoreService.addChatMessage('bot', response);
    _messageController.clear();
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
              "content": """
You are DocBuddy, a friendly and professional virtual doctor. Always begin conversations by warmly greeting the user. Ask relevant follow-up questions if symptoms are unclear. Provide responses ONLY related to health or medical issues.

Your reply should include:
- Diagnosis (if applicable)
- Possible causes
- Recommended medications (common OTC where possible)
- Precautions
- Basic treatment
- Dietary advice
- And in case of serious or emergency symptoms, suggest: "Please consult a real doctor immediately."

Keep the tone empathetic, supportive, and human-like — like a real doctor who cares about the patient.
"""
            },
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 500
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
    pdf.addPage(pw.MultiPage(
      build: (pw.Context context) {
        return [
          pw.Text("DocBuddy Medical Report", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Divider(),
          ...messages.map((msg) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "${msg['sender'] == 'user' ? 'You' : 'DocBuddy'}:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(msg['text'] ?? ''),
                  pw.SizedBox(height: 10),
                ],
              )),
          pw.SizedBox(height: 20),
          pw.Text("⚠️ Note: This is an AI-generated report. For serious conditions, please consult a real doctor.", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
        ];
      },
    ));

    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/DocBuddy_Report.pdf");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DocBuddy Chat'),
        actions: [
          IconButton(
            tooltip: 'Download Medical Report',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: generateReport,
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - index - 1];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.teal : Colors.grey.shade300,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Describe your symptoms...",
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
    );
  }
}
