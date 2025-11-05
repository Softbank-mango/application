import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../l10n/app_localizations.dart'; // (신규)

// --- (8) (신규) 배포 로딩 페이지 ---
class DeploymentLoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!; // (신규)

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loadingTitle), // (수정)
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/pot.json', width: 200, height: 200),
            SizedBox(height: 20),
            Text(
              l10n.loadingMessage, // (수정)
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.textTheme.displayLarge?.color),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}