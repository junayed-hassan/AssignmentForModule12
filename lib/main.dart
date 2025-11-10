import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('isDark') ?? false;
  runApp(CalculatorApp(initialDark: savedDark));
}

class CalculatorApp extends StatefulWidget {
  final bool initialDark;
  const CalculatorApp({Key? key, required this.initialDark}) : super(key: key);

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDark;
  }

  void _toggleTheme(bool value) async {
    setState(() => _isDark = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Calculator',
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: CalculatorPage(isDark: _isDark, onThemeChanged: _toggleTheme),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const CalculatorPage({
    Key? key,
    required this.isDark,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _lastPressed = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldClearDisplayOnNextDigit = false;

  static const List<String> operators = ['+', '-', '×', '÷'];

  void _onDigitPressed(String digit) {
    setState(() {
      if (_shouldClearDisplayOnNextDigit || _display == '0') {
        _display = digit;
        _shouldClearDisplayOnNextDigit = false;
      } else {
        _display += digit;
      }
      _lastPressed = 'digit';
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldClearDisplayOnNextDigit) {
        _display = '0.';
        _shouldClearDisplayOnNextDigit = false;
        _lastPressed = '.';
        return;
      }
      if (!_display.contains('.')) {
        _display += '.';
      }
      _lastPressed = '.';
    });
  }

  void _onAllClear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _lastPressed = '';
      _shouldClearDisplayOnNextDigit = false;
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      // Prevent multiple operators in a row: if last was operator, replace it
      if (_lastPressed == 'operator') {
        _operator = op;
        return;
      }

      // If there's an existing operator, compute first
      if (_operator != null && _firstOperand != null) {
        _compute();
      } else {
        _firstOperand = double.tryParse(_display);
      }

      _operator = op;
      _shouldClearDisplayOnNextDigit = true;
      _lastPressed = 'operator';
    });
  }

  void _onEqualPressed() {
    setState(() {
      if (_operator == null || _firstOperand == null) return;
      _compute();
      _operator = null;
      _firstOperand = null;
      _lastPressed = 'equal';
      _shouldClearDisplayOnNextDigit = true;
    });
  }

  void _compute() {
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;
    switch (_operator) {
      case '+':
        result = (_firstOperand ?? 0) + secondOperand;
        break;
      case '-':
        result = (_firstOperand ?? 0) - secondOperand;
        break;
      case '×':
        result = (_firstOperand ?? 0) * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = 'Error';
          _firstOperand = null;
          _operator = null;
          _shouldClearDisplayOnNextDigit = true;
          return;
        }
        result = (_firstOperand ?? 0) / secondOperand;
        break;
      default:
        return;
    }

    // Format result: remove trailing .0 when possible
    String text;
    if (result % 1 == 0) {
      text = result.toInt().toString();
    } else {
      // limit to reasonable decimal places
      text = result.toStringAsPrecision(12);
      // remove trailing zeros and possible trailing dot
      text = double.parse(text).toString();
    }

    _display = text;
    _firstOperand = double.tryParse(_display);
  }

  Widget _buildButton(
    String label, {
    double flex = 1,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isOperator = operators.contains(label) || label == '=';

    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                color ?? (isOperator ? theme.colorScheme.secondary : null),
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্যালকুলেটর'),
        actions: [
          Row(
            children: [
              const Text('Light'),
              Switch(value: widget.isDark, onChanged: widget.onThemeChanged),
              const Text('Dark'),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                flex: isPortrait ? 3 : 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _display,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildButton(
                          'AC',
                          onTap: _onAllClear,
                          color: Colors.redAccent,
                        ),
                        _buildButton('÷', onTap: () => _onOperatorPressed('÷')),
                        _buildButton('×', onTap: () => _onOperatorPressed('×')),
                        _buildButton('-', onTap: () => _onOperatorPressed('-')),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('7', onTap: () => _onDigitPressed('7')),
                        _buildButton('8', onTap: () => _onDigitPressed('8')),
                        _buildButton('9', onTap: () => _onDigitPressed('9')),
                        _buildButton('+', onTap: () => _onOperatorPressed('+')),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('4', onTap: () => _onDigitPressed('4')),
                        _buildButton('5', onTap: () => _onDigitPressed('5')),
                        _buildButton('6', onTap: () => _onDigitPressed('6')),
                        _buildButton(
                          '=',
                          onTap: _onEqualPressed,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('1', onTap: () => _onDigitPressed('1')),
                        _buildButton('2', onTap: () => _onDigitPressed('2')),
                        _buildButton('3', onTap: () => _onDigitPressed('3')),
                        _buildButton('.', onTap: _onDecimalPressed),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton(
                          '0',
                          flex: 2,
                          onTap: () => _onDigitPressed('0'),
                        ),
                        _buildButton('00', onTap: () => _onDigitPressed('00')),
                        _buildButton('%', onTap: _onPercentPressed),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPercentPressed() {
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = value / 100;
      // format
      if (result % 1 == 0) {
        _display = result.toInt().toString();
      } else {
        _display = double.parse(result.toStringAsPrecision(12)).toString();
      }
      _shouldClearDisplayOnNextDigit = true;
      _lastPressed = '%';
    });
  }
}
