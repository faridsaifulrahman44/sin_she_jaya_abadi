import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/auth/admin_session.dart';
import '../core/theme/app_theme.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  static const routeName = '/akun';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _AkunPageContent(),
    );
  }
}

class _AkunPageContent extends StatefulWidget {
  const _AkunPageContent();

  @override
  State<_AkunPageContent> createState() => _AkunPageContentState();
}

class _AkunPageContentState extends State<_AkunPageContent> {
  AdminRole? _role;
  String? _namaAdmin;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final idAdmin = await AdminSession.getCurrentId();
      final role = await AdminSession.getRole();
      // Nama admin belum di-cache — kita bisa fetch langsung dari Supabase
      // tapi untuk saat ini tampilkan "Admin" + id
      if (mounted) {
        setState(() {
          _role = role;
          _namaAdmin = 'Admin #$idAdmin';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _namaAdmin = 'Pengguna';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = ctextPrimary(context);
    final textMuted = ctextMuted(context);
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final primary = cprimary(context);

    final role = _role ?? AdminRole.unknown;
    final namaAdmin = _namaAdmin ?? 'Memuat...';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        // Avatar + Nama
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                namaAdmin,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: role.isOwner
                      ? primary.withValues(alpha: 0.1)
                      : cwarning(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  role.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: role.isOwner ? primary : cwarning(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Pengaturan section
        _SectionHeader(title: 'Pengaturan'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: Column(
            children: [
              // Dark Mode
              _SettingsTile(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                title: 'Mode Gelap',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => ThemeServiceInstance.notifier.toggle(),
                  activeTrackColor: primary,
                ),
              ),
              Divider(height: 1, color: dividerColor, indent: 56),
              // Notifikasi (placeholder)
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                trailing: Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
                onTap: () {
                  showModernSnackBar(
                    context,
                    'Fitur notifikasi belum tersedia',
                  );
                },
              ),
              Divider(height: 1, color: dividerColor, indent: 56),
              // Printer (placeholder)
              _SettingsTile(
                icon: Icons.print_outlined,
                title: 'Pengaturan Printer',
                trailing: Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
                onTap: () {
                  showModernSnackBar(
                    context,
                    'Pengaturan printer belum tersedia',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Info section
        _SectionHeader(title: 'Info'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            trailing: Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
            onTap: () {
              showModernSnackBar(
                context,
                'SinShe Jaya Abadi v1.0.0',
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Danger zone
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: _SettingsTile(
            icon: Icons.logout,
            iconColor: cdanger(context),
            titleColor: cdanger(context),
            title: 'Logout',
            trailing: const SizedBox.shrink(),
            onTap: () => _handleLogout(context),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'SinShe Jaya Abadi v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Logout',
      isDanger: true,
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!context.mounted) return;
      showModernSnackBar(context, 'Gagal logout', isError: true);
      return;
    }
    AdminSession.clearCache();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ctextSecondary(context),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = titleColor ?? ctextPrimary(context);
    final iconClr = iconColor ?? ctextSecondary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconClr, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}