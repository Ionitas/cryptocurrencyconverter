import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final Function(String) onOperatorPressed;
  final VoidCallback onEquals;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onClear,
    required this.onBackspace,
    required this.onOperatorPressed,
    required this.onEquals,
  });

  @override
  Widget build(BuildContext context) {
    final decimalSeparator = NumberFormat.decimalPattern().symbols.DECIMAL_SEP;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildButton('7', onDigitPressed, context),
              _buildButton('8', onDigitPressed, context),
              _buildButton('9', onDigitPressed, context),
              _buildOperatorButton('/', onOperatorPressed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildButton('4', onDigitPressed, context),
              _buildButton('5', onDigitPressed, context),
              _buildButton('6', onDigitPressed, context),
              _buildOperatorButton('*', onOperatorPressed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildButton('1', onDigitPressed, context),
              _buildButton('2', onDigitPressed, context),
              _buildButton('3', onDigitPressed, context),
              _buildOperatorButton('-', onOperatorPressed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildButton(decimalSeparator, onDigitPressed, context),
              _buildButton('0', onDigitPressed, context),
              _buildButton('000', onDigitPressed, context),
              _buildOperatorButton('+', onOperatorPressed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpecialButton('C', onClear, Colors.red),
              _buildSpecialButton('←', onBackspace, Colors.orange),
              _buildSpecialButton('=', onEquals, Colors.green, flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Function(String) onPressed, BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => onPressed(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildOperatorButton(String label, Function(String) onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => onPressed(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(String label, VoidCallback onPressed, Color color, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
