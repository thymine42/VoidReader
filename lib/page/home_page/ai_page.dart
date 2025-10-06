import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key, required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding:
            constraints.maxWidth > 600 ? null : const EdgeInsets.only(bottom: 80.0),
        child: const AiChatStream(),
      ),
    );
  }
}
