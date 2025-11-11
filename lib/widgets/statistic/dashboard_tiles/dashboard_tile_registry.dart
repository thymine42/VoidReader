import 'package:anx_reader/models/statistics_dashboard_tile.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/dashboard_tile_base.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/tiles/library_totals_tile.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/tiles/period_summary_tile.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/tiles/top_book_tile.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/tiles/total_time_tile.dart';

const Map<StatisticsDashboardTileType, StatisticsDashboardTileBase>
    dashboardTileRegistry = {
  StatisticsDashboardTileType.totalTime: TotalTimeTile(),
  StatisticsDashboardTileType.libraryTotals: LibraryTotalsTile(),
  StatisticsDashboardTileType.periodSummary: PeriodSummaryTile(),
  StatisticsDashboardTileType.topBook: TopBookTile(),
};
