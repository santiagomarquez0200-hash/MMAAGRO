import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

// ─── Paleta (misma del login) ─────────────────────────────────────────────────
const _kBg     = Color(0xFF060E08);
const _kCard   = Color(0xFF0E2016);
const _kLime   = Color(0xFF8CC53F);
const _kMuted  = Color(0xFF4A7055);
const _kBorder = Color(0xFF1F3D28);
const _kText   = Colors.white;
const _kTextDim = Color(0xFF7CA885);

class EnvConfigPage extends StatefulWidget {
  const EnvConfigPage({super.key});

  @override
  State<EnvConfigPage> createState() => _EnvConfigPageState();
}

class _EnvConfigPageState extends State<EnvConfigPage>
    with SingleTickerProviderStateMixin {
  late String _selectedUrl;
  bool _applying = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _envs = [
    _EnvOption(
      nombre: 'PRUEBAS',
      descripcion: 'Entorno de desarrollo y pruebas',
      url: AppEnvironment.urlPruebas,
      badgeColor: Color(0xFF92400E),
      badgeBg: Color(0xFF1C0A00),
      badgeText: Color(0xFFFBBF24),
      icon: Icons.science_outlined,
    ),
    _EnvOption(
      nombre: 'PRODUCCIÓN',
      descripcion: 'Entorno real — datos de operación',
      url: AppEnvironment.urlProduccion,
      badgeColor: Color(0xFF14532D),
      badgeBg: Color(0xFF052E16),
      badgeText: Color(0xFF86EFAC),
      icon: Icons.verified_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedUrl = AppEnvironment.erpBaseUrl;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicarCambio() async {
    if (_applying) return;
    setState(() => _applying = true);

    AppEnvironment.setUrlOverride(_selectedUrl);
    GetIt.instance<ErpApiClient>().updateBaseUrl(_selectedUrl);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('env_url_override', _selectedUrl);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _applying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Entorno cambiado a ${_envLabel(_selectedUrl)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      backgroundColor: const Color(0xFF15803D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
    Navigator.of(context).pop();
  }

  String _envLabel(String url) =>
      url.contains('Pruebas') ? 'PRUEBAS' : 'PRODUCCIÓN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCurrentBanner(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Selecciona el entorno'),
                      const SizedBox(height: 10),
                      ..._envs.map(_buildEnvCard),
                      const SizedBox(height: 32),
                      _buildApplyButton(),
                      const SizedBox(height: 20),
                      _buildUrlPreview(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar con flecha de retorno ─────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.8)),
      ),
      child: Row(
        children: [
          _buildIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Configuración de entorno',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kLime.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _kLime, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                _envLabel(AppEnvironment.erpBaseUrl),
                style: const TextStyle(
                  color: _kLime,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: _kTextDim, size: 18),
      ),
    );
  }

  // ── Banner del entorno actual ─────────────────────────────────────────────

  Widget _buildCurrentBanner() {
    final isProduccion =
        AppEnvironment.erpBaseUrl == AppEnvironment.urlProduccion;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isProduccion
                  ? const Color(0xFF14532D).withValues(alpha: 0.6)
                  : const Color(0xFF78350F).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isProduccion
                  ? Icons.verified_outlined
                  : Icons.science_outlined,
              color: isProduccion
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFFBBF24),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entorno activo',
                  style: TextStyle(color: _kTextDim, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  isProduccion ? 'PRODUCCIÓN' : 'PRUEBAS',
                  style: TextStyle(
                    color:
                        isProduccion ? const Color(0xFF86EFAC) : const Color(0xFFFBBF24),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isProduccion
                  ? const Color(0xFF14532D)
                  : const Color(0xFF78350F).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isProduccion ? 'LIVE' : 'TEST',
              style: TextStyle(
                color: isProduccion
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFBBF24),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Label de sección ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: _kLime,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: _kTextDim,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    ]);
  }

  // ── Tarjeta de entorno seleccionable ──────────────────────────────────────

  Widget _buildEnvCard(_EnvOption env) {
    final sel = _selectedUrl == env.url;
    return GestureDetector(
      onTap: () => setState(() => _selectedUrl = env.url),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: sel
              ? _kLime.withValues(alpha: 0.06)
              : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? _kLime.withValues(alpha: 0.55) : _kBorder,
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // ícono del entorno
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: env.badgeBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: env.badgeColor.withValues(alpha: 0.4)),
              ),
              child: Icon(env.icon, color: env.badgeText, size: 20),
            ),
            const SizedBox(width: 12),
            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      env.nombre,
                      style: TextStyle(
                        color: sel ? _kLime : _kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: env.badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        env.nombre == 'PRUEBAS' ? 'TEST' : 'LIVE',
                        style: TextStyle(
                          color: env.badgeText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    env.descripcion,
                    style: const TextStyle(
                      color: _kTextDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? _kLime : Colors.transparent,
                border: Border.all(
                  color: sel ? _kLime : _kMuted,
                  width: 2,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Botón aplicar ─────────────────────────────────────────────────────────

  Widget _buildApplyButton() {
    final changed = _selectedUrl != AppEnvironment.erpBaseUrl;
    return GestureDetector(
      onTap: (_applying || !changed) ? null : _aplicarCambio,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          gradient: (changed && !_applying)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7DB535), Color(0xFF4E7C22)],
                )
              : null,
          color: (changed && !_applying)
              ? null
              : _kCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: changed ? Colors.transparent : _kBorder,
          ),
          boxShadow: (changed && !_applying)
              ? [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: _applying
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: changed ? Colors.white : _kMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'APLICAR CAMBIO',
                      style: TextStyle(
                        color: changed ? Colors.white : _kMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Vista previa de la URL activa ──────────────────────────────────────────

  Widget _buildUrlPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'URL seleccionada',
            style: TextStyle(color: _kTextDim, fontSize: 10, letterSpacing: 0.3),
          ),
          const SizedBox(height: 5),
          Text(
            _selectedUrl,
            style: const TextStyle(
              color: Color(0xFF6B8F6B),
              fontSize: 10.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de opción de entorno ──────────────────────────────────────────────

class _EnvOption {
  final String nombre;
  final String descripcion;
  final String url;
  final Color badgeColor;
  final Color badgeBg;
  final Color badgeText;
  final IconData icon;

  const _EnvOption({
    required this.nombre,
    required this.descripcion,
    required this.url,
    required this.badgeColor,
    required this.badgeBg,
    required this.badgeText,
    required this.icon,
  });
}
