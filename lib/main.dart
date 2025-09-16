import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Indiana Britto – Calculator",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CalculatorPage(title: "Indiana Britto – Calculator"),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.title});
  final String title;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expr = "";
  String _result = "0";
  String? _error;
  bool _justEvaluated = false;

  final List<String> _keys = <String>[
    'C', '/', '*', '⌫',
    '7', '8', '9', '-',
    '4', '5', '6', '+',
    '1', '2', '3', '=',
    '0', '.', '%', 'x²',
  ];

  bool _isOp(String s) => s == '+' || s == '-' || s == '*' || s == '/' || s == '%';

  void _press(String key) {
    if (key.isEmpty) return;
    setState(() {
      _error = null;
      if (key == 'C') {
        _expr = "";
        _result = "0";
        _justEvaluated = false;
        return;
      }
      if (key == '⌫') {
        if (_justEvaluated) {
          _justEvaluated = false;
        }
        if (_expr.isNotEmpty) {
          _expr = _expr.trimRight();
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
        }
        _expr = _expr.trimRight();
        _tryPreview();
        return;
      }
      if (key == '=') {
        _evaluateFinal();
        return;
      }
      if (key == 'x²') {
        _applySquare();
        return;
      }
      if (_justEvaluated) {
        if (_isOp(key)) {
          _expr = _result;
        } else {
          _expr = "";
        }
        _justEvaluated = false;
      }
      if (_expr.isEmpty && _isOp(key)) {
        if (key != '-') return;
      }
      if (_expr.isNotEmpty &&
          _isOp(key) &&
          _isOp(_expr.trimRight().isNotEmpty ? _expr.trimRight().characters.last : '')) {
        _expr = _expr.trimRight();
        _expr = _expr.substring(0, _expr.length - 1) + key;
      } else {
        _expr += key;
      }
      _expr = _expr.replaceAll(RegExp(r'\s+'), ' ');
      _tryPreview();
    });
  }

  void _applySquare() {
    if (_justEvaluated) {
      _expr = _result;
      _justEvaluated = false;
    }
    final raw = _expr.trimRight();
    if (raw.isEmpty) return;
    final match = RegExp(r'(\d+(\.\d+)?)$').firstMatch(raw);
    if (match == null) {
      return;
    }
    final numText = match.group(1)!;
    final start = match.start;
    final before = raw.substring(0, start);
    final replaced = '$before($numText)*($numText)';
    _expr = replaced;
    _tryPreview();
  }

  void _evaluateFinal() {
    try {
      if (_expr.isEmpty) return;
      final cleaned = _normalize(_expr);
      final value = _safeEval(cleaned);
      if (value == null) {
        _error = "Error";
        return;
      }
      _result = _format(value);
      _expr = "${_pretty(_expr)} = $_result";
      _justEvaluated = true;
    } catch (e) {
      _error = "Error";
    }
  }

  void _tryPreview() {
    try {
      final raw = _expr.trim();
      if (raw.isEmpty) {
        _result = "0";
        return;
      }
      final last = raw.characters.last;
      if (_isOp(last) || last == '.') return;
      final cleaned = _normalize(raw);
      final value = _safeEval(cleaned);
      if (value != null) {
        _result = _format(value);
      }
    } catch (_) {}
  }

  String _normalize(String s) {
    final t = s
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('–', '-')
        .replaceAll('=', '')
        .trim();
    return t;
  }

  String _pretty(String s) {
    return s
        .replaceAll('*', ' * ')
        .replaceAll('/', ' / ')
        .replaceAll('+', ' + ')
        .replaceAll('-', ' - ')
        .replaceAll('%', ' % ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  num? _safeEval(String input) {
    try {
      if (RegExp(r'/\s*0(?![0-9])').hasMatch(input)) {}
      final expr = Expression.parse(input);
      final evaluator = const ExpressionEvaluator();
      final value = evaluator.eval(expr, const {}) as num;
      if (value.isInfinite || value.isNaN) {
        _error = "Division by zero";
        return null;
      }
      return value;
    } catch (_) {
      _error ??= "Invalid expression";
      return null;
    }
  }

  String _format(num n) {
    final s = n.toString();
    if (s.contains('e') || s.contains('E')) return s;
    if (n is int || n == n.roundToDouble()) return n.round().toString();
    final asFixed = (n).toStringAsFixed(10);
    return asFixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            color: cs.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expr.isEmpty ? "0" : _pretty(_expr),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (_error == null)
                  Text(
                    _result,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                  )
                else
                  Text(
                    _error!,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.error),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: cs.surface,
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _keys.map((k) {
                  if (k.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final isAction = (k == 'C' || k == '⌫' || k == '=');
                  final isOpKey = _isOp(k);
                  final bg = k == '='
                      ? cs.primary
                      : isAction
                          ? cs.tertiaryContainer
                          : isOpKey
                              ? cs.secondaryContainer
                              : cs.surfaceContainerHigh;
                  final fg = k == '=' ? cs.onPrimary : null;
                  return ElevatedButton(
                    onPressed: () => _press(k),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bg,
                      foregroundColor: fg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      elevation: 0.5,
                    ),
                    child: Text(k),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
