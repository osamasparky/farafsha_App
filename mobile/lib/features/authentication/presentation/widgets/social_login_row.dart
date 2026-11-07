import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SocialLoginRow extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String message)? onError;

  const SocialLoginRow({
    super.key,
    this.onSuccess,
    this.onError,
  });

  @override
  State<SocialLoginRow> createState() => _SocialLoginRowState();
}

class _SocialLoginRowState extends State<SocialLoginRow> {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();
  String? _activeProviderLoading;

  Future<void> _handleProviderLogin(String provider) async {
    if (_activeProviderLoading != null) return;

    setState(() => _activeProviderLoading = provider);

    try {
      final result = await _authRepo.signInWithSocial(provider);

      if (!mounted) return;
      setState(() => _activeProviderLoading = null);

      if (result.success) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          context.go('/home');
        }
      } else if (!result.isCancelled) {
        final err = result.message ?? 'فشل تسجيل الدخول بواسطة $provider.';
        if (widget.onError != null) {
          widget.onError!(err);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err, style: const TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFFD2566A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _activeProviderLoading = null);
      final msg = 'حدث خطأ: ${e.toString().replaceAll('Exception:', '').trim()}';
      if (widget.onError != null) {
        widget.onError!(msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFD2566A),
          ),
        );
      }
    }
  }

  Widget _buildSocialIconBtn({
    required String providerKey,
    required Widget icon,
    required Color bgColor,
    required Color borderColor,
    Color? glowColor,
  }) {
    final isLoading = _activeProviderLoading == providerKey;

    return GestureDetector(
      onTap: () => _handleProviderLogin(providerKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: (glowColor ?? borderColor).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google
        _buildSocialIconBtn(
          providerKey: 'google',
          bgColor: Colors.white,
          borderColor: const Color(0xFFDADCE0),
          glowColor: const Color(0xFF4285F4),
          icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 36),
        ),
        const SizedBox(width: 14),

        // Apple
        _buildSocialIconBtn(
          providerKey: 'apple',
          bgColor: const Color(0xFF000000),
          borderColor: const Color(0xFF333333),
          glowColor: Colors.white24,
          icon: const Icon(Icons.apple_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),

        // Facebook
        _buildSocialIconBtn(
          providerKey: 'facebook',
          bgColor: const Color(0xFF1877F2),
          borderColor: const Color(0xFF2E89FF),
          glowColor: const Color(0xFF1877F2),
          icon: const Icon(Icons.facebook_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),

        // X (Twitter)
        _buildSocialIconBtn(
          providerKey: 'twitter',
          bgColor: const Color(0xFF14171A),
          borderColor: const Color(0xFF2C3238),
          glowColor: const Color(0xFF1DA1F2),
          icon: const Text(
            '𝕏',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 14),

        // LinkedIn
        _buildSocialIconBtn(
          providerKey: 'linkedin',
          bgColor: const Color(0xFF0A66C2),
          borderColor: const Color(0xFF1B82E8),
          glowColor: const Color(0xFF0A66C2),
          icon: const Text(
            'in',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Arial'),
          ),
        ),
      ],
    );
  }
}
