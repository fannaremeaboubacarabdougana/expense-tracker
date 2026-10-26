import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import '../services/currency_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;
  final CurrencyService currencyService;

  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================
          // APPEARANCE SETTINGS
          // ==========================================
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Card(
            child: AnimatedBuilder(
              animation: themeService,
              builder: (context, _) {
                return RadioGroup<ThemeMode>(
                  groupValue: themeService.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System default'),
                        subtitle: Text('Follow your device appearance'),
                        value: ThemeMode.system,
                      ),

                      RadioListTile<ThemeMode>(
                        title: Text('Light mode'),
                        value: ThemeMode.light,
                      ),

                      RadioListTile<ThemeMode>(
                        title: Text('Dark mode'),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // CURRENCY SETTINGS
          // ==========================================
          const Text(
            'Currency',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            child: AnimatedBuilder(
              animation: currencyService,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(currencyService.currencyCode),
                    initialValue: currencyService.currencyCode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Preferred currency',
                      prefixIcon: Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(),
                    ),
                    items: CurrencyService.currencies.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text('${entry.key} (${entry.value})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        currencyService.setCurrency(value);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Changing the currency changes the displayed '
              'symbol only. It does not convert amounts '
              'using exchange rates.',
              style: TextStyle(fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // ABOUT SECTION
          // ==========================================
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const Card(
            child: ListTile(
              leading: Icon(Icons.account_balance_wallet),
              title: Text('Expense Tracker'),
              subtitle: Text(
                'Track expenses, analyze spending, '
                'and manage recurring payments.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
