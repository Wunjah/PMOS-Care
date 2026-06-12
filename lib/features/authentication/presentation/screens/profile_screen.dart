import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kMutedText = Color(0xFF777684);
const _kBg = Color(0xFFF8F9FF);
const _kDivider = Color(0xFFE7E8EE);
const _kError = Color(0xFFEB505E);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateNotifierProvider);
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.displayName;
      _emailController.text = authState.user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _isUploading = true);
      final url = await ref.read(authStateNotifierProvider.notifier).uploadProfilePhoto(picked.path);
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(url != null ? 'Photo updated!' : 'Photo upload failed'),
          backgroundColor: url != null ? Colors.green : _kError,
        ));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _kError));
      }
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(authStateNotifierProvider.notifier).updateDisplayName(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Email', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'New Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text('A verification link will be sent to your new email.',
                style: TextStyle(fontSize: 12, color: _kMutedText)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateNotifierProvider.notifier).updateEmail(
                _emailController.text.trim(), _passwordController.text,
              );
              _passwordController.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification link sent to new email.'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: _kError)),
        content: const Text(
          'This is permanent and cannot be undone. All your health records, cycles, and meal logs will be deleted.',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kError),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateNotifierProvider.notifier).deleteAccount();
              if (mounted) context.go('/login');
            },
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (_, next) {
      if (next is AuthUnauthenticated && mounted) {
        context.go('/login');
      }
    });

    final authState = ref.watch(authStateNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 80, bottom: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(user),
                  const SizedBox(height: 28),

                  // Personal Info
                  _sectionLabel('PERSONAL INFO'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildEditRow(
                      controller: _nameController,
                      label: 'Display Name',
                      icon: Icons.person_outline,
                      onSave: _saveName,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Settings
                  _sectionLabel('SETTINGS'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _ToggleTile(
                      icon: Icons.fingerprint,
                      title: 'Biometric Lock',
                      subtitle: 'Require fingerprint/face to open',
                      value: user?.biometricLockEnabled ?? false,
                      onChanged: (v) {
                        ref.read(authStateNotifierProvider.notifier).updateSettings(
                          biometricLockEnabled: v,
                          notificationsEnabled: user?.notificationsEnabled ?? true,
                        );
                      },
                    ),
                    const Divider(height: 0, indent: 52, endIndent: 16, color: _kDivider),
                    _ToggleTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Reminders for meds and appointments',
                      value: user?.notificationsEnabled ?? true,
                      onChanged: (v) {
                        ref.read(authStateNotifierProvider.notifier).updateSettings(
                          biometricLockEnabled: user?.biometricLockEnabled ?? false,
                          notificationsEnabled: v,
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // App & Learning
                  _sectionLabel('APP'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildNavTile(
                      icon: Icons.menu_book_outlined,
                      iconColor: const Color(0xFF00696A),
                      title: 'Learning Center',
                      subtitle: 'Articles, videos & PMOS education',
                      onTap: () => context.push('/education'),
                    ),
                    const Divider(height: 0, indent: 52, endIndent: 16, color: _kDivider),
                    _buildNavTile(
                      icon: Icons.link_outlined,
                      iconColor: Colors.orange,
                      title: 'Connected Apps',
                      subtitle: 'Google Fit, Apple Health & more',
                      onTap: () => context.push('/connected-apps'),
                    ),
                    const Divider(height: 0, indent: 52, endIndent: 16, color: _kDivider),
                    _buildNavTile(
                      icon: Icons.event_note_outlined,
                      iconColor: _kPrimary,
                      title: 'My Appointments',
                      subtitle: 'View and manage bookings',
                      onTap: () => context.push('/appointments'),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Account
                  _sectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildNavTile(
                      icon: Icons.email_outlined,
                      title: 'Change Email',
                      subtitle: user?.email ?? 'No email set',
                      onTap: _showChangeEmailDialog,
                    ),
                    const Divider(height: 0, indent: 52, endIndent: 16, color: _kDivider),
                    _buildNavTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      onTap: () => ref.read(authStateNotifierProvider.notifier).logout(),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Danger Zone
                  _sectionLabel('DANGER ZONE', danger: true),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildNavTile(
                      icon: Icons.delete_forever_outlined,
                      iconColor: _kError,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove all data',
                      titleColor: _kError,
                      onTap: _showDeleteDialog,
                    ),
                  ], danger: true),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.only(left: 4, right: 20, top: 40, bottom: 12),
            decoration: const BoxDecoration(
              color: Color(0xCCF8F9FF),
              border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kDarkText),
                  onPressed: () => context.pop(),
                ),
                const Text('My Profile',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: _kDarkText)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : user?.photoUrl != null
                        ? ClipOval(child: Image.network(user!.photoUrl!, fit: BoxFit.cover, width: 96, height: 96))
                        : Center(
                            child: Text(
                              (user?.displayName.isNotEmpty == true) ? user!.displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: _kPrimary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: _kPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user?.displayName ?? 'User',
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: _kDarkText)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              user?.isDoctor == true ? 'Healthcare Provider' : 'Patient',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {bool danger = false}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: danger ? _kError : _kMutedText,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {bool danger = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger ? _kError.withOpacity(0.2) : _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText)),
                TextField(
                  controller: controller,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: _kDarkText, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? _kPrimary),
      title: Text(title,
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? _kDarkText)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
      trailing: const Icon(Icons.chevron_right, color: _kMutedText, size: 18),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: _kDarkText)),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _kPrimary,
          ),
        ],
      ),
    );
  }
}
