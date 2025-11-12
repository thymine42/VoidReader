import 'package:anx_reader/models/statistics_dashboard_tile.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/common/async_skeleton_wrapper.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/dashboard_tile_base.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/dashboard_tile_metadata.dart';
import 'package:anx_reader/widgets/tips/statistic_tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopBookTile extends StatisticsDashboardTileBase {
  const TopBookTile()
      : super(const StatisticsDashboardTileMetadata(
          type: StatisticsDashboardTileType.topBook,
          title: 'Top book', // TODO(l10n)
          description: 'Most read title in the current period.', // TODO(l10n)
          columnSpan: 4,
          rowSpan: 2,
          icon: Icons.bookmark_added_outlined,
        ));

  @override
  Widget buildCorner(BuildContext context, WidgetRef ref) {
    return cornerIcon(context, Icons.favorite);
  }

  @override
  Widget buildContent(
    BuildContext context,
    WidgetRef ref,
  ) {
    return AsyncSkeletonWrapper(
      asyncValue: ref.watch(statisticDataProvider),
      builder: (data) {
        if (data.bookReadingTime.isEmpty) {
          return Center(child: FittedBox(child: StatisticsTips()));
        }
        final entry = data.bookReadingTime.first;
        final book = entry.keys.first;
        final seconds = entry.values.first;

        final TextStyle bookTitleStyle = const TextStyle(
          fontSize: 20,
          fontFamily: 'SourceHanSerif',
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.ellipsis,
        );
        final TextStyle bookAuthorStyle = const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          overflow: TextOverflow.ellipsis,
        );
        final TextStyle bookReadingTimeStyle = const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );

        return Row(
          children: [
            BookCover(
              book: book,
              width: 120,
              radius: 10,
            ),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: bookTitleStyle),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(book.author, style: bookAuthorStyle),
                        ),
                        Text(
                            // getReadingTime(context),
                            convertSeconds(seconds),
                            textAlign: TextAlign.end,
                            style: bookReadingTimeStyle),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [Expanded(child: Text('Graph'))],
                    ),
                  ]),
            ),
          ],
        );
      },
    );
  }
}
