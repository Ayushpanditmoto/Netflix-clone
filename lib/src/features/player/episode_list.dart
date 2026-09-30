import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/shimmer.dart';
import 'player_sheet.dart';

/// Season selector plus the episode list for a series, mirroring the layout
/// streaming sites use: swipe left/right to move between seasons, with a row of
/// season tabs that stays in sync with the visible page.
///
/// Episodes are labelled `S1:E1  •  1x01`.
class EpisodeList extends ConsumerStatefulWidget {
  const EpisodeList({super.key, required this.movie});

  final Movie movie;

  @override
  ConsumerState<EpisodeList> createState() => _EpisodeListState();
}

class _EpisodeListState extends ConsumerState<EpisodeList> {
  /// The season number the user is looking at, or null before the first
  /// season list arrives.
  int? _selected;

  /// Created lazily because the initial page depends on which season is
  /// selected by default, which is only known once the seasons load.
  PageController? _pageController;
  final _tabsScrollController = ScrollController();
  final _tabKeys = <int, GlobalKey>{};

  @override
  void dispose() {
    _pageController?.dispose();
    _tabsScrollController.dispose();
    super.dispose();
  }

  GlobalKey _tabKey(int seasonNumber) =>
      _tabKeys.putIfAbsent(seasonNumber, GlobalKey.new);

  /// Index of the newest real season, skipping the "Specials" bucket by
  /// default while still allowing it to be swiped to.
  int _defaultIndex(List<Season> seasons) {
    var best = 0;
    for (var i = 0; i < seasons.length; i++) {
      if (seasons[i].number > seasons[best].number) best = i;
    }
    return seasons[best].number > 0 ? best : 0;
  }

  /// Keeps the chosen season if it still exists, otherwise falls back to the
  /// newest real season.
  int _resolveIndex(List<Season> seasons) {
    final current = _selected;
    if (current == null) return _defaultIndex(seasons);
    final index = seasons.indexWhere((season) => season.number == current);
    return index == -1 ? _defaultIndex(seasons) : index;
  }

  void _onPageChanged(int index, List<Season> seasons) {
    setState(() => _selected = seasons[index].number);
    _revealTab(index, seasons);
  }

  /// Scrolls the tab row so the active tab stays visible after a swipe.
  void _revealTab(int index, List<Season> seasons) {
    final key = _tabKeys[seasons[index].number];
    final context = key?.currentContext;
    if (context == null || !_tabsScrollController.hasClients) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = seasonsProvider(widget.movie.id);
    final seasons = ref.watch(provider);

    return seasons.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Shimmer(child: ShimmerBox(height: 44, borderRadius: 99)),
      ),
      error: (error, stackTrace) => TextButton.icon(
        onPressed: () => ref.invalidate(provider),
        icon: const Icon(Icons.refresh),
        label: const Text('Retry seasons'),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'No seasons listed for this series.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        final index = _resolveIndex(list);
        final seasonNumber = list[index].number;
        _pageController ??= PageController(initialPage: index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeasonTabs(
              seasons: list,
              selectedIndex: index,
              scrollController: _tabsScrollController,
              tabKeyFor: _tabKey,
              onSelected: (next) {
                _pageController?.animateToPage(
                  next,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
            const SizedBox(height: 14),
            _SeasonPages(
              seriesId: widget.movie.id,
              seasons: list,
              initialIndex: index,
              controller: _pageController!,
              onPageChanged: (next) => _onPageChanged(next, list),
              currentSeasonNumber: seasonNumber,
            ),
          ],
        );
      },
    );
  }
}

/// Season tabs that mirror the swipeable pages below them. Tapping a tab
/// animates the pager; swiping the pager moves the selection here.
class _SeasonTabs extends StatelessWidget {
  const _SeasonTabs({
    required this.seasons,
    required this.selectedIndex,
    required this.scrollController,
    required this.tabKeyFor,
    required this.onSelected,
  });

