import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _classController;
  String? _photoPath;
  Uint8List? _photoBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = appProfile.value;
    _nameController = TextEditingController(text: profile.name);
    _classController = TextEditingController(text: profile.className);
    _photoPath = profile.photoPath;
    _photoBytes = profile.photoBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1000,
      );
      if (!mounted || image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoPath = image.path;
        _photoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto tidak dapat dibaca.')));
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final className = _classController.text.trim();
    if (name.isEmpty || className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan kelas wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    appProfile.value = UserProfile(
      name: name,
      className: className,
      photoPath: _photoPath,
      photoBytes: _photoBytes,
    );
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile Saya',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: .25),
                    colors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: colors.primary.withValues(alpha: .25),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ProfileAvatar(bytes: _photoBytes, radius: 58),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: IconButton.filled(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.camera_alt_rounded, size: 19),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    'PERSONAL PROFILE',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur identitas kamu di aplikasi',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _ProfileField(
              controller: _nameController,
              label: 'Nama lengkap',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _ProfileField(
              controller: _classController,
              label: 'Kelas',
              icon: Icons.school_outlined,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'MENYIMPAN...' : 'SIMPAN PROFILE'),
                style: FilledButton.styleFrom(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
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
    );
  }
}

class ProfileAppBarButton extends StatelessWidget {
  const ProfileAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile>(
      valueListenable: appProfile,
      builder: (context, profile, _) {
        return IconButton(
          tooltip: 'Buka profile',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          padding: EdgeInsets.zero,
          icon: _ProfileAvatar(bytes: profile.photoBytes, radius: 16),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.bytes, required this.radius});

  final Uint8List? bytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canShowBytes = bytes != null && bytes!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary.withValues(alpha: .18),
      child: canShowBytes
          ? ClipOval(
              child: SizedBox.square(
                dimension: radius * 2,
                child: Image.memory(
                  bytes!,
                  key: ValueKey(bytes),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _fallbackIcon(colors),
                ),
              ),
            )
          : _fallbackIcon(colors),
    );
  }

  Widget _fallbackIcon(ColorScheme colors) =>
      Icon(Icons.person_rounded, size: radius * 1.08, color: colors.primary);
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.textCapitalization,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
