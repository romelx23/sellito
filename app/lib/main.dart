import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/customer_session.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/landing_screen.dart';
import 'features/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = Session();
  final customer = CustomerSession();

  await session.restore();
  await customer.restore();
  final onboarded = await OnboardingScreen.isDone();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: customer),
      ],
      child: SellaApp(
        home: onboarded ? const LandingScreen() : const OnboardingScreen(),
      ),
    ),
  );
}

class SellaApp extends StatelessWidget {
  const SellaApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sella · Tarjetas de fidelidad',
      debugShowCheckedModeBanner: false,
      theme: buildSellaTheme(),
      home: home,
    );
  }
}
