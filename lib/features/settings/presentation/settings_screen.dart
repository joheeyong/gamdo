import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark mode
          Card(
            child: SwitchListTile(
              title: Text(context.l10n.darkMode),
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              value: isDarkMode,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 16),

          // API Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.api_outlined,
                          color: context.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.apiSettings,
                        style: context.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProxyUrlField(),
                  const SizedBox(height: 12),
                  _AppTokenField(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  '감도 v1.0.0',
                  style: context.textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Claude Vision',
                  style: context.textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProxyUrlField extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProxyUrlField> createState() => _ProxyUrlFieldState();
}

class _ProxyUrlFieldState extends ConsumerState<_ProxyUrlField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proxyUrl = ref.watch(proxyUrlSettingProvider);

    proxyUrl.whenData((url) {
      if (_controller.text.isEmpty && url.isNotEmpty) {
        _controller.text = url;
      }
    });

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.l10n.proxyUrl,
        hintText: 'https://your-worker.workers.dev',
        suffixIcon: IconButton(
          icon: const Icon(Icons.save_outlined),
          onPressed: () {
            ref
                .read(proxyUrlSettingProvider.notifier)
                .save(_controller.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.l10n.save}!')),
            );
          },
        ),
      ),
    );
  }
}

class _AppTokenField extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppTokenField> createState() => _AppTokenFieldState();
}

class _AppTokenFieldState extends ConsumerState<_AppTokenField> {
  late TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appToken = ref.watch(appTokenSettingProvider);

    appToken.whenData((token) {
      if (_controller.text.isEmpty && token.isNotEmpty) {
        _controller.text = token;
      }
    });

    return TextField(
      controller: _controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: context.l10n.appToken,
        hintText: 'your-app-token',
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: () {
                ref
                    .read(appTokenSettingProvider.notifier)
                    .save(_controller.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${context.l10n.save}!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
