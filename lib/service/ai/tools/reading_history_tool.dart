import 'dart:async';

import 'package:anx_reader/service/ai/tools/input/reading_history_input.dart';
import 'package:anx_reader/service/ai/tools/repository/reading_history_repository.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';

import 'base_tool.dart';

class ReadingHistoryTool
    extends RepositoryTool<ReadingHistoryInput, Map<String, dynamic>> {
  ReadingHistoryTool(this._repository)
      : super(
          name: 'reading_history',
          description:
              'Fetch reading history entries. Optional filters: book_id, from/to (ISO date), limit.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'book_id': {
                'type': 'integer',
                'description': 'Filter by book identifier.',
              },
              'from': {
                'type': 'string',
                'description': 'Include entries on/after this ISO date.',
              },
              'to': {
                'type': 'string',
                'description': 'Include entries on/before this ISO date.',
              },
              'limit': {
                'type': 'integer',
                'description': 'Max number of records to return (1-100).',
              },
            },
          },
          timeout: const Duration(seconds: 4),
        );

  final ReadingHistoryRepository _repository;

  @override
  ReadingHistoryInput parseInput(Map<String, dynamic> json) {
    return ReadingHistoryInput.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> run(ReadingHistoryInput input) async {
    final records = await _repository.fetchHistory(
      bookId: input.bookId,
      from: input.from,
      to: input.to,
      limit: input.resolvedLimit(),
    );

    final totalSeconds =
        records.fold<int>(0, (sum, item) => sum + item.entry.readingTime);

    return {
      'bookId': input.bookId,
      'from': input.from?.toIso8601String(),
      'to': input.to?.toIso8601String(),
      'totalEntries': records.length,
      'totalReadingDuration': convertSeconds(totalSeconds),
      'records': records.map((record) => record.toMap()).toList(),
    };
  }

  @override
  bool shouldLogError(Object error) {
    return error is! TimeoutException;
  }
}

final readingHistoryTool =
    ReadingHistoryTool(const ReadingHistoryRepository()).tool;
