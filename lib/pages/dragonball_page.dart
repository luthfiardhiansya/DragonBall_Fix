import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import '../models/dragonball.dart';
import '../splash/dragonball_splash.dart';
import '../theme/app_theme.dart';
import 'dragonball_detail_page.dart';

class DragonballLoadingPage extends StatelessWidget {
  const DragonballLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DragonballSplashScreen(
      onFinished: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DragonballPage()),
        );
      },
    );
  }
}

class DragonballPage extends StatefulWidget {
  const DragonballPage({super.key});

  @override
  State<DragonballPage> createState() => _DragonballPageState();
}

class _DragonballPageState extends State<DragonballPage>
    with TickerProviderStateMixin {
  static const String _lottieAnimationUrl =
      'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json';

  static final Uri _charactersUri = Uri.parse(
    'https://dragonball-api.com/api/characters?limit=100',
  );

  final TextEditingController _searchController = TextEditingController();
  late Future<Dragonball> _charactersFuture;
  Gender? _selectedGender;
  Race? _selectedRace;
  Affiliation? _selectedAffiliation;
  double? _minimumKi;
  double? _maximumKi;
  Timer? _filterLoadingTimer;
  bool _isFilterLoading = false;
  int _currentTab = 0;
  final Set<int> _favoriteIds = <int>{};
  final GlobalKey _favoriteNavKey = GlobalKey();
  final GlobalKey _dragonBallNavKey = GlobalKey();
  OverlayEntry? _summonEntry;

  @override
  void initState() {
    super.initState();
    _charactersFuture = _fetchCharacters();
  }

  @override
  void dispose() {
    _filterLoadingTimer?.cancel();
    _summonEntry?.remove();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterLoading() {
    _filterLoadingTimer?.cancel();
    setState(() => _isFilterLoading = true);
    _filterLoadingTimer = Timer(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _isFilterLoading = false);
    });
  }

  void _onSearchChanged(String _) {
    setState(() {});
  }

  void _onGenderChanged(Gender? gender) {
    setState(() => _selectedGender = gender);
    _showFilterLoading();
  }

  void _onRaceChanged(Race? race) {
    setState(() => _selectedRace = race);
    _showFilterLoading();
  }

  void _onAffiliationChanged(Affiliation? affiliation) {
    setState(() => _selectedAffiliation = affiliation);
    _showFilterLoading();
  }

  Future<Dragonball> _fetchCharacters() async {
    final response = await http.get(_charactersUri);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data karakter (${response.statusCode})');
    }

    return dragonballFromJson(response.body);
  }

  Future<void> _refresh() async {
    setState(() {
      _charactersFuture = _fetchCharacters();
    });
    await _charactersFuture;
  }

  List<Item> _filterCharacters(List<Item> characters) {
    final query = _searchController.text.trim().toLowerCase();

    return characters.where((character) {
      final matchesName = character.name.toLowerCase().contains(query);
      final matchesGender =
          _selectedGender == null || character.gender == _selectedGender;
      final matchesRace =
          _selectedRace == null || character.race == _selectedRace;
      final matchesAffiliation =
          _selectedAffiliation == null ||
          character.affiliation == _selectedAffiliation;
      final characterKi = kiToNumber(character.ki);
      final matchesMinimumKi =
          _minimumKi == null ||
          (characterKi != null && characterKi >= _minimumKi!);
      final matchesMaximumKi =
          _maximumKi == null ||
          (characterKi != null && characterKi <= _maximumKi!);

      return (_currentTab != 2 || _favoriteIds.contains(character.id)) &&
          matchesName &&
          matchesGender &&
          matchesRace &&
          matchesAffiliation &&
          matchesMinimumKi &&
          matchesMaximumKi;
    }).toList();
  }

  void _toggleFavorite(Item character, BuildContext sourceContext) {
    final adding = !_favoriteIds.contains(character.id);
    setState(() {
      if (adding) {
        _favoriteIds.add(character.id);
      } else {
        _favoriteIds.remove(character.id);
      }
    });
    if (adding) _flyFavoriteIcon(sourceContext);
  }

  void _startSummon(List<Item> characters) {
    if (_summonEntry != null || characters.isEmpty) return;

    final sourceBox =
        _dragonBallNavKey.currentContext?.findRenderObject() as RenderBox?;
    final screen = MediaQuery.sizeOf(context);
    final startPosition = sourceBox == null
        ? Offset(screen.width / 2, screen.height - 50)
        : sourceBox.localToGlobal(
            Offset(sourceBox.size.width / 2, sourceBox.size.height / 2),
          );
    final character = (List<Item>.from(characters)..shuffle()).first;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SummonOverlay(
        character: character,
        startPosition: startPosition,
        onDismiss: () {
          if (identical(_summonEntry, entry)) _summonEntry = null;
          entry.remove();
        },
        onOpenDetails: (selectedCharacter) {
          if (identical(_summonEntry, entry)) _summonEntry = null;
          entry.remove();
          _openCharacterDetails(selectedCharacter);
        },
      ),
    );
    _summonEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _flyFavoriteIcon(BuildContext sourceContext) {
    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    if (sourceBox == null) return;
    final start = sourceBox.localToGlobal(
      Offset(sourceBox.size.width / 2, sourceBox.size.height / 2),
    );
    final targetBox =
        _favoriteNavKey.currentContext?.findRenderObject() as RenderBox?;
    final end = targetBox == null
        ? Offset(
            MediaQuery.sizeOf(context).width * .7,
            MediaQuery.sizeOf(context).height - 44,
          )
        : targetBox.localToGlobal(
            Offset(targetBox.size.width / 2, targetBox.size.height / 2),
          );
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final position = Offset.lerp(start, end, animation.value)!;
          return Positioned(
            left: position.dx - 14,
            top: position.dy - 14,
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          );
        },
      ),
    );
    overlay.insert(entry);
    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }

  void _openCharacterDetails(Item character) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 720),
        reverseTransitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, _) =>
            DragonballDetailPage(character: character),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: .86, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedGender != null ||
      _selectedRace != null ||
      _selectedAffiliation != null ||
      _minimumKi != null ||
      _maximumKi != null;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedGender = null;
      _selectedRace = null;
      _selectedAffiliation = null;
      _minimumKi = null;
      _maximumKi = null;
    });
    _showFilterLoading();
  }

  Future<void> _showKiFilterDialog() async {
    final minimumController = TextEditingController(
      text: _minimumKi == null ? '' : _formatNumber(_minimumKi!),
    );
    final maximumController = TextEditingController(
      text: _maximumKi == null ? '' : _formatNumber(_maximumKi!),
    );

    final result = await showDialog<_KiRange>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filter jumlah Ki'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minimumController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ki minimum',
                  hintText: 'Contoh: 1000',
                  prefixIcon: Icon(Icons.south_west),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maximumController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ki maksimum',
                  hintText: 'Contoh: 1000000',
                  prefixIcon: Icon(Icons.north_east),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, const _KiRange()),
              child: const Text('Hapus'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  _KiRange(
                    minimum: _parseInputNumber(minimumController.text),
                    maximum: _parseInputNumber(maximumController.text),
                  ),
                );
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );

    minimumController.dispose();
    maximumController.dispose();

    if (result != null && mounted) {
      setState(() {
        _minimumKi = result.minimum;
        _maximumKi = result.maximum;
      });
      _showFilterLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dragon Ball Characters'),
      ),
      body: FutureBuilder<Dragonball>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null || data.items.isEmpty) {
            return Center(
              child: Text(
                'Data karakter tidak ditemukan.',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          final filteredCharacters = _filterCharacters(data.items);

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refresh,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (_currentTab == 1)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        sliver: SliverToBoxAdapter(
                          child: _FilterPanel(
                            controller: _searchController,
                            selectedGender: _selectedGender,
                            selectedRace: _selectedRace,
                            selectedAffiliation: _selectedAffiliation,
                            minimumKi: _minimumKi,
                            maximumKi: _maximumKi,
                            hasActiveFilters: _hasActiveFilters,
                            onSearchChanged: _onSearchChanged,
                            onGenderChanged: _onGenderChanged,
                            onRaceChanged: _onRaceChanged,
                            onAffiliationChanged: _onAffiliationChanged,
                            onKiFilterTap: _showKiFilterDialog,
                            onReset: _resetFilters,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      sliver: SliverToBoxAdapter(
                        child: _ResultSummary(
                          total: data.items.length,
                          shown: filteredCharacters.length,
                          isFavoriteTab: _currentTab == 2,
                        ),
                      ),
                    ),
                    if (filteredCharacters.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _currentTab == 2
                            ? const _EmptyFavoriteResult()
                            : const _EmptySearchResult(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 1100
                                ? 5
                                : constraints.crossAxisExtent >= 800
                                ? 4
                                : constraints.crossAxisExtent >= 560
                                ? 3
                                : 2;

                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 294,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final character = filteredCharacters[index];
                                return _CharacterCard(
                                  character: character,
                                  onTap: () => _showCharacterDetails(character),
                                  isFavorite: _favoriteIds.contains(
                                    character.id,
                                  ),
                                  onFavorite: (sourceContext) =>
                                      _toggleFavorite(character, sourceContext),
                                );
                              }, childCount: filteredCharacters.length),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_isFilterLoading) const _FilterLoadingOverlay(),
            ],
          );
        },
      ),
      bottomNavigationBar: _DragonballBottomBar(
        favoriteKey: _favoriteNavKey,
        dragonBallKey: _dragonBallNavKey,
        currentIndex: _currentTab == 2 ? 3 : _currentTab,
        onSelected: (index) {
          if (index == 2) {
            _charactersFuture.then((data) => _startSummon(data.items));
            return;
          }
          if (index == 4) return;
          setState(() => _currentTab = index == 3 ? 2 : index);
        },
      ),
    );
  }

  void _showCharacterDetails(Item character) {
    _filterLoadingTimer?.cancel();
    setState(() => _isFilterLoading = true);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isFilterLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DragonballDetailPage(character: character),
        ),
      );
    });
  }
}

class _DragonballBottomBar extends StatelessWidget {
  const _DragonballBottomBar({
    required this.favoriteKey,
    required this.dragonBallKey,
    required this.currentIndex,
    required this.onSelected,
  });

  final GlobalKey? favoriteKey;
  final GlobalKey dragonBallKey;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 122,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 88,
              child: Material(
                color: colors.surface,
                elevation: 8,
                child: Row(
                  children: [
                    _item(context, Icons.grid_view_rounded, 'Gallery', 0),
                    _item(context, Icons.search_rounded, 'Search', 1),
                    const Expanded(child: SizedBox()),
                    _item(
                      context,
                      Icons.favorite_rounded,
                      'Favorite',
                      3,
                      key: favoriteKey,
                    ),
                    _themeModeButton(context),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  key: dragonBallKey,
                  onTap: () => onSelected(2),
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/bola.png', fit: BoxFit.cover),
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

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    Key? key,
  }) {
    return _navButton(context, icon, label, index, key: key);
  }

  Widget _themeModeButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeMode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          return InkWell(
            onTap: () {
              appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: colors.primary,
                ),
                const SizedBox(height: 3),
                Text(
                  isDark ? 'Light' : 'Dark',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    VoidCallback? onPressed,
    Key? key,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        key: key,
        onTap: onPressed ?? () => onSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: selected ? colors.primary : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummonOverlay extends StatefulWidget {
  const _SummonOverlay({
    required this.character,
    required this.startPosition,
    required this.onDismiss,
    required this.onOpenDetails,
  });

  final Item character;
  final Offset startPosition;
  final VoidCallback onDismiss;
  final ValueChanged<Item> onOpenDetails;

  @override
  State<_SummonOverlay> createState() => _SummonOverlayState();
}

class _SummonOverlayState extends State<_SummonOverlay>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 7200);

  late final AnimationController _controller;
  late final Animation<double> _flight;
  final AudioPlayer _flightSound = AudioPlayer();
  final AudioPlayer _crackSound = AudioPlayer();
  final AudioPlayer _burstSound = AudioPlayer();
  late Item _character;
  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _controller = AnimationController(vsync: this, duration: _duration);
    _flight =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 0.05),
            weight: 12,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.05,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            weight: 88,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(.08, .46)),
        );
    _controller.addListener(_handleSoundCues);
    _playSound(_flightSound, 'audio/gacha_flight.wav');
    _controller.forward();
  }

  void _handleSoundCues() {
    final progress = _controller.value;
    if (_lastProgress < .53 && progress >= .53) {
      _playSound(_crackSound, 'audio/gacha_crack.wav');
      HapticFeedback.mediumImpact();
    }
    if (_lastProgress < .72 && progress >= .72) {
      _playSound(_burstSound, 'audio/gacha_burst.wav');
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    }
    _lastProgress = progress;
  }

  Future<void> _playSound(AudioPlayer player, String asset) async {
    try {
      await player.setVolume(.85);
      await player.play(AssetSource(asset));
    } catch (_) {
      // Audio is optional on platforms where sound is unavailable.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flightSound.dispose();
    _crackSound.dispose();
    _burstSound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final size = MediaQuery.sizeOf(context);
          final center = Offset(size.width / 2, size.height / 2 - 35);
          final flightPosition = Offset.lerp(
            widget.startPosition,
            center,
            _flight.value,
          )!;
          final ballPosition = t < .47 ? flightPosition : center;
          final shakeProgress = Curves.easeIn.transform(
            ((t - .47) / .28).clamp(0.0, 1.0).toDouble(),
          );
          final shake = math.sin(t * 150) * 18 * shakeProgress;
          final flash =
              ((t - .66) / .1).clamp(0.0, 1.0).toDouble() *
              (1 - ((t - .76) / .12).clamp(0.0, 1.0).toDouble());
          final characterProgress = Curves.easeOutCubic.transform(
            ((t - .72) / .18).clamp(0.0, 1.0).toDouble(),
          );
          final isFinal = t >= .9;
          // Rotate toward the edge and return to the front face. This keeps
          // the artwork readable instead of showing a mirrored back face.
          final rotation = characterProgress < .5
              ? characterProgress * math.pi
              : (1 - characterProgress) * math.pi;
          final characterScale =
              0.72 +
              (math.sin(characterProgress * math.pi) * .12) +
              (characterProgress * .28);
          final ballScale = t < .1
              ? 1 + Curves.easeOutBack.transform(t / .1) * .16
              : 1.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: (.72 * Curves.easeIn.transform((t / .2).clamp(0, 1)))
                        .clamp(0, .72),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _SummonParticlesPainter(progress: t),
                ),
              ),
              if (t < .82)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _SummonTrailPainter(
                      start: widget.startPosition,
                      end: center,
                      progress: _flight.value,
                    ),
                  ),
                ),
              if (t < .82)
                Positioned(
                  left: ballPosition.dx - 80 + shake,
                  top: ballPosition.dy - 80,
                  child: Transform.rotate(
                    angle: t * math.pi * 2.4,
                    child: Transform.scale(
                      scale: ballScale,
                      child: _SummonDragonBall(progress: t, flash: flash),
                    ),
                  ),
                ),
              if (t >= .68)
                Center(
                  child: IgnorePointer(
                    ignoring: !isFinal,
                    child: GestureDetector(
                      onTap: isFinal
                          ? () => widget.onOpenDetails(_character)
                          : null,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0016)
                          ..rotateY(rotation)
                          ..scale(characterScale),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _SummonAura(progress: characterProgress),
                            ColorFiltered(
                              colorFilter: characterProgress < .7
                                  ? const ColorFilter.matrix(<double>[
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0,
                                    ])
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.dst,
                                    ),
                              child: Hero(
                                tag: 'dragonball-character-${_character.id}',
                                child: Image.network(
                                  _character.image,
                                  width: 230,
                                  height: 330,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (flash > 0)
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: flash * .78),
                  ),
                ),
              if (isFinal)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28,
                  child: AnimatedOpacity(
                    opacity: isFinal ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: _SummonResultPanel(character: _character),
                  ),
                ),
              if (isFinal)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  right: 12,
                  child: IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummonDragonBall extends StatelessWidget {
  const _SummonDragonBall({required this.progress, required this.flash});

  final double progress;
  final double flash;

  @override
  Widget build(BuildContext context) {
    final shake = ((progress - .47) / .25).clamp(0, 1);
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              const Color(0xFFFF7A00),
              Colors.white,
              flash,
            )!.withValues(alpha: .58 + shake * .25),
            blurRadius: 22 + shake * 26,
            spreadRadius: 2 + shake * 8,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipOval(child: Image.asset('assets/bola.png', fit: BoxFit.cover)),
          if (progress >= .56)
            CustomPaint(painter: _SummonCrackPainter(progress: progress)),
        ],
      ),
    );
  }
}

class _SummonTrailPainter extends CustomPainter {
  const _SummonTrailPainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  final Offset start;
  final Offset end;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 9; i++) {
      final dotProgress = (progress - i * .035).clamp(0.0, 1.0).toDouble();
      final dot = Offset.lerp(start, end, dotProgress)!;
      canvas.drawCircle(
        dot,
        (4 - i * .3).clamp(1.0, 4.0).toDouble(),
        Paint()
          ..color = const Color(0xFFFFC107).withValues(alpha: .7 - i * .06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SummonTrailPainter oldDelegate) => true;
}

class _SummonParticlesPainter extends CustomPainter {
  const _SummonParticlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 35);
    for (var i = 0; i < 30; i++) {
      final angle = i * .87;
      final distance = 45 + ((progress * 260 + i * 19) % 280);
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final radius = 1.2 + ((i + progress * 10) % 3) * .5;
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = const Color(0xFFFFB300)
              .withValues(alpha: .15 + (i % 4) * .08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SummonParticlesPainter oldDelegate) => true;
}

class _SummonCrackPainter extends CustomPainter {
  const _SummonCrackPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent.withValues(
        alpha: ((progress - .56) / .2).clamp(0, 1),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final paths = [
      [
        const Offset(.45, .03),
        const Offset(.39, .25),
        const Offset(.52, .39),
        const Offset(.42, .62),
        const Offset(.55, .98),
      ],
      [const Offset(.4, .25), const Offset(.16, .35), const Offset(.05, .55)],
      [const Offset(.52, .39), const Offset(.77, .29), const Offset(.93, .4)],
      [const Offset(.42, .62), const Offset(.22, .72), const Offset(.14, .91)],
    ];
    for (final points in paths) {
      if (progress < .6 + paths.indexOf(points) * .025) continue;
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SummonCrackPainter oldDelegate) => true;
}

class _SummonAura extends StatelessWidget {
  const _SummonAura({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250 + progress * 28,
      height: 330 + progress * 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(120),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000)
                .withValues(alpha: .25 + progress * .2),
            blurRadius: 42,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _SummonResultPanel extends StatelessWidget {
  const _SummonResultPanel({required this.character});

  final Item character;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          character.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.orange, blurRadius: 14)],
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Tekan karakter untuk melihat detail',
          style: TextStyle(
            color: Color(0xFFFFD180),
            fontSize: 12,
            letterSpacing: .3,
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.controller,
    required this.selectedGender,
    required this.selectedRace,
    required this.selectedAffiliation,
    required this.minimumKi,
    required this.maximumKi,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onGenderChanged,
    required this.onRaceChanged,
    required this.onAffiliationChanged,
    required this.onKiFilterTap,
    required this.onReset,
  });

  final TextEditingController controller;
  final Gender? selectedGender;
  final Race? selectedRace;
  final Affiliation? selectedAffiliation;
  final double? minimumKi;
  final double? maximumKi;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<Race?> onRaceChanged;
  final ValueChanged<Affiliation?> onAffiliationChanged;
  final VoidCallback onKiFilterTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari nama karakter...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ResetButton(enabled: hasActiveFilters, onPressed: onReset),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                icon: Icons.people_alt_outlined,
                label: selectedGender == null
                    ? 'Gender'
                    : genderLabel(selectedGender!),
                selected: selectedGender == null,
                onPressed: () => _showGenderMenu(context),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                icon: Icons.category_outlined,
                label: selectedRace == null ? 'Ras' : raceLabel(selectedRace!),
                selected: selectedRace != null,
                onPressed: () => _showRaceMenu(context),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                icon: Icons.bolt,
                label: _kiLabel,
                selected: minimumKi != null || maximumKi != null,
                onPressed: onKiFilterTap,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                icon: Icons.groups_outlined,
                label: selectedAffiliation == null
                    ? 'Affiliation'
                    : affiliationLabel(selectedAffiliation!),
                selected: selectedAffiliation != null,
                onPressed: () => _showAffiliationMenu(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _kiLabel {
    if (minimumKi == null && maximumKi == null) return 'Ki';
    final minimum = minimumKi == null ? '0' : _formatNumber(minimumKi!);
    final maximum = maximumKi == null ? '∞' : _formatNumber(maximumKi!);
    return 'Ki $minimum–$maximum';
  }

  Future<void> _showGenderMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<_GenderChoice>(
      context: context,
      builder: (context) => _ChoiceSheet<_GenderChoice>(
        title: 'Filter gender',
        icon: Icons.people_alt_outlined,
        options: const [
          _ChoiceOption(value: _GenderChoice.all, label: 'Semua gender'),
          _ChoiceOption(value: _GenderChoice(Gender.MALE), label: 'Male'),
          _ChoiceOption(value: _GenderChoice(Gender.FEMALE), label: 'Female'),
        ],
        selected: _GenderChoice(selectedGender),
      ),
    );
    if (selected != null) {
      onGenderChanged(selected.gender);
    }
  }

  Future<void> _showRaceMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<_RaceChoice>(
      context: context,
      builder: (context) => _ChoiceSheet<_RaceChoice>(
        title: 'Filter ras',
        icon: Icons.category_outlined,
        options: [
          const _ChoiceOption(value: _RaceChoice.all, label: 'Semua ras'),
          ...Race.values
              .where((race) => race != Race.UNKNOWN)
              .map(
                (race) => _ChoiceOption(
                  value: _RaceChoice(race),
                  label: raceLabel(race),
                ),
              ),
        ],
        selected: selectedRace == null
            ? _RaceChoice.all
            : _RaceChoice(selectedRace),
      ),
    );
    if (selected != null) {
      onRaceChanged(selected.race);
    }
  }

  Future<void> _showAffiliationMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<_AffiliationChoice>(
      context: context,
      builder: (context) => _ChoiceSheet<_AffiliationChoice>(
        title: 'Filter affiliation',
        icon: Icons.groups_outlined,
        options: [
          const _ChoiceOption(
            value: _AffiliationChoice.all,
            label: 'Semua affiliation',
          ),
          ...Affiliation.values
              .where((affiliation) => affiliation != Affiliation.UNKNOWN)
              .map(
                (affiliation) => _ChoiceOption(
                  value: _AffiliationChoice(affiliation),
                  label: affiliationLabel(affiliation),
                ),
              ),
        ],
        selected: selectedAffiliation == null
            ? _AffiliationChoice.all
            : _AffiliationChoice(selectedAffiliation),
      ),
    );
    if (selected != null) {
      onAffiliationChanged(selected.affiliation);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      label: Text(label, overflow: TextOverflow.ellipsis),
      selected: selected,
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      checkmarkColor: colors.onPrimary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      side: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
      onSelected: (_) => onPressed(),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: 'Reset filter',
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.onSurfaceVariant.withValues(
          alpha: 0.35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.restart_alt_rounded),
          if (enabled)
            Positioned(
              right: -4,
              top: -4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceOption<T> {
  const _ChoiceOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _GenderChoice {
  const _GenderChoice(this.gender);

  static const all = _GenderChoice(null);

  final Gender? gender;

  @override
  bool operator ==(Object other) =>
      other is _GenderChoice && other.gender == gender;

  @override
  int get hashCode => gender.hashCode;
}

class _RaceChoice {
  const _RaceChoice(this.race);

  static const all = _RaceChoice(null);

  final Race? race;

  @override
  bool operator ==(Object other) => other is _RaceChoice && other.race == race;

  @override
  int get hashCode => race.hashCode;
}

class _AffiliationChoice {
  const _AffiliationChoice(this.affiliation);

  static const all = _AffiliationChoice(null);

  final Affiliation? affiliation;

  @override
  bool operator ==(Object other) =>
      other is _AffiliationChoice && other.affiliation == affiliation;

  @override
  int get hashCode => affiliation.hashCode;
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
  });

  final String title;
  final IconData icon;
  final List<_ChoiceOption<T>> options;
  final T selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            ...options.map(
              (option) => RadioListTile<T>(
                value: option.value,
                groupValue: selected,
                title: Text(option.label),
                onChanged: (value) => Navigator.pop(context, value),
                contentPadding: EdgeInsets.zero,
                activeColor: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.total,
    required this.shown,
    required this.isFavoriteTab,
  });

  final int total;
  final int shown;
  final bool isFavoriteTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          isFavoriteTab
              ? '$shown karakter yang ditambah ke favorite'
              : '$shown karakter ditampilkan',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          'dari $total',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.isFavorite,
    required this.onFavorite,
  });

  final Item character;
  final VoidCallback onTap;
  final bool isFavorite;
  final void Function(BuildContext context) onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CharacterCardVisual(
      character: character,
      onTap: onTap,
      isFavorite: isFavorite,
      onFavorite: onFavorite,
    );

    // ignore: dead_code
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: theme.colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _CharacterImage(url: character.image),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: Builder(
                      builder: (heartContext) => IconButton(
                        tooltip: isFavorite
                            ? 'Hapus dari favorite'
                            : 'Tambah ke favorite',
                        onPressed: () => onFavorite(heartContext),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorite),
                            color: isFavorite
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          character.gender == Gender.FEMALE
                              ? Icons.female
                              : Icons.male,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${genderLabel(character.gender)} • ${raceLabel(character.race)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Ki: ${character.ki}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      affiliationLabel(character.affiliation),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCardVisual extends StatefulWidget {
  const _CharacterCardVisual({
    required this.character,
    required this.onTap,
    required this.isFavorite,
    required this.onFavorite,
  });

  final Item character;
  final VoidCallback onTap;
  final bool isFavorite;
  final void Function(BuildContext context) onFavorite;

  @override
  State<_CharacterCardVisual> createState() => _CharacterCardVisualState();
}

class _CharacterCardVisualState extends State<_CharacterCardVisual> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final normalBackground = isDark
        ? const [Color(0xFF11161D), Color(0xFF202832)]
        : const [Color(0xFFFFFFFF), Color(0xFFE8EDF4)];
    final activeBackground = isDark
        ? [
            colors.primary.withValues(alpha: .26),
            const Color(0xFF321B25),
            const Color(0xFF171C28),
          ]
        : [
            colors.primary.withValues(alpha: .22),
            const Color(0xFFFFE5D4),
            const Color(0xFFF5F8FF),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _active ? activeBackground : normalBackground,
            ),
            border: Border.all(
              color: _active
                  ? colors.primary.withValues(alpha: .85)
                  : colors.onSurface.withValues(alpha: .08),
              width: _active ? 1.4 : 1,
            ),
            boxShadow: [
              if (_active)
                BoxShadow(
                  color: colors.primary.withValues(alpha: .34),
                  blurRadius: 20,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .28 : .12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          (_active ? colors.primary : const Color(0xFFFF8A00))
                              .withValues(alpha: _active ? .28 : .14),
                          Colors.transparent,
                        ],
                        stops: const [.0, .52],
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: colors.primary.withValues(alpha: .12),
                  highlightColor: Colors.transparent,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AnimatedScale(
                            scale: _active ? 1.045 : 1,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: _CharacterImage(url: widget.character.image),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Column(
                          children: [
                            Text(
                              widget.character.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              raceLabel(widget.character.race),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _active
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: colors.surface.withValues(alpha: .9),
                  shape: const CircleBorder(),
                  child: Builder(
                    builder: (heartContext) => IconButton(
                      tooltip: widget.isFavorite
                          ? 'Hapus dari favorite'
                          : 'Tambah ke favorite',
                      onPressed: () => widget.onFavorite(heartContext),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(widget.isFavorite),
                          color: widget.isFavorite
                              ? Colors.red
                              : colors.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterImage extends StatelessWidget {
  const _CharacterImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = url.isEmpty ? null : NetworkImage(url);

    return Ink(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.transparent,
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.contain),
      ),
      child: image == null
          ? Center(
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 58,
              ),
            )
          : null,
    );
  }
}

class _FilterLoadingOverlay extends StatelessWidget {
  const _FilterLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: ColoredBox(
        color: colors.scrim.withValues(alpha: 0.48),
        child: Center(
          child: Card(
            color: colors.surface,
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    _DragonballPageState._lottieAnimationUrl,
                    height: 90,
                    repeat: true,
                  ),
                  Text(
                    'Memuat...',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              _DragonballPageState._lottieAnimationUrl,
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Karakter tidak ditemukan',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci atau filter gender.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavoriteResult extends StatelessWidget {
  const _EmptyFavoriteResult();

  static const _animationUrl =
      'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/B.json';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(_animationUrl, height: 150, repeat: true),
            const SizedBox(height: 12),
            Text(
              'Favorite kamu masih kosong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tekan ikon hati pada karakter untuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              _DragonballPageState._lottieAnimationUrl,
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.network(
        _DragonballPageState._lottieAnimationUrl,
        height: 180,
        repeat: true,
      ),
    );
  }
}

class _KiRange {
  const _KiRange({this.minimum, this.maximum});

  final double? minimum;
  final double? maximum;
}

double? _parseInputNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String _formatNumber(double value) {
  if (value.isInfinite) return '∞';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

double? kiToNumber(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(',', '');
  final numberMatch = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
  if (numberMatch == null) return null;

  final number = double.tryParse(numberMatch.group(0)!);
  if (number == null) return null;
  if (normalized.contains('infinite')) return double.infinity;

  const multipliers = <String, double>{
    'thousand': 1e3,
    'million': 1e6,
    'billion': 1e9,
    'trillion': 1e12,
    'quadrillion': 1e15,
    'quintillion': 1e18,
    'sextillion': 1e21,
    'septillion': 1e24,
    'octillion': 1e27,
    'nonillion': 1e30,
    'decillion': 1e33,
  };

  for (final entry in multipliers.entries) {
    if (normalized.contains(entry.key)) return number * entry.value;
  }
  return number;
}

String raceLabel(Race value) => switch (value) {
  Race.ANDROID => 'Android',
  Race.FRIEZA_RACE => 'Frieza Race',
  Race.HUMAN => 'Human',
  Race.NAMEKIAN => 'Namekian',
  Race.SAIYAN => 'Saiyan',
  Race.UNKNOWN => 'Unknown',
};

String genderLabel(Gender value) => switch (value) {
  Gender.FEMALE => 'Female',
  Gender.MALE => 'Male',
  Gender.UNKNOWN => 'Unknown',
};

String affiliationLabel(Affiliation value) => switch (value) {
  Affiliation.ARMY_OF_FRIEZA => 'Army of Frieza',
  Affiliation.FREELANCER => 'Freelancer',
  Affiliation.OTHER => 'Other',
  Affiliation.VILLAIN => 'Villain',
  Affiliation.Z_FIGHTER => 'Z Fighter',
  Affiliation.UNKNOWN => 'Unknown',
};
