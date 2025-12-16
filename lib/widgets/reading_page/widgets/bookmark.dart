import 'package:void_reader/l10n/generated/L10n.dart';
import 'package:void_reader/models/bookmark.dart';
import 'package:void_reader/page/book_player/epub_player.dart';
import 'package:void_reader/providers/bookmark.dart';
import 'package:void_reader/utils/error_handler.dart';
import 'package:void_reader/widgets/common/container/filled_container.dart';
import 'package:void_reader/widgets/delete_confirm.dart';
import 'package:void_reader/widgets/reading_page/widgets/bookmark_name_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarkWidget extends ConsumerStatefulWidget {
  const BookmarkWidget({
    super.key,
    required this.epubPlayerKey,
    required this.onNavigate,
  });

  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final VoidCallback onNavigate;

  @override
  ConsumerState<BookmarkWidget> createState() => _BookmarkWidgetState();
}

class _BookmarkWidgetState extends ConsumerState<BookmarkWidget> {
  @override
  Widget build(BuildContext context) {
    final bookId = widget.epubPlayerKey.currentState!.book.id;

    final bookmarkList = ref.watch(BookmarkProvider(bookId));
    return bookmarkList.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text(
                  L10n.of(context).noBookmarks,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 16.0),
                Text(L10n.of(context).noBookmarksTip),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: BookmarkItem(
                bookmark: bookmark,
                onTap: (cfi) {
                  widget.epubPlayerKey.currentState?.goToCfi(cfi);
                  widget.onNavigate();
                },
                onDelete: (id) {
                  ref.read(BookmarkProvider(bookId).notifier).removeBookmark(
                        id: id,
                      );
                },
                onEdit: (bookmark) async {
                  String? name = await showDialog<String>(
                    context: context,
                    builder: (context) => BookmarkNameDialog(
                      initialName: bookmark.name,
                    ),
                  );
                  if (name != null) {
                    ref.read(BookmarkProvider(bookId).notifier).updateBookmark(
                          bookmark.copyWith(name: name),
                        );
                  }
                },
              ),
            );
          },
        );
      },
      error: (error, stackTrace) {
        return errorHandler(error, stack: stackTrace);
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class BookmarkItem extends StatelessWidget {
  const BookmarkItem({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  final BookmarkModel bookmark;
  final Function(String) onTap;
  final Function(int) onDelete;
  final Function(BookmarkModel) onEdit;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(bookmark.cfi),
      child: FilledContainer(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookmark.name != null && bookmark.name!.isNotEmpty)
              Text(
                bookmark.name!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              bookmark.content,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Divider(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bookmark.chapter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                      Text('${(bookmark.percentage * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => onEdit(bookmark),
                    ),
                    DeleteConfirm(
                      delete: () {
                        onDelete(bookmark.id!);
                      },
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
