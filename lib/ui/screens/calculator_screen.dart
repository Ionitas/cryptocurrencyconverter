import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../widgets/currency_row_widget.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/currency_selector.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
  }

  @override
  void dispose() {
    _rotationController.stop();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyRows = ref.watch(currencyRowsProvider);
    final exchangeRates = ref.watch(exchangeRatesProvider);

    // Listen to exchange rates changes and control rotation
    ref.listen<AsyncValue<dynamic>>(exchangeRatesProvider, (previous, next) {
      if (!mounted) return;
      next.when(
        data: (_) => _rotationController.stop(),
        loading: () => _rotationController.repeat(),
        error: (_, __) => _rotationController.stop(),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          exchangeRates.when(
            data: (rates) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text('Updated: ${_formatLastUpdated(rates.lastUpdated)}', style: const TextStyle(fontSize: 12)),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: RotationTransition(turns: _rotationController, child: const Icon(Icons.refresh)),
            onPressed: () => ref.read(exchangeRatesProvider.notifier).refreshRates(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  exchangeRates.when(
                    data: (_) => const SizedBox(height: 1, child: SizedBox.shrink()),
                    loading: () => const SizedBox(height: 1, child: LinearProgressIndicator()),
                    error: (error, _) {
                      debugPrint('Error loading exchange rates: $error');
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Unable to load exchange rates. Please check your internet connection.',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  ...List.generate(
                    currencyRows.length,
                    (index) => CurrencyRowWidget(
                      row: currencyRows[index],
                      onTap: () {
                        ref.read(currencyRowsProvider.notifier).setActiveRow(index);
                        ref.read(calculatorProvider.notifier).clear(clearAllRows: false);
                      },
                      onIconTap: () async {
                        final selected = await showCurrencySelector(
                          context,
                          selectedCurrency: currencyRows[index].currency,
                        );
                        if (selected != null) {
                          ref.read(currencyRowsProvider.notifier).changeCurrency(index, selected);
                          exchangeRates.whenData(
                            (rates) => ref.read(currencyRowsProvider.notifier).updateConvertedValues(rates),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          NumericKeypad(
            onDigitPressed: (digit) => ref.read(calculatorProvider.notifier).inputDigit(digit),
            onClear: () => ref.read(calculatorProvider.notifier).clear(),
            onBackspace: () => ref.read(calculatorProvider.notifier).backspace(),
            onOperatorPressed: (operator) => ref.read(calculatorProvider.notifier).setOperator(operator),
            onEquals: () => ref.read(calculatorProvider.notifier).equals(),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(lastUpdated);
  }
}