  final List<Season> seasons;
  final int selectedIndex;
  final ScrollController scrollController;
  final GlobalKey Function(int seasonNumber) tabKeyFor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final season = seasons[index];
          final isSelected = index == selectedIndex;
          return ChoiceChip(
            key: tabKeyFor(season.number),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (value) => onSelected(index),
            label: Text(
              season.number == 0 ? 'Specials' : 'Season ${season.number}',
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            selectedColor: const Color(0xFFE50914),
            backgroundColor: const Color(0xFF1D1D1D),
            side: BorderSide(
              color: isSelected ? const Color(0xFFE50914) : Colors.white12,
            ),
          );
        },
      ),
    );
  }
}

/// One swipeable page per season.
///
/// The height is driven by the tallest page so the pager does not resize while
/// the user swipes, which would make the gesture feel like it is fighting the
/// layout. Pages scroll internally when their episodes overflow.
class _SeasonPages extends ConsumerWidget {
  const _SeasonPages({
    required this.seriesId,
    required this.seasons,
    required this.initialIndex,
    required this.controller,
    required this.onPageChanged,
    required this.currentSeasonNumber,
  });

  final int seriesId;
  final List<Season> seasons;
  final int initialIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  /// The season currently on screen, used to size the viewport to the content
  /// the user is actually looking at.
  final int currentSeasonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = episodesProvider((
      seriesId: seriesId,
      seasonNumber: currentSeasonNumber,
    ));
    final height = _heightFor(ref.watch(current));

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemCount: seasons.length,
        itemBuilder: (context, index) =>
            _Episodes(seriesId: seriesId, season: seasons[index].number),
      ),
    );
  }

  /// Roughly one row per episode, capped so a long season scrolls inside the
  /// page instead of stretching the sheet to an unusable height.
  double _heightFor(AsyncValue<List<Episode>> episodes) {
    return episodes.when(
      loading: () => _rowHeight * 3,
      error: (error, stackTrace) => 72,
      data: (list) {
        if (list.isEmpty) return 72;
        final visible = list.length > _maxVisibleRows
            ? _maxVisibleRows
            : list.length;
        return _rowHeight * visible;
      },
    );
  }
}

const double _rowHeight = 104;
const int _maxVisibleRows = 4;

class _Episodes extends ConsumerWidget {
  const _Episodes({required this.seriesId, required this.season});

  final int seriesId;
  final int season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = episodesProvider((
      seriesId: seriesId,
      seasonNumber: season,
    ));
    final episodes = ref.watch(provider);

    // The page has a fixed height, so a long season scrolls inside itself
    // rather than growing the bottom sheet mid-swipe.
    return episodes.when(
      loading: () => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Shimmer(child: SizedBox(height: 92, child: ShimmerBox())),
          ),
        ),
      ),
      error: (error, stackTrace) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          TextButton.icon(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry episodes'),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'No episodes listed for this season.',
            style: TextStyle(color: Colors.white54),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _EpisodeRow(seriesId: seriesId, episode: list[index]),
        );
      },
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.seriesId, required this.episode});

  final int seriesId;
  final Episode episode;

  /// Playback needs the *series* id while the sheet should show the episode
  /// title, so a Movie carrying both is synthesised here instead of threading
  /// two objects through the player.
  Movie get _asMovie => Movie(
    id: seriesId,
    title: episode.title,
    overview: episode.overview,
    posterPath: null,
    backdropPath: episode.stillPath,
    releaseDate: episode.airDate,
    voteAverage: episode.voteAverage,
    mediaType: 'tv',
  );

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (episode.airDateLabel.isNotEmpty) episode.airDateLabel,
      if (episode.runtime != null) '${episode.runtime} min',
    ].join('  •  ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showPlayerSheet(
        context,
        _asMovie,
        season: episode.seasonNumber,
        episode: episode.number,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PosterImage(imageUrl: episode.stillUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EpisodeText(episode: episode, meta: meta),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 28),
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white70,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeText extends StatelessWidget {
  const _EpisodeText({required this.episode, required this.meta});

  final Episode episode;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'S${episode.seasonNumber}:E${episode.number}  •  ${episode.code}',
          style: const TextStyle(
            color: Color(0xFFE50914),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          episode.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        if (episode.overview.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            episode.overview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            meta,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
