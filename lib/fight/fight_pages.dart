import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../models/dragonball.dart';
import '../routes/app_routes.dart';
import 'fight_controller.dart';

const _kidBuuAsset = 'assets/fight/kid-buu.png';
const _arenaAsset = 'assets/fight/map.png';
const _combatAsset = 'assets/fight/berantem.png';
const _loadingAsset = 'assets/animations/loading.json';

Future<void> _lockPortrait() =>
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

class FightIntroPage extends StatefulWidget {
  const FightIntroPage({super.key, required this.characters});

  final List<Item> characters;

  @override
  State<FightIntroPage> createState() => _FightIntroPageState();
}

class _FightIntroPageState extends State<FightIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    unawaited(_lockPortrait());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterSelectionPage(characters: widget.characters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF080A12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_arenaAsset, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xCC070914),
                  const Color(0x66070914),
                  const Color(0xF2070914),
                ],
                stops: const [0, .42, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FightTopBar(
                    title: 'FIGHT MODE',
                    onBack: () => Navigator.pop(context),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    'BOSS INTRODUCTION',
                    style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'YOUR NEXT OPPONENT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 1.7,
                    ),
                  ),
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 7,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final glow = .18 + _pulseController.value * .16;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 240 + _pulseController.value * 16,
                              height: 240 + _pulseController.value * 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4F9A)
                                        .withValues(alpha: glow),
                                    blurRadius: 70,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            child!,
                          ],
                        );
                      },
                      child: Image.asset(
                        _kidBuuAsset,
                        fit: BoxFit.contain,
                        width: 255,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Center(
                    child: Text(
                      'KID-BUU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFF4F9A)
                                .withValues(alpha: .8),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text(
                      'FINAL BOSS  •  PURE CHAOS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PowerBar(
                    label: 'KI POWER',
                    value: kidBuuKiLabel,
                    progress: 1,
                    color: const Color(0xFFFF4F9A),
                  ),
                  const Spacer(flex: 1),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: _startSelection,
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('FIGHT'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3D83),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key, required this.characters});

  final List<Item> characters;

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  late final List<Item> _characters;
  var _selectedIndex = 0;
  var _isConfirmed = false;

  Item get _selected => _characters[_selectedIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_lockPortrait());
    _characters = List<Item>.from(widget.characters)
      ..sort((a, b) => a.id.compareTo(b.id));
    if (_characters.isEmpty) _characters.add(_fallbackCharacter);
  }

  static final _fallbackCharacter = Item(
    id: 0,
    name: 'Unknown Warrior',
    ki: '0',
    maxKi: '0',
    race: Race.UNKNOWN,
    gender: Gender.UNKNOWN,
    description: '',
    image: '',
    affiliation: Affiliation.UNKNOWN,
    deletedAt: null,
  );

  void _move(int delta) {
    setState(() {
      _selectedIndex = (_selectedIndex + delta) % _characters.length;
      if (_selectedIndex < 0) _selectedIndex = _characters.length - 1;
      _isConfirmed = false;
    });
  }

  void _confirm() {
    setState(() => _isConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selected.name} siap bertarung.'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _showAllCharacters() async {
    final selected = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => _AllCharactersOverlay(
        characters: _characters,
        selectedId: _selected.id,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedIndex = _characters.indexWhere((item) => item.id == selected.id);
      _isConfirmed = false;
    });
  }

  void _readyFight() {
    if (!_isConfirmed) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FightLoadingPage(player: _selected, characters: _characters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final previous =
        _characters[(_selectedIndex - 1 + _characters.length) %
            _characters.length];
    final next = _characters[(_selectedIndex + 1) % _characters.length];
    final power = FightResultCalculator.parseKi(_selected.ki);
    final progress = (power / kidBuuKi).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF080A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080A12),
        foregroundColor: Colors.white,
        title: const Text(
          'CHOOSE CHARACTER',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAllCharacters,
            icon: const Icon(Icons.grid_view_rounded, size: 17),
            label: const Text('LIHAT SEMUA'),
            style: TextButton.styleFrom(foregroundColor: colors.secondary),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 80) return;
            _move(velocity < 0 ? 1 : -1);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallLabel(text: 'PLAYER 1', color: colors.secondary),
                    Text(
                      'SWIPE / DOUBLE TAP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .42),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -32,
                      child: _SideCharacter(character: previous, flipped: true),
                    ),
                    Positioned(
                      right: -32,
                      child: _SideCharacter(character: next),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                colors.primary.withValues(alpha: .2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 74,
                      right: 74,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: .42),
                              blurRadius: 34,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isConfirmed = false),
                      onDoubleTap: _confirm,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutBack,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: _CenterCharacter(
                          key: ValueKey(_selected.id),
                          character: _selected,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      child: _ArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => _move(-1),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      child: _ArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: () => _move(1),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Column(
                  children: [
                    Text(
                      _selected.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _PowerBar(
                      label: 'KI POWER',
                      value: FightResultCalculator.formatKi(power),
                      progress: progress,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _isConfirmed ? 'CHARACTER LOCKED' : 'Tap sekali untuk memilih • double tap untuk mengunci',
                      style: TextStyle(
                        color: _isConfirmed
                            ? const Color(0xFF62E6A5)
                            : Colors.white.withValues(alpha: .56),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isConfirmed ? _readyFight : null,
                        icon: const Icon(Icons.sports_mma_rounded),
                        label: const Text('READY FIGHT'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A3D),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white30,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FightLoadingPage extends StatefulWidget {
  const FightLoadingPage({
    super.key,
    required this.player,
    required this.characters,
  });

  final Item player;
  final List<Item> characters;

  @override
  State<FightLoadingPage> createState() => _FightLoadingPageState();
}

class _FightLoadingPageState extends State<FightLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    unawaited(_lockPortrait());
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    unawaited(
      _progress.animateTo(
        .82,
        duration: const Duration(seconds: 4),
        curve: Curves.easeInOut,
      ),
    );
    unawaited(_prepareArena());
  }

  Future<void> _prepareArena() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final pageContext = context;

    await Future.wait<void>([
      _precacheAsset(_arenaAsset, pageContext),
      _precacheAsset(_kidBuuAsset, pageContext),
      _precacheAsset(_combatAsset, pageContext),
      if (widget.player.image.isNotEmpty) _precachePlayer(pageContext),
    ]);
    if (!mounted) return;
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BattleArenaPage(
          player: widget.player,
          characters: widget.characters,
        ),
      ),
    );
  }

  Future<void> _precacheAsset(String asset, BuildContext pageContext) async {
    if (!mounted) return;
    try {
      await precacheImage(
        AssetImage(asset),
        pageContext,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // A local asset failure must not leave the fight flow on the loading page.
    }
  }

  Future<void> _precachePlayer(BuildContext pageContext) async {
    if (!mounted) return;
    try {
      await precacheImage(
        NetworkImage(widget.player.image),
        pageContext,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // The arena still works with the fallback artwork if the API image fails.
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070912),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SETTING UP A FIGHT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.player.name.toUpperCase()}  VS  KID-BUU',
                    style: const TextStyle(
                      color: Color(0xFFFF8A3D),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Lottie.asset(_loadingAsset, height: 150, repeat: true),
                  const SizedBox(height: 28),
                  LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFF8A3D),
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _progress.value < .8
                        ? 'LOADING ARENA • PREPARING AURA'
                        : 'READY TO BATTLE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
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

class BattleArenaPage extends StatefulWidget {
  const BattleArenaPage({
    super.key,
    required this.player,
    required this.characters,
  });

  final Item player;
  final List<Item> characters;

  @override
  State<BattleArenaPage> createState() => _BattleArenaPageState();
}

class _BattleArenaPageState extends State<BattleArenaPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _battleController;
  final _sounds = <AudioPlayer>[];
  final _soundTimers = <Timer>[];
  var _resultOpened = false;

  @override
  void initState() {
    super.initState();
    unawaited(_lockPortrait());
    _battleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _openResult();
          });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _battleController.forward();
      _scheduleSounds();
    });
  }

  void _scheduleSounds() {
    _queueSound(const Duration(seconds: 3), 'audio/gacha_flight.wav');
    _queueSound(const Duration(milliseconds: 3800), 'audio/gacha_crack.wav');
    _queueSound(const Duration(seconds: 5), 'audio/gacha_burst.wav');
  }

  void _queueSound(Duration delay, String asset) {
    _soundTimers.add(
      Timer(delay, () {
        if (!mounted) return;
        final player = AudioPlayer();
        _sounds.add(player);
        unawaited(player.play(AssetSource(asset)));
      }),
    );
  }

  void _openResult() {
    if (_resultOpened || !mounted) return;
    _resultOpened = true;
    final result = FightResultCalculator.calculate(widget.player);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BattleResultPage(
          player: widget.player,
          characters: widget.characters,
          result: result,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _battleController.dispose();
    for (final timer in _soundTimers) {
      timer.cancel();
    }
    for (final sound in _sounds) {
      unawaited(sound.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _battleController,
        builder: (context, _) {
          final phase = _battleController.value * 8;
          final meeting = ((phase - 3) / 1.0).clamp(0.0, 1.0);
          final smokeProgress = ((phase - 3.2) / 1.2).clamp(0.0, 1.0);
          final flash = phase >= 3.1
              ? (math.sin((phase - 3.1) * math.pi * 3).abs() * .28)
              : 0.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_arenaAsset, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .52),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _EnergyParticlePainter(
                      progress: _battleController.value,
                      color: colors.primary,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const Align(
                            alignment: Alignment.topCenter,
                            child: _ArenaTitle(),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: _BattleHud(
                              name: 'KID-BUU',
                              ki: kidBuuKiLabel,
                              color: const Color(0xFFFF4F9A),
                              progress: 1,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _BattleHud(
                              name: widget.player.name,
                              ki: FightResultCalculator.formatKi(
                                FightResultCalculator.parseKi(widget.player.ki),
                              ),
                              color: const Color(0xFF5DB8FF),
                              progress:
                                  (FightResultCalculator.parseKi(
                                            widget.player.ki,
                                          ) /
                                          kidBuuKi)
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                              alignRight: true,
                            ),
                          ),
                          Positioned(
                            top: height * .13 + meeting * height * .20,
                            left: width * .62 - meeting * width * .31,
                            width: width * .38,
                            height: height * .30,
                            child: Transform.rotate(
                              angle: meeting * -.08,
                              child: Image.asset(
                                _kidBuuAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: height * .58 - meeting * height * .24,
                            left: -width * .06 + meeting * width * .28,
                            width: width * .56,
                            height: height * .31,
                            child: Transform.flip(
                              flipX: true,
                              child: widget.player.image.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 120,
                                      color: Colors.white.withValues(alpha: .6),
                                    )
                                  : Image.network(
                                      widget.player.image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) =>
                                          Icon(
                                            Icons.person_rounded,
                                            size: 120,
                                            color: Colors.white.withValues(
                                              alpha: .6,
                                            ),
                                          ),
                                    ),
                            ),
                          ),
                          if (smokeProgress > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: smokeProgress,
                                  child: Center(
                                    child: Transform.rotate(
                                      angle: math.sin(phase * 2.7) * .08,
                                      child: Transform.scale(
                                        scale:
                                            .92 +
                                            smokeProgress * .12 +
                                            math.sin(phase * 2.2) * .04,
                                        child: SizedBox(
                                          // The source PNG has transparent
                                          // margins. Oversizing it makes its
                                          // opaque smoke cover both fighters.
                                          height: height * 1.04,
                                          width: height * 1.04 * (480 / 270),
                                          child: Image.asset(
                                            _combatAsset,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.center,
                            child: _PhaseBadge(phase: phase),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: flash),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class BattleResultPage extends StatefulWidget {
  const BattleResultPage({
    super.key,
    required this.player,
    required this.characters,
    required this.result,
  });

  final Item player;
  final List<Item> characters;
  final FightResult result;

  @override
  State<BattleResultPage> createState() => _BattleResultPageState();
}

class _BattleResultPageState extends State<BattleResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    unawaited(_lockPortrait());
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String get _headline => switch (widget.result.outcome) {
    FightOutcome.win => 'YOU WIN',
    FightOutcome.lose => 'YOU LOSE',
    FightOutcome.draw => 'DRAW',
  };

  Color get _accent => switch (widget.result.outcome) {
    FightOutcome.win => const Color(0xFF5CE39D),
    FightOutcome.lose => const Color(0xFFFF5574),
    FightOutcome.draw => const Color(0xFFFFC857),
  };

  void _rematch() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BattleArenaPage(
          player: widget.player,
          characters: widget.characters,
        ),
      ),
    );
  }

  void _changeCharacter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CharacterSelectionPage(characters: widget.characters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDraw = widget.result.outcome == FightOutcome.draw;
    return Scaffold(
      backgroundColor: const Color(0xFF080A12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_arenaAsset, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _accent.withValues(alpha: .12),
                  Colors.black.withValues(alpha: .76),
                  Colors.black.withValues(alpha: .98),
                ],
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) => FadeTransition(
                opacity: _entrance,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .86, end: 1).animate(
                    CurvedAnimation(
                      parent: _entrance,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Column(
                  children: [
                    const _FightTopBar(title: 'BATTLE RESULT'),
                    const Spacer(),
                    if (isDraw)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ResultImage.network(widget.player.image),
                          const SizedBox(width: 14),
                          _ResultImage.asset(_kidBuuAsset),
                        ],
                      )
                    else
                      SizedBox(
                        height: 310,
                        child: _ResultImage.networkOrAsset(
                          useAsset: widget.result.isLose,
                          networkUrl: widget.player.image,
                          asset: _kidBuuAsset,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _headline,
                      style: TextStyle(
                        color: _accent,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [Shadow(color: _accent, blurRadius: 24)],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.result.isWin
                          ? '${widget.player.name} conquered the arena'
                          : widget.result.isLose
                          ? 'KID-BUU remains undefeated'
                          : 'Both warriors have equal Ki',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ResultStats(player: widget.player, result: widget.result),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _rematch,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('REMATCH'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _changeCharacter,
                            child: const Text('CHANGE CHARACTER'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoute.dragonball,
                              (route) => false,
                            ),
                            child: const Text('HOME'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCharactersOverlay extends StatelessWidget {
  const _AllCharactersOverlay({
    required this.characters,
    required this.selectedId,
  });

  final List<Item> characters;
  final int selectedId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LIHAT SEMUA KARAKTER',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: characters.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .72,
                  ),
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final selected = character.id == selectedId;
                    return InkWell(
                      onTap: () => Navigator.pop(context, character),
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primary.withValues(alpha: .18)
                              : colors.onSurface.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: selected ? colors.primary : Colors.white10,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _NetworkArtwork(
                                url: character.image,
                                color: selected ? null : Colors.white,
                                opacity: selected ? 1 : .72,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              character.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterCharacter extends StatelessWidget {
  const _CenterCharacter({super.key, required this.character});

  final Item character;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      height: 360,
      child: _NetworkArtwork(url: character.image, fit: BoxFit.contain),
    );
  }
}

class _SideCharacter extends StatelessWidget {
  const _SideCharacter({required this.character, this.flipped = false});

  final Item character;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: 160,
      height: 270,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          .15,
          0,
          0,
          0,
          0,
          0,
          .15,
          0,
          0,
          0,
          0,
          0,
          .2,
          0,
          0,
          0,
          0,
          0,
          .7,
          0,
        ]),
        child: _NetworkArtwork(url: character.image, fit: BoxFit.contain),
      ),
    );
    return Transform.flip(flipX: flipped, child: image);
  }
}

class _NetworkArtwork extends StatelessWidget {
  const _NetworkArtwork({
    required this.url,
    this.fit = BoxFit.contain,
    this.color,
    this.opacity = 1,
  });

  final String url;
  final BoxFit fit;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Icon(Icons.person_rounded, size: 90, color: Colors.white38);
    }
    return Opacity(
      opacity: opacity,
      child: Image.network(
        url,
        fit: fit,
        color: color,
        colorBlendMode: color == null ? null : BlendMode.modulate,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.person_rounded, size: 90, color: Colors.white38),
      ),
    );
  }
}

class _PowerBar extends StatelessWidget {
  const _PowerBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: color,
            backgroundColor: Colors.white12,
          ),
        ),
      ],
    );
  }
}

class _FightTopBar extends StatelessWidget {
  const _FightTopBar({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        if (onBack != null) const SizedBox(width: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    ),
  );
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: onPressed,
    icon: Icon(icon, size: 30),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: .12),
      foregroundColor: Colors.white,
    ),
  );
}

class _ArenaTitle extends StatelessWidget {
  const _ArenaTitle();

  @override
  Widget build(BuildContext context) => const Text(
    'WORLD MARTIAL ARTS ARENA',
    style: TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    ),
  );
}

class _BattleHud extends StatelessWidget {
  const _BattleHud({
    required this.name,
    required this.ki,
    required this.color,
    required this.progress,
    this.alignRight = false,
  });

  final String name;
  final String ki;
  final Color color;
  final double progress;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 155,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: color,
              backgroundColor: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ki,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    if (phase < 2.2 || phase > 7.8) return const SizedBox.shrink();
    final text = phase < 3
        ? 'GET READY'
        : phase < 3.8
        ? 'CLASH!'
        : 'FIGHT!';
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: .8),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        shadows: const [Shadow(color: Colors.black, blurRadius: 12)],
      ),
    );
  }
}

