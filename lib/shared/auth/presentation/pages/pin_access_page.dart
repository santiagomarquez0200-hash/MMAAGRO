import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/core/config/env_config_page.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';

// ─── Paleta ────────────────────────────────────────────────────────────────────
const _kBg   = Color(0xFF060E08);
const _kCard = Color(0xFF0E2016);
const _kLime      = Color(0xFF8CC53F);
const _kLimeDim   = Color(0xFF5A8428);
const _kMuted     = Color(0xFF4A7055);
const _kBorder    = Color(0xFF1F3D28);
const _kText      = Colors.white;
const _kTextDim   = Color(0xFF7CA885);

class PinAccessPage extends StatefulWidget {
  const PinAccessPage({super.key});

  @override
  State<PinAccessPage> createState() => _PinAccessPageState();
}

class _PinAccessPageState extends State<PinAccessPage>
    with TickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _usuarioCtrl   = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool   _obscurePassword    = true;
  bool   _guardarCredenciales = false;
  String _rolSeleccionado    = 'operador';

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _cargarCredenciales();
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('guardar_credenciales') ?? false)) return;
    final savedUser = await _storage.read(key: 'saved_usuario');
    final savedPass = await _storage.read(key: 'saved_password');
    final savedRol  = await _storage.read(key: 'saved_rol');
    if (savedUser != null && savedPass != null && mounted) {
      setState(() {
        _usuarioCtrl.text   = savedUser;
        _passwordCtrl.text  = savedPass;
        if (savedRol != null) _rolSeleccionado = savedRol;
        _guardarCredenciales = true;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final usuario  = _usuarioCtrl.text.trim();
    final password = _passwordCtrl.text;

    final prefs = await SharedPreferences.getInstance();
    if (_guardarCredenciales) {
      await _storage.write(key: 'saved_usuario',  value: usuario);
      await _storage.write(key: 'saved_password', value: password);
      await _storage.write(key: 'saved_rol',      value: _rolSeleccionado);
      await prefs.setBool('guardar_credenciales', true);
    } else {
      await _storage.delete(key: 'saved_usuario');
      await _storage.delete(key: 'saved_password');
      await _storage.delete(key: 'saved_rol');
      await prefs.setBool('guardar_credenciales', false);
    }

    if (!mounted) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          codigo:   usuario,
          pin:      password,
          username: usuario,
          password: password,
          rol:      _rolSeleccionado,
        ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ));
          }
        },
        child: Stack(children: [
          // ── Fondo decorativo ───────────────────────────────────────────
          const _LoginBackground(),
          // ── Contenido ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: LayoutBuilder(builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),

                              // ── Branding ─────────────────────────────────
                              _buildBranding(),
                              const SizedBox(height: 36),

                              // ── Tarjeta de formulario ─────────────────────
                              _buildFormCard(),

                              const Spacer(),
                              // ── Footer ────────────────────────────────────
                              _buildFooter(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // ── Botón de entorno (encima de todo para recibir toques) ──────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 14),
                child: _buildEnvButton(context),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Botón configuración de entorno ────────────────────────────────────────

  Widget _buildEnvButton(BuildContext context) {
    final isProd =
        AppEnvironment.erpBaseUrl == AppEnvironment.urlProduccion;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EnvConfigPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          isProd ? 'PROD' : 'TEST',
          style: TextStyle(
            color: isProd ? const Color(0xFF86EFAC) : const Color(0xFFFBBF24),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // ── Branding ──────────────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Column(children: [
      // Logo con glow
      Stack(alignment: Alignment.center, children: [
        // Glow exterior
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _kLime.withValues(alpha: 0.18),
                _kLime.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Círculo exterior semitransparente
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _kLime.withValues(alpha: 0.2), width: 1),
            color: _kLime.withValues(alpha: 0.04),
          ),
        ),
        // Círculo interior con icono
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3D28), Color(0xFF0F2518)],
            ),
            border: Border.all(
                color: _kLime.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kLime.withValues(alpha: 0.22),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/ic_launcher2.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ]),
      const SizedBox(height: 18),

      // Nombre empresa
      const Text(
        'AGROKASA',
        style: TextStyle(
          color: _kText,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.5,
          height: 1.0,
        ),
      ),
      const SizedBox(height: 5),

      // Nombre app
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          color: _kLime.withValues(alpha: 0.06),
        ),
        child: const Text(
          'AgriControl  ·  Sistema MMA',
          style: TextStyle(
            color: _kTextDim,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ]);
  }

  // ── Tarjeta de formulario ─────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(children: [
        // Cabecera del card
        Row(children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _kLime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Acceso al sistema',
            style: TextStyle(
              color: _kText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, size: 16, color: _kMuted),
        ]),
        const SizedBox(height: 20),

        // Selector de rol
        _buildRolSelector(),
        const SizedBox(height: 20),

        // Separador
        Row(children: [
          Expanded(child: Divider(color: _kBorder, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('credenciales',
                style: TextStyle(
                    color: _kMuted.withValues(alpha: 0.6), fontSize: 10)),
          ),
          Expanded(child: Divider(color: _kBorder, thickness: 0.8)),
        ]),
        const SizedBox(height: 18),

        // Campo usuario
        _buildField(
          controller: _usuarioCtrl,
          label: 'Usuario',
          hint: 'Código ERP',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Ingrese su usuario' : null,
        ),
        const SizedBox(height: 14),

        // Campo contraseña
        _buildPasswordField(),
        const SizedBox(height: 16),

        // Recordar credenciales
        _buildRecordarRow(),
        const SizedBox(height: 22),

        // Botón ingresar
        _buildLoginButton(),
      ]),
    );
  }

  // ── Selector de rol ───────────────────────────────────────────────────────

  Widget _buildRolSelector() {
    final roles = [
      ('operador',   'Operario',   Icons.agriculture_rounded),
      ('portero',    'Portero',    Icons.security_rounded),
      ('supervisor', 'Supervisor', Icons.manage_accounts_rounded),
      ('mecanico',   'Mecánico',   Icons.build_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: roles
            .map((r) => _buildRolTab(r.$1, r.$2, r.$3))
            .toList(),
      ),
    );
  }

  Widget _buildRolTab(String value, String label, IconData icon) {
    final sel = _rolSeleccionado == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rolSeleccionado = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6AA32E), Color(0xFF4E7C22)],
                  )
                : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: _kLime.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              icon,
              size: 17,
              color: sel ? Colors.white : _kMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: sel ? Colors.white : _kMuted,
                fontSize: 10.5,
                fontWeight:
                    sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Campos de texto ───────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputAction textInputAction = TextInputAction.done,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      textInputAction: textInputAction,
      autocorrect: false,
      style: const TextStyle(
          color: _kText, fontSize: 14.5, letterSpacing: 0.2),
      decoration: _fieldDecoration(label: label, hint: hint, icon: icon),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      style: const TextStyle(
          color: _kText, fontSize: 14.5, letterSpacing: 0.5),
      decoration: _fieldDecoration(
        label: 'Contraseña',
        hint: '········',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _kMuted,
            size: 19,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) =>
          (v?.isEmpty ?? true) ? 'Ingrese su contraseña' : null,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          const TextStyle(color: _kTextDim, fontSize: 12.5),
      hintStyle: TextStyle(
          color: _kMuted.withValues(alpha: 0.45), fontSize: 13),
      prefixIcon: Icon(icon, color: _kMuted, size: 19),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: base,
      enabledBorder: base,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kLime, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade500, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade500, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
    );
  }

  // ── Recordar credenciales ─────────────────────────────────────────────────

  Widget _buildRecordarRow() {
    return GestureDetector(
      onTap: () =>
          setState(() => _guardarCredenciales = !_guardarCredenciales),
      behavior: HitTestBehavior.opaque,
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: _guardarCredenciales ? _kLime : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _guardarCredenciales ? _kLime : _kMuted,
              width: 1.5,
            ),
          ),
          child: _guardarCredenciales
              ? const Icon(Icons.check_rounded,
                  size: 11, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 9),
        const Text(
          'Recordar mis credenciales',
          style: TextStyle(
            color: _kTextDim,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }

  // ── Botón de login ────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, state) {
        final loading = state is AuthLoading;
        return GestureDetector(
          onTap: loading ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: loading
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7DB535), Color(0xFF4E7C22)],
                    ),
              color: loading
                  ? _kLimeDim.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(13),
              boxShadow: loading
                  ? null
                  : [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'INGRESAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
              color: _kLimeDim, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        const Text(
          'AgriControl MMA',
          style: TextStyle(color: _kMuted, fontSize: 11),
        ),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 10,
          color: _kBorder,
        ),
        const SizedBox(width: 8),
        const Text(
          'Agrokasa · Pisco',
          style: TextStyle(color: _kMuted, fontSize: 11),
        ),
        const SizedBox(width: 6),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
              color: _kLimeDim, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

