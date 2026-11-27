import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SocialLoginRow extends StatefulWidget {
  final List<Map<String, dynamic>>? providers;
  final VoidCallback? onSuccess;
  final Function(String message)? onError;

  const SocialLoginRow({
    super.key,
    this.providers,
    this.onSuccess,
    this.onError,
  });

  @override
  State<SocialLoginRow> createState() => _SocialLoginRowState();
}

class _SocialLoginRowState extends State<SocialLoginRow> {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();
  String? _activeProviderLoading;
  List<Map<String, dynamic>> _loadedProviders = [];
  bool _isLoadingProviders = false;

  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="24" height="24">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  static const String _appleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="22" height="22" fill="#ffffff">
  <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.69-3.04-7.59-7.71-11.72-14-6.47-9.87-11.53-21.2-15.18-34-3.66-12.8-5.49-24.97-5.49-36.5 0-16.14 4.35-29.6 13.06-40.38 8.7-10.78 19.38-16.29 32.03-16.53 4.89 0 10.14 1.25 15.75 3.75 5.6 2.5 9.74 3.82 12.41 3.96 2.07-.14 6.32-1.46 12.75-3.96 6.42-2.5 11.83-3.64 16.23-3.41 12.22.68 22.18 5.23 29.89 13.65-10.74 6.5-16.02 15.65-15.82 27.45.2 9.24 3.72 17.06 10.56 23.47 6.84 6.41 14.88 10.15 24.12 11.23-2.07 6.3-4.68 12.87-7.83 19.7zm-29.35-106.6c0 6.64-2.5 12.85-7.5 17.62-5 4.77-11.02 7.72-18.06 7.85-.27-.8-.4-1.68-.4-2.65 0-6.64 2.68-13.1 8.04-18.39 5.36-5.29 11.76-8.23 19.2-8.83.27 1.47.4 2.66.4 4.4z"/>
</svg>
''';

  static const String _facebookSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" fill="#ffffff">
  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>
''';

  static const String _twitterXSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="#ffffff">
  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
</svg>
''';

  static const String _linkedinSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="#ffffff">
  <path d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.88 8.56a1.68 1.68 0 0 0 1.68-1.68c0-.93-.75-1.69-1.68-1.69a1.69 1.69 0 0 0-1.69 1.69c0 .93.76 1.68 1.69 1.68m1.39 9.94v-8.37H5.5v8.37h2.77z"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    if (widget.providers != null) {
      _loadedProviders = widget.providers!.where((p) => p['is_enabled'] == true).toList();
    } else {
      _fetchProviders();
    }
  }

  @override
  void didUpdateWidget(covariant SocialLoginRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.providers != null && widget.providers != oldWidget.providers) {
      setState(() {
        _loadedProviders = widget.providers!.where((p) => p['is_enabled'] == true).toList();
      });
    }
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoadingProviders = true);
    try {
      final list = await ApiService.instance.getSocialProviders();
      if (mounted) {
        setState(() {
          _loadedProviders = list.where((p) => p['is_enabled'] == true).toList();
          _isLoadingProviders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProviders = false);
      }
    }
  }

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
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (glowColor ?? borderColor).withOpacity(0.32),
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
              : SizedBox(
                  width: 22,
                  height: 22,
                  child: FittedBox(fit: BoxFit.contain, child: icon),
                ),
        ),
      ),
    );
  }

  Widget? _buildProviderWidget(String key) {
    switch (key.toLowerCase()) {
      case 'google':
        return _buildSocialIconBtn(
          providerKey: 'google',
          bgColor: Colors.white,
          borderColor: const Color(0xFFE2E4E8),
          glowColor: const Color(0xFF4285F4),
          icon: SvgPicture.string(_googleSvg, width: 22, height: 22),
        );
      case 'apple':
        // إخفاء زر Apple على أجهزة أندرويد لعدم دعمه أصلاً وإبقاء الواجهة نظيفة
        if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
          return null;
        }
        return _buildSocialIconBtn(
          providerKey: 'apple',
          bgColor: const Color(0xFF141416),
          borderColor: Colors.white24,
          glowColor: Colors.white24,
          icon: SvgPicture.string(_appleSvg, width: 22, height: 22),
        );
      case 'facebook':
        return _buildSocialIconBtn(
          providerKey: 'facebook',
          bgColor: const Color(0xFF1877F2),
          borderColor: const Color(0xFF4C9AFF),
          glowColor: const Color(0xFF1877F2),
          icon: SvgPicture.string(_facebookSvg, width: 22, height: 22),
        );
      case 'twitter':
      case 'x':
        return _buildSocialIconBtn(
          providerKey: 'twitter',
          bgColor: const Color(0xFF14171A),
          borderColor: Colors.white24,
          glowColor: const Color(0xFF1DA1F2),
          icon: SvgPicture.string(_twitterXSvg, width: 20, height: 20),
        );
      case 'linkedin':
        return _buildSocialIconBtn(
          providerKey: 'linkedin',
          bgColor: const Color(0xFF0A66C2),
          borderColor: const Color(0xFF378FE9),
          glowColor: const Color(0xFF0A66C2),
          icon: SvgPicture.string(_linkedinSvg, width: 20, height: 20),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProviders) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD27A)),
          ),
        ),
      );
    }

    if (_loadedProviders.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgets = <Widget>[];
    for (int i = 0; i < _loadedProviders.length; i++) {
      final providerKey = _loadedProviders[i]['provider']?.toString() ?? '';
      final w = _buildProviderWidget(providerKey);
      if (w != null) {
        widgets.add(w);
      }
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // المحاذاة في المنتصف تماماً حتى مع إخفاء أو تعطيل بعض المنصات
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: widgets,
      ),
    );
  }
}
