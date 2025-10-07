import 'dart:async';

import 'package:anx_reader/service/ai/tools/input/current_time_input.dart';

import 'base_tool.dart';

class CurrentTimeTool
    extends RepositoryTool<CurrentTimeInput, Map<String, dynamic>> {
  CurrentTimeTool()
      : super(
          name: 'current_time',
          description:
              'Return the current system time. Optional parameter include_timezone (default true).',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'include_timezone': {
                'type': 'boolean',
                'description':
                    'Whether to include timezone offset information (default true).',
              },
            },
          },
          timeout: const Duration(seconds: 1),
        );

  @override
  CurrentTimeInput parseInput(Map<String, dynamic> json) {
    return CurrentTimeInput.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> run(CurrentTimeInput input) async {
    final now = DateTime.now();
    final utc = now.toUtc();
    final offset = now.timeZoneOffset;

    return {
      'localIso': now.toIso8601String(),
      'utcIso': utc.toIso8601String(),
      'timestampMs': now.millisecondsSinceEpoch,
      if (input.includeTimezone)
        'timezone': {
          'name': now.timeZoneName,
          'offsetMinutes': offset.inMinutes,
        },
    };
  }
}

final currentTimeTool = CurrentTimeTool().tool;