// ─── Fondo decorativo ─────────────────────────────────────────────────────────

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BgPainter(size: size),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final Size size;
  const _BgPainter({required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    // Gradiente base
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF060E08), Color(0xFF0A1A0D), Color(0xFF060E08)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height), bgPaint);

    // Arco grande top-right
    final arc1 = Paint()
      ..color = const Color(0xFF8CC53F).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(sz.width + sz.width * 0.1, -sz.height * 0.05),
        sz.width * 0.75,
        arc1);

    // Círculo stroke top-right
    final arc2 = Paint()
      ..color = const Color(0xFF8CC53F).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
        Offset(sz.width * 0.85, sz.height * 0.0),
        sz.width * 0.55,
        arc2);

    // Círculo stroke bottom-left
    final arc3 = Paint()
      ..color = const Color(0xFF8CC53F).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(
        Offset(-sz.width * 0.15, sz.height * 1.05),
        sz.width * 0.65,
        arc3);

    // Pequeños puntos decorativos dispersos
    final dotPaint = Paint()
      ..color = const Color(0xFF8CC53F).withValues(alpha: 0.08);
    final rng = [
      const Offset(0.12, 0.15),
      const Offset(0.88, 0.22),
      const Offset(0.05, 0.45),
      const Offset(0.95, 0.50),
      const Offset(0.20, 0.80),
      const Offset(0.80, 0.75),
      const Offset(0.50, 0.93),
    ];
    for (final pt in rng) {
      canvas.drawCircle(Offset(sz.width * pt.dx, sz.height * pt.dy), 2.0,
          dotPaint);
    }

    // Líneas diagonales sutiles (trama)
    final linePaint = Paint()
      ..color = const Color(0xFF8CC53F).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (var i = -sz.height.toInt();
        i < sz.width.toInt() * 2;
        i += 48) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble() + sz.height * math.tan(math.pi / 4), sz.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.size != size;
}
