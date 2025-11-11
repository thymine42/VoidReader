import 'package:anx_reader/models/statistics_dashboard_tile.dart';
import 'package:anx_reader/providers/dashboard_tiles_provider.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/dashboard_tile_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staggered_reorderable/staggered_reorderable.dart';

/// Base class for all statistics dashboard tiles.
abstract class StatisticsDashboardTileBase {
  const StatisticsDashboardTileBase(this.metadata);

  final StatisticsDashboardTileMetadata metadata;

  StatisticsDashboardTileType get type => metadata.type;

  /// Builds the tile body with access to WidgetRef.
  Widget buildContent(BuildContext context, WidgetRef ref);

  onRemove() {}

  /// Returns the [ReorderableItem] used by the reorderable grid.
  ReorderableItem buildReorderableItem({required BuildContext context}) {
    return ReorderableItem(
      trackingNumber: type.index,
      id: type.name,
      crossAxisCellCount: metadata.columnSpan,
      mainAxisCellCount: metadata.rowSpan,
      child: DashboardTileShell(
        tileType: type,
        onRemove: onRemove,
        buildContent: buildContent,
      ),
      placeholder: Opacity(
        opacity: 0.5,
        child: DashboardTileShell(
          tileType: type,
          onRemove: null,
          buildContent: buildContent,
        ),
      ),
    );
  }
}

class DashboardTileShell extends ConsumerWidget {
  const DashboardTileShell({
    super.key,
    required this.buildContent,
    required this.tileType,
    this.onRemove,
  });

  final Widget Function(BuildContext context, WidgetRef ref) buildContent;
  final StatisticsDashboardTileType tileType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardTilesProvider);
    final showRemoveButton =
        state.isEditing && state.workingTiles.length > 1 && onRemove != null;

    final notifier = ref.read(dashboardTilesProvider.notifier);

    return Stack(
      children: [
        FilledContainer(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(6),
          radius: 16,
          child: buildContent(context, ref),
        ),
        if (showRemoveButton)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton.filledTonal(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove card', // TODO(l10n)
              onPressed: () {
                notifier.removeTile(tileType);
                onRemove?.call();
              },
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    );
  }
}
