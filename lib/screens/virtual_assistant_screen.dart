import 'dart:ui';
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

  double _speechRate = 0.7; // Slower default
  final List<double> _rates = [0.7, 1.0, 1.5, 2.0, 0.5];
  int _rateIndex = 0;

  List<dynamic> _availableVoices = [];
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initTTS();
  }

  Future<void> _initTTS() async {
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _availableVoices = await _tts.getVoices;
    _selectedVoice = _availableVoices
        .firstWhere((voice) => voice['name'].toString().contains('en'), orElse: () => _availableVoices.first)['name'];
    await _tts.setVoice({"name": _selectedVoice!});
    await _tts.setSpeechRate(_speechRate);
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      setState(() {
        _recognizedText = "Speech recognition not available";
      });
    }
  }

  void _toggleSpeed() {
    _rateIndex = (_rateIndex + 1) % _rates.length;
    setState(() {
      _speechRate = _rates[_rateIndex];
    });
  }

  void _startListening() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            setState(() => _recognizedText = result.recognizedWords);
            if (result.finalResult) _stopListening();
          },
        );
      } else {
        setState(() => _recognizedText = "Speech recognition not available");
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty && _recognizedText != "Tap the mic and start speaking...") {
      _getChatbotResponse(_recognizedText);
    }
  }

  Future<void> _getChatbotResponse(String userInput) async {
    setState(() => _conversation.add({"user": userInput}));

    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";
    const String apiKey = "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"; // Replace with env config

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
              "content":
                  "You are DocBuddy, a friendly virtual doctor. Ask for more symptoms, give helpful advice, and always recommend a real doctor for serious issues. Only answer medical questions."
            },
            {"role": "user", "content": userInput}
          ],
          "max_tokens": 80
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data["choices"][0]["message"]["content"];
        setState(() => _conversation.add({"bot": reply}));
        _speak(reply);
      } else {
        _speak("Sorry, I couldn't process your request.");
      }
    } catch (e) {
      _speak("An error occurred. Please try again.");
    }
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(_speechRate);
    if (_selectedVoice != null) {
      await _tts.setVoice({"name": _selectedVoice!});
    }
    await _tts.speak(text);
  }

  void _openVoiceSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _availableVoices.isEmpty
              ? const Text("No voices found", style: TextStyle(color: Colors.white))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select Voice", style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 10),
                    ..._availableVoices.take(10).map((voice) {
                      return ListTile(
                        title: Text(voice['name'], style: const TextStyle(color: Colors.white)),
                        leading: Radio<String>(
                          value: voice['name'],
                          groupValue: _selectedVoice,
                          onChanged: (value) {
                            setState(() {
                              _selectedVoice = value!;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Virtual Doctor Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openVoiceSettings,
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
                    : [Color(0xFFd0eaf5), Color(0xFFa5cfe8), Color(0xFF7fb1d6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.health_and_safety, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _recognizedText,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleSpeed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text("${_speechRate}x", style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _conversation.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final msg = _conversation[_conversation.length - 1 - index];
                      final isUser = msg.containsKey("user");
                      return _buildChatBubble(isUser ? msg["user"]! : msg["bot"]!, isUser);
                    },
                  ),
                ),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 70,
                    width: 70,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.redAccent : Colors.teal,
                      boxShadow: _isListening
                          ? [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 20)]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
