import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key, required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
double bottomPadding = constraints.maxWidth > 600 ? 0.0 : 80.0;


    return Scaffold(
      body: Container(
        padding:
             EdgeInsets.fromLTRB(6, 6, 6, bottomPadding),
        child: const AiChatStream(),
      ),
    );
  }
}
