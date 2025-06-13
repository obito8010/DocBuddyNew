import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VirtualAssistantScreen extends StatefulWidget {
  const VirtualAssistantScreen({super.key});

  @override
  State<VirtualAssistantScreen> createState() => _VirtualAssistantScreenState();
}

class _VirtualAssistantScreenState extends State<VirtualAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  List<Map<String, String>> _conversation = [];
  String _recognizedText = "Tap the mic and start speaking...";

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      setState(() {
        _recognizedText = "Speech recognition not available";
      });
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
    _getChatbotResponse(_recognizedText);
  }

  Future<void> _getChatbotResponse(String userInput) async {
    setState(() {
      _conversation.add({"user": userInput});
    });

    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";
    const String apiKey = "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"; // 🔐 Replace if needed

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "messages": [
            {
              "role": "system",
              "content": "You are DocBuddy, a professional virtual doctor. Provide short, precise and complete medical advice in a brief manner, avoiding unnecessary details."
            },
            {
              "role": "user",
              "content": userInput
            }
          ],
          "max_tokens": 80
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String chatbotReply = data["choices"][0]["message"]["content"];
        setState(() {
          _conversation.add({"bot": chatbotReply});
        });
        _speak(chatbotReply);
      } else {
        _speak("Sorry, I couldn't process your request.");
      }
    } catch (e) {
      _speak("An error occurred. Please try again.");
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
    setState(() => _isSpeaking = false);
  }

  void _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Doctor Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final message = _conversation[index];
                final isUser = message.containsKey("user");
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUser ? message["user"]! : message["bot"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSpeaking)
                  FloatingActionButton(
                    onPressed: _stopSpeaking,
                    heroTag: 'stopSpeaking',
                    child: const Icon(Icons.stop),
                  ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  heroTag: 'micControl',
                  child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