class _EnergyParticlePainter extends CustomPainter {
  const _EnergyParticlePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .44);
    for (var i = 0; i < 20; i++) {
      final x = (math.sin(i * 17.3) * .5 + .5) * size.width;
      final baseY = (math.cos(i * 9.1) * .5 + .5) * size.height;
      final y = (baseY + progress * size.height * .35) % size.height;
      final radius = 1.2 + (i % 3) * .8;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.player, required this.result});

  final Item player;
  final FightResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(
          name: player.name,
          value: FightResultCalculator.formatKi(result.playerKi),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text('VS', style: TextStyle(color: Colors.white38)),
        ),
        const _Stat(name: 'KID-BUU', value: kidBuuKiLabel),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _ResultImage extends StatelessWidget {
  const _ResultImage.asset(String asset) : url = null, assetPath = asset;
  const _ResultImage.network(String image) : url = image, assetPath = null;

  final String? url;
  final String? assetPath;

  factory _ResultImage.networkOrAsset({
    required bool useAsset,
    required String networkUrl,
    required String asset,
  }) {
    return useAsset
        ? _ResultImage.asset(asset)
        : _ResultImage.network(networkUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(assetPath!, fit: BoxFit.contain);
    }
    if (url == null || url!.isEmpty) {
      return const Icon(Icons.person_rounded, color: Colors.white54, size: 120);
    }
    return Image.network(
      url!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.person_rounded, color: Colors.white54, size: 120),
    );
  }
}
