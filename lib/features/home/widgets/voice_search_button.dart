import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_theme.dart';

class VoiceSearchButton extends StatefulWidget {
  final Function(String query) onSearchComplete;
  final TextEditingController? searchController; // ✅ NEW: Accept controller

  const VoiceSearchButton({
    super.key,
    required this.onSearchComplete,
    this.searchController, // ✅ NEW: Optional controller
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onError: (error) {
        print('❌ Speech error: $error');
        _stopListening();
        _showError('Speech recognition error');
      },
      onStatus: (status) {
        print('🎤 Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          _stopListening();
        }
      },
    );

    if (!available) {
      _showError('Speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
      _transcription = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _transcription = result.recognizedWords;
        });

        // ✅ FIX #1: Update TextEditingController if provided
        if (widget.searchController != null) {
          widget.searchController!.text = result.recognizedWords;
          // Move cursor to end
          widget.searchController!.selection = TextSelection.fromPosition(
            TextPosition(offset: result.recognizedWords.length),
          );
        }

        // ✅ FIX #2: Update search in real-time
        widget.onSearchComplete(result.recognizedWords);

        // Auto-complete when user stops speaking
        if (result.finalResult) {
          _completeSearch();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _completeSearch() {
    if (_transcription.trim().isNotEmpty) {
      // ✅ FIX #3: Ensure controller is updated
      if (widget.searchController != null) {
        widget.searchController!.text = _transcription.trim();
      }
      widget.onSearchComplete(_transcription.trim());
    }
    _stopListening();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isListening ? _completeSearch : _startListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none_rounded,
              color: _isListening ? AppTheme.secondary : AppTheme.primary,
              size: 24,
            ),
          );
        },
      ),
    );
  }
}
