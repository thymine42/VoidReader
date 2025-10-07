import 'dart:async';

import 'package:anx_reader/service/ai/tools/input/calculator_input.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:math_expressions/math_expressions.dart';

import 'base_tool.dart';

class CalculatorTool
    extends RepositoryTool<CalculatorInput, Map<String, dynamic>> {
  CalculatorTool()
      : super(
          name: 'calculator',
          description:
              'Use this to evaluate arithmetic expressions with numbers and + - * / ^.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'expression': {
                'type': 'string',
                'description': 'The arithmetic expression to evaluate.',
              },
            },
            'required': ['expression'],
          },
          timeout: const Duration(seconds: 2),
        );

  @override
  CalculatorInput parseInput(Map<String, dynamic> json) {
    return CalculatorInput.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> run(CalculatorInput input) async {
    final expression = input.expression?.trim() ?? '';
    if (expression.isEmpty) {
      throw ArgumentError('Expression cannot be empty');
    }

    final result = _evaluateExpression(expression);
    return {
      'expression': expression,
      'result': result,
    };
  }

  @override
  bool shouldLogError(Object error) {
    return error is! TimeoutException;
  }

  String _evaluateExpression(String expression) {
    AnxLog.info('Evaluating expression: $expression');
    final parser = ShuntingYardParser();
    final parsed = parser.parse(expression);
    final evaluation = parsed.evaluate(EvaluationType.REAL, ContextModel());
    if (evaluation is num && evaluation != 0) {
      final rounded = _roundIfClose(evaluation.toDouble());
      return rounded.toString();
    }
    return evaluation.toString();
  }

  double _roundIfClose(double value) {
    const epsilon = 1e-10;
    final rounded = value.roundToDouble();
    return (value - rounded).abs() < epsilon ? rounded : value;
  }
}

final calculatorTool = CalculatorTool().tool;
