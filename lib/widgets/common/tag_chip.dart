import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/common/color_picker_sheet.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:flutter/material.dart';
import 'package:anx_reader/utils/color/hash_color.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;

  Color _colorForLabel(String value) {
    return color ?? hashColor(value);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _colorForLabel(label);
    final bgColor = selected ? baseColor.withAlpha(46) : Colors.transparent;
    final borderColor =
        selected ? Colors.transparent : baseColor.withAlpha(102);
    final foreground = selected
        ? baseColor
        : Theme.of(context).colorScheme.onSurface.withAlpha(179);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: Container(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          '# $label',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }

  static Future<void> showEditDialog({
    required BuildContext context,
    required String initialName,
    required Color? initialColor, // RGB
    required Future<void> Function(String newName) onRename,
    required Future<void> Function(Color color) onColorChange,
    required Future<void> Function() onDelete,
  }) async {
    final l10n = L10n.of(context);
    final controller = TextEditingController(text: initialName);
    await showDialog(
      context: context,
      builder: (dialogContext) {
        Color colorValue =
            (initialColor ?? hashColor(initialName)).withAlpha(0xFF);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.tagEditTitle),
                  DeleteConfirm(delete: () async {
                    await onDelete();
                    if (context.mounted) Navigator.of(dialogContext).pop();
                  }),
                ],
              ),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.tagNamePlaceholder,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: l10n.tagColorTooltip,
                  icon: Icon(Icons.circle, color: colorValue),
                  onPressed: () async {
                    final picked = await showRgbColorPicker(
                      context: context,
                      initialColor: colorValue,
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        colorValue = picked;
                      });
                      await onColorChange(colorValue);
                    }
                  },
                ),
                TextButton(
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) return;
                    await onRename(newName);
                    if (context.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }
}
