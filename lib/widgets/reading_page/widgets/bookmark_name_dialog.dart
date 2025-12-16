import 'package:void_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

class BookmarkNameDialog extends StatefulWidget {
  const BookmarkNameDialog({super.key, this.initialName});

  final String? initialName;

  @override
  State<BookmarkNameDialog> createState() => _BookmarkNameDialogState();
}

class _BookmarkNameDialogState extends State<BookmarkNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).readingBookmark),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: L10n.of(context).contextMenuAddNoteTips,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(L10n.of(context).commonCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child: Text(L10n.of(context).commonSave),
        ),
      ],
    );
  }
}
