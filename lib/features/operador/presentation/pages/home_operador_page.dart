export 'home_page.dart' show HomePage;

// HomeOperadorPage es un alias de HomePage para la arquitectura de roles.
// El router usa HomeOperadorPage; internamente es la misma pantalla.
import 'package:flutter/material.dart';
import 'home_page.dart';

class HomeOperadorPage extends StatelessWidget {
  const HomeOperadorPage({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}
