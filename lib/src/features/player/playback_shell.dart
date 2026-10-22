import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_controller.dart';
import 'player_screen.dart';
import '../home/home_screen.dart';

class PlaybackShell extends ConsumerWidget {
  const PlaybackShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    return Stack(
      fit: StackFit.expand,
      children: [
        const HomeScreen(),
        if (session != null)
          _PlaybackOverlay(
            session: session,
            onMinimize: controller.minimize,
            onExpand: controller.expand,
            onClose: controller.close,
          ),
      ],
    );
  }
}

class _PlaybackOverlay extends StatefulWidget {
  const _PlaybackOverlay({
    required this.session,
    required this.onMinimize,
    required this.onExpand,
    required this.onClose,
  });

  final PlaybackSession session;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  State<_PlaybackOverlay> createState() => _PlaybackOverlayState();
}

class _PlaybackOverlayState extends State<_PlaybackOverlay> {
  Offset? _miniOffset;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isMini = session.mode == PlaybackMode.mini;
    final screenSize = MediaQuery.sizeOf(context);
    final miniSize = const Size(180, 101.25);
    final defaultOffset = Offset(
      screenSize.width - miniSize.width - 12,
      screenSize.height - miniSize.height - 88,
    );
    final offset = _miniOffset ?? defaultOffset;

    return Positioned.fill(
      child: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: isMini ? Colors.transparent : const Color(0xFF090909),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: isMini ? offset.dx : 0,
              top: isMini ? offset.dy : 0,
              width: isMini ? miniSize.width : screenSize.width,
              height: isMini ? miniSize.height : screenSize.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(isMini ? 12 : 0),
                  boxShadow: isMini
                      ? const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMini ? 12 : 0),
                  child: PlayerScreen(
                    key: ValueKey(
                      '${session.movie.id}-${session.season}-${session.episode}',
                    ),
                    movie: session.movie,
                    season: session.season,
                    episode: session.episode,
                    isMini: isMini,
                    onMinimize: widget.onMinimize,
                    onExpand: widget.onExpand,
                    onClose: widget.onClose,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isMini,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: offset,
                    child: SizedBox(
                      width: miniSize.width,
                      height: miniSize.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onExpand,
                        onPanUpdate: (details) {
                          final current = _miniOffset ?? offset;
                          setState(() {
                            _miniOffset = Offset(
                              (current.dx + details.delta.dx).clamp(
                                8.0,
                                screenSize.width - miniSize.width - 8,
                              ),
                              (current.dy + details.delta.dy).clamp(
                                8.0,
                                screenSize.height - miniSize.height - 8,
                              ),
                            );
                          });
                        },
                        onPanEnd: (_) {
                          final current = _miniOffset ?? offset;
                          final left = current.dx < screenSize.width / 2
                              ? 8.0
                              : screenSize.width - miniSize.width - 8;
                          setState(
                            () => _miniOffset = Offset(left, current.dy),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
