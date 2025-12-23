import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_scope.dart';
import 'auth/create_account_screen.dart';
import 'auth/login_screen.dart';
import 'accounts/account_controller.dart';
import 'accounts/account_scope.dart';
import 'categories/category_controller.dart';
import 'categories/category_scope.dart';
import 'home/home_screen.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_scope.dart';
import 'transactions/transaction_controller.dart';
import 'transactions/transaction_scope.dart';
import 'usage/usage_controller.dart';
import 'usage/usage_scope.dart';

class FlutterAccountApp extends StatefulWidget {
  const FlutterAccountApp({super.key});

  @override
  State<FlutterAccountApp> createState() => _FlutterAccountAppState();
}

class _FlutterAccountAppState extends State<FlutterAccountApp> {
  late final AuthController _authController;
  late final TransactionController _transactionController;
  late final AccountController _accountController;
  late final CategoryController _categoryController;
  late final SettingsController _settingsController;
  late final UsageController _usageController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(authRepository: AuthRepository());
    _transactionController = TransactionController();
    _accountController = AccountController(
      transactionController: _transactionController,
    );
    _categoryController = CategoryController();
    _settingsController = SettingsController();
    _usageController = UsageController();
    WidgetsBinding.instance.addObserver(_authController);
    WidgetsBinding.instance.addObserver(_usageController);
    _authController.init();
    _transactionController.init();
    _accountController.init();
    _categoryController.init();
    _settingsController.init();
    _usageController.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_authController);
    WidgetsBinding.instance.removeObserver(_usageController);
    _authController.dispose();
    _transactionController.dispose();
    _accountController.dispose();
    _categoryController.dispose();
    _settingsController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: _settingsController,
      child: UsageScope(
        controller: _usageController,
        child: AuthScope(
          controller: _authController,
          child: TransactionScope(
            controller: _transactionController,
            child: AccountScope(
              controller: _accountController,
              child: CategoryScope(
                controller: _categoryController,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _settingsController,
                    _usageController,
                    _authController,
                    _transactionController,
                    _accountController,
                    _categoryController,
                  ]),
                  builder: (context, _) {
                    return MaterialApp(
                      title: 'Offline Account',
                      theme: ThemeData(
                        useMaterial3: true,
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: Colors.indigo,
                          brightness: Brightness.light,
                        ),
                      ),
                      darkTheme: ThemeData(
                        useMaterial3: true,
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: Colors.indigo,
                          brightness: Brightness.dark,
                        ),
                      ),
                      themeMode: _settingsController.themeMode,
                      locale: _settingsController.locale,
                      supportedLocales: const [Locale('en'), Locale('fa')],
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      builder: (context, child) {
                        final mediaQuery = MediaQuery.of(context);
                        return MediaQuery(
                          data: mediaQuery.copyWith(
                            textScaler: TextScaler.linear(
                              _settingsController.textScale,
                            ),
                          ),
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                      home: _homeForState(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeForState() {
    if (!_authController.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_transactionController.initialized ||
        !_accountController.initialized ||
        !_categoryController.initialized ||
        !_settingsController.initialized ||
        !_usageController.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_authController.hasAccount) return const CreateAccountScreen();
    if (!_authController.authenticated) return const LoginScreen();
    return const HomeScreen();
  }
}
