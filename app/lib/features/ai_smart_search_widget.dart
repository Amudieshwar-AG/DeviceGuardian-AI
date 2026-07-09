import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class AISmartSearchWidget extends StatefulWidget {
  final String backendUrl; // e.g., "http://10.0.2.2:8000/api/search"

  const AISmartSearchWidget({super.key, required this.backendUrl});

  @override
  _AISmartSearchWidgetState createState() => _AISmartSearchWidgetState();
}

class _AISmartSearchWidgetState extends State<AISmartSearchWidget> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _aiResponse = '';
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _searchAI(_textController.text);
      }
    }
  }

  Future<void> _searchAI(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _aiResponse = '';
    });

    try {
      final response = await http.post(
        Uri.parse(widget.backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiResponse = data['summary'];
        });
      } else {
        setState(() {
          _aiResponse = "Error: Could not connect to the AI search module.";
        });
      }
    } catch (e) {
      setState(() {
        _aiResponse = "Network Error: Please ensure backend is running.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(PhosphorIcons.magnifyingGlass(), color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask Gemini anything...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: _searchAI,
                ),
              ),
              // Mic Button
              IconButton(
                icon: Icon(
                  _isListening ? PhosphorIcons.microphoneStage() : PhosphorIcons.microphone(),
                  color: _isListening ? AppTheme.warning : AppTheme.primaryColor,
                ),
                onPressed: _listen,
              ),
              // Send Button
              IconButton(
                icon: Icon(PhosphorIcons.paperPlaneRight(), color: AppTheme.primaryColor),
                onPressed: () => _searchAI(_textController.text),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        
        // AI Response Area
        if (_isLoading || _aiResponse.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIcons.sparkle(), color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "AI Smart Answer",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _aiResponse,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}
