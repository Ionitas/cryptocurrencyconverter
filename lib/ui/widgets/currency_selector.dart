import 'package:flutter/material.dart';
import '../../models/currency.dart';

class CurrencySelector extends StatefulWidget {
  final Currency? selectedCurrency;

  const CurrencySelector({super.key, this.selectedCurrency});

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Select Currency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value.toLowerCase();
              }),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Fiat'),
                Tab(text: 'Crypto'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCurrencyList(Currencies.allFiat), _buildCurrencyList(Currencies.allCrypto)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyList(List<Currency> currencies) {
    final filtered = currencies.where((currency) {
      if (_searchQuery.isEmpty) return true;
      return currency.code.toLowerCase().contains(_searchQuery) || currency.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final currency = filtered[index];
        final isSelected = currency == widget.selectedCurrency;

        return ListTile(
          title: Text(currency.name),
          subtitle: Text(currency.code),
          trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
          selected: isSelected,
          onTap: () => Navigator.of(context).pop(currency),
        );
      },
    );
  }
}

Future<Currency?> showCurrencySelector(BuildContext context, {Currency? selectedCurrency}) async {
  return showDialog<Currency>(
    context: context,
    builder: (context) => CurrencySelector(selectedCurrency: selectedCurrency),
  );
}
