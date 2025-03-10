import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/network_info_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/ui/home_tab_provider.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/util/sleep.dart';
import 'package:localsend_app/widget/animations/initial_fade_transition.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/dialogs/quick_save_notice.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';
import 'package:routerino/routerino.dart';

class ReceiveTab extends StatefulWidget {
  const ReceiveTab({Key? key}) : super(key: key);

  @override
  State<ReceiveTab> createState() => _ReceiveTagState();
}

class _ReceiveTagState extends State<ReceiveTab> with AutomaticKeepAliveClientMixin, Riverpie {
  bool _advanced = false;
  bool _showHistoryButton = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final settings = ref.watch(settingsProvider);
    final networkInfo = ref.watch(networkStateProvider);
    final serverState = ref.watch(serverProvider);

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ResponsiveListView.defaultMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InitialFadeTransition(
                                duration: const Duration(milliseconds: 300),
                                delay: const Duration(milliseconds: 200),
                                child: Consumer(builder: (context, ref) {
                                  final animations = ref.watch(animationProvider);
                                  final activeTab = ref.watch(homeTabProvider);
                                  return RotatingWidget(
                                    duration: const Duration(seconds: 15),
                                    spinning: serverState != null && animations && activeTab == HomeTab.receive,
                                    child: const LocalSendLogo(withText: false),
                                  );
                                }),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(serverState?.alias ?? settings.alias, style: const TextStyle(fontSize: 48)),
                              ),
                              InitialFadeTransition(
                                duration: const Duration(milliseconds: 300),
                                delay: const Duration(milliseconds: 500),
                                child: Text(
                                  serverState == null ? t.general.offline : networkInfo.localIps.map((ip) => '#${ip.visualId}').toSet().join(' '),
                                  style: const TextStyle(fontSize: 24),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: settings.quickSave
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).buttonTheme.colorScheme!.primary,
                                foregroundColor: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                              ),
                              onPressed: () async => ref.notifier(settingsProvider).setQuickSave(false),
                              child: Text('${t.general.quickSave}: ${t.general.on}'),
                            )
                          : TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                              onPressed: () async {
                                await ref.notifier(settingsProvider).setQuickSave(true);
                                if (mounted) {
                                  await QuickSaveNotice.open(context);
                                }
                              },
                              child: Text('${t.general.quickSave}: ${t.general.off}'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState: _advanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstChild: Container(),
          secondChild: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                    },
                    children: [
                      TableRow(
                        children: [
                          Text(t.receiveTab.infoBox.alias),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: SelectableText(serverState?.alias ?? '-'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(t.receiveTab.infoBox.ip),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (networkInfo.localIps.isEmpty) Text(t.general.unknown),
                              ...networkInfo.localIps.map((ip) => SelectableText(ip)),
                            ],
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(t.receiveTab.infoBox.port),
                          const SizedBox(width: 10),
                          SelectableText(serverState?.port.toString() ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_advanced)
                  AnimatedOpacity(
                    opacity: _showHistoryButton ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: CustomIconButton(
                      onPressed: () async {
                        await context.push(() => const ReceiveHistoryPage());
                      },
                      child: const Icon(Icons.history),
                    ),
                  ),
                CustomIconButton(
                  key: const ValueKey('info-btn'),
                  onPressed: () async {
                    if (_advanced) {
                      setState(() => _advanced = false);
                      await sleepAsync(200);
                      if (mounted) {
                        setState(() => _showHistoryButton = true);
                      }
                    } else {
                      setState(() {
                        _advanced = true;
                        _showHistoryButton = false;
                      });
                    }
                  },
                  child: const Icon(Icons.info),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
