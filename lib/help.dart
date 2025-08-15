import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHelpPage extends StatefulWidget {
  const ChatHelpPage({super.key});

  @override
  State<ChatHelpPage> createState() => _ChatHelpPageState();
}

class _ChatHelpPageState extends State<ChatHelpPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _localMessages = [];
  bool _showSuggestions = true;

  final List<String> _quickQuestions = [
    'cancel_booking_question'.tr(),
    'payment_methods_question'.tr(),
    'luggage_policy_question'.tr(),
    'change_email_question'.tr(),
  ];

  final Map<String, String> _faqResponses = {
    "annuler": 'cancel_booking_response'.tr(),
    "paiement": 'payment_methods_response'.tr(),
    "bagage": 'luggage_policy_response'.tr(),
    "email": 'change_email_response'.tr(),
    "default": 'default_response'.tr(),
  };

  @override
  void initState() {
    super.initState();
    _resetChat(); // Réinitialise les messages à chaque ouverture
  }

  void _resetChat() {
    setState(() {
      _localMessages.clear();
      _showSuggestions = true;
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text.trim();
    final response = _generateResponse(message);

    setState(() {
      _localMessages.add({
        'message': message,
        'response': response,
        'timestamp': DateTime.now(),
        'isUser': true,
      });
      _showSuggestions = false;
    });

    _controller.clear();
    _scrollToBottom();

    // Optionnel : Tu peux enregistrer dans Firestore ici si tu veux garder une trace
    _firestore.collection('chat_help').add({
      'message': message,
      'response': response,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _generateResponse(String message) {
    final cleaned = message.toLowerCase();

    final keywords = {
      'annuler':
          'cancel_keywords'.tr().split(',').map((e) => e.trim()).toList(),
      'paiement':
          'payment_keywords'.tr().split(',').map((e) => e.trim()).toList(),
      'bagage':
          'luggage_keywords'.tr().split(',').map((e) => e.trim()).toList(),
      'email': 'email_keywords'.tr().split(',').map((e) => e.trim()).toList(),
    };

    for (var entry in keywords.entries) {
      if (entry.value.any((word) => cleaned.contains(word.toLowerCase()))) {
        return _faqResponses[entry.key]!;
      }
    }

    return _faqResponses['default']!;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chat_help_title'.tr()),
        backgroundColor: const Color.fromARGB(255, 26, 105, 195),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/travel.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _showSuggestions && _localMessages.isEmpty
                  ? _buildQuickSuggestions()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _localMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _localMessages[index];
                        return _MessageBubble(
                          message: msg['message'],
                          response: msg['response'],
                          timestamp: msg['timestamp'],
                          isUser: msg['isUser'] ?? true,
                        );
                      },
                    ),
            ),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help_question'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 248, 249, 249),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickQuestions.map((question) {
              return ActionChip(
                label: Text(question),
                backgroundColor: Colors.blue.shade50,
                onPressed: () {
                  _controller.text = question;
                  _sendMessage();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'write_question_hint'.tr(),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(Icons.travel_explore, color: Colors.blue.shade800),
                  onPressed: _resetChat,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue.shade800),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String response;
  final DateTime timestamp;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.response,
    required this.timestamp,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
                topLeft: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
