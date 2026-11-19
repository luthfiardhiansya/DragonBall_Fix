import 'package:flutter/material.dart';

import '../models/dragonball.dart';

class DragonballDetailPage extends StatelessWidget {
  const DragonballDetailPage({super.key, required this.character});

  final Item character;

  String get _heroTag => 'dragonball-character-${character.id}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Character Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
        child: Column(
          children: [
            SizedBox(
              height: 430,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, .25),
                            radius: .8,
                            colors: [
                              colors.primary.withValues(alpha: .20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 8,
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: .22),
                            blurRadius: 42,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Hero(
                      tag: _heroTag,
                      child: _DetailArtwork(url: character.image),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -46),
              child: _CharacterInformationCard(character: character),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailArtwork extends StatelessWidget {
  const _DetailArtwork({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (url.isEmpty) {
      return Center(
        child: Icon(Icons.person_outline, size: 100, color: colors.primary),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 72,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _CharacterInformationCard extends StatelessWidget {
  const _CharacterInformationCard({required this.character});

  final Item character;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primary.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              character.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.category_outlined,
                  label: 'RACE',
                  value: _raceLabel(character.race),
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: Icons.bolt_rounded,
                  label: 'KI',
                  value: character.ki,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: Icons.auto_awesome_rounded,
                  label: 'MAX KI',
                  value: character.maxKi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _DetailSectionTitle(
            icon: Icons.menu_book_outlined,
            title: 'Origin Story',
          ),
          const SizedBox(height: 8),
          Text(
            character.description,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.55,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          const _DetailSectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'Character Data',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: .035),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _DetailInfoRow(
                  label: 'Gender',
                  value: _genderLabel(character.gender),
                ),
                _DetailInfoRow(
                  label: 'Affiliation',
                  value: _affiliationLabel(character.affiliation),
                ),
                _DetailInfoRow(
                  label: 'Character ID',
                  value: '#${character.id}',
                ),
                _DetailInfoRow(
                  label: 'Data status',
                  value: character.deletedAt == null ? 'Active' : 'Archived',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _raceLabel(Race value) => switch (value) {
  Race.ANDROID => 'Android',
  Race.FRIEZA_RACE => 'Frieza Race',
  Race.HUMAN => 'Human',
  Race.NAMEKIAN => 'Namekian',
  Race.SAIYAN => 'Saiyan',
  Race.UNKNOWN => 'Unknown',
};

String _genderLabel(Gender value) => switch (value) {
  Gender.FEMALE => 'Female',
  Gender.MALE => 'Male',
  Gender.UNKNOWN => 'Unknown',
};

String _affiliationLabel(Affiliation value) => switch (value) {
  Affiliation.ARMY_OF_FRIEZA => 'Army of Frieza',
  Affiliation.FREELANCER => 'Freelancer',
  Affiliation.OTHER => 'Other',
  Affiliation.VILLAIN => 'Villain',
  Affiliation.Z_FIGHTER => 'Z Fighter',
  Affiliation.UNKNOWN => 'Unknown',
};
