import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

class BottomPanel extends StatelessWidget {
  const BottomPanel({
    required this.logs,
    required this.onClosePressed,
    super.key,
  });

  final List<String> logs;
  final void Function() onClosePressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          ColoredBox(
            color: colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Logs',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(logs.length.toString()),
                    ),
                    const Spacer(),
                    IconButton(
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onClosePressed,
                      icon: const Icon(
                        Symbols.close_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 4),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                0,
                2,
                0,
                MediaQuery.paddingOf(context).bottom,
              ),
              reverse: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs.reversed.elementAt(index);
                return InkWell(
                  onTap: () {},
                  onLongPress: () =>
                      Clipboard.setData(ClipboardData(text: log)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      log,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
