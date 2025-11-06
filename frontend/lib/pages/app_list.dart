import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/plant_model.dart';
import '../widgets/profile_menu.dart';
import 'dart:math';
import '../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ShelfPage extends StatefulWidget {
  final String workspaceId;
  final String workspaceName;
  final VoidCallback onDeploy;
  final Function(Plant) onPlantTap;
  final Function(String, String) onSlackReaction;
  final User currentUser;
  final Map<String, dynamic>? userData;
  final IO.Socket socket; // (★★★★★ 신규 ★★★★★: socket 받기)

  const ShelfPage({
    Key? key,
    required this.workspaceId,
    required this.workspaceName,
    required this.onDeploy,
    required this.onPlantTap,
    required this.onSlackReaction,
    required this.currentUser,
    this.userData,
    required this.socket, // (★★★★★ 신규 ★★★★★)
    // (★★★★★ 삭제 ★★★★★: required this.shelf 제거)
  }) : super(key: key);

  @override
  _ShelfPageState createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  List<Plant> shelf = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // AppCore에서 가져온 리스너
    // ShelfPage가 로드될 때 'current-shelf' 리스너 등록
    widget.socket.on('current-shelf', _onCurrentShelf);
  }

  @override
  void dispose() {
    // 리스너 해제
    widget.socket.off('current-shelf', _onCurrentShelf);
    super.dispose();
  }

  // AppCore에서 가져온 리스너 콜백
  void _onCurrentShelf(dynamic data) {
    if (!mounted) return;
    setState(() {
      shelf = (data as List).map((p) => Plant(
          id: p['id'],
          plantType: p['plantType'] ?? 'pot',
          version: p['version'],
          description: p['description'] ?? 'No description provided.',
          status: p['status'],
          ownerUid: p['ownerUid'] ?? '',
          workspaceId: p['workspaceId'] ?? '',
          reactions: List<String>.from(p['reactions'] ?? [])
      )..currentStatusMessage = (p['status'] == 'HEALTHY' ? '배포 완료됨' : (p['status'] == 'FAILED' ? '배포 실패함' : (p['status'] == 'SLEEPING' ? '겨울잠 상태' : '대기 중')))
      ).toList();
      _isLoading = false; // (로딩 완료)
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Plant> currentShelf = shelf;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspaceName),
        actions: [
          ProfileMenuButton(
            currentUser: widget.currentUser,
            userData: widget.userData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(l10n.apps,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.textTheme.displayLarge?.color,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 20),
            Expanded(
              child: shelf.isEmpty
                  ? Center(child: Text('앱이 없습니다. "새 앱 배포하기"를 눌러 시작하세요.'))
                  : ListView.builder(
                itemCount: shelf.length,
                itemBuilder: (context, index) {
                  final plant = shelf[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TossProjectListTile(
                      plant: plant,
                      onTap: () => widget.onPlantTap(plant),
                      onSlackReaction: (emoji) =>
                          widget.onSlackReaction(plant.id, emoji),
                      currentUser: widget.currentUser,
                      userData: widget.userData,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onDeploy,
        label: Text(l10n.deployNewApp),
        icon: Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: StadiumBorder(),
      ),
    );
  }
}

// --- (5) "Toss 스타일 리스트 타일" ---
class TossProjectListTile extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final Function(String) onSlackReaction;

  final User currentUser;
  final Map<String, dynamic>? userData;

  const TossProjectListTile({
    Key? key,
    required this.plant,
    required this.onTap,
    required this.onSlackReaction,
    required this.currentUser,
    this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String lottieFile;
    // (신규) "겨울잠" 상태 추가
    if (plant.status == 'SLEEPING') {
      lottieFile = 'assets/pot_sleeping.json'; // (신규) 잠자는 Lottie
    } else {
      switch (plant.plantType) {
        case 'rose': lottieFile = 'assets/rose.json'; break;
        case 'cactus': lottieFile = 'assets/cactus.json'; break;
        case 'bonsai': lottieFile = 'assets/bonsai.json'; break;
        case 'sunflower': lottieFile = 'assets/sunflower.json'; break;
        case 'maple': lottieFile = 'assets/maple.json'; break;
        case 'cherry_blossom': lottieFile = 'assets/cherry_blossom.json'; break;
        case 'pot': lottieFile = 'assets/pot.json'; break;
        default: lottieFile = 'assets/pot.json';
      }
    }

    if (plant.status == 'FAILED') lottieFile = 'assets/wilted_fly.json';
    if (plant.status == 'DEPLOYING' || plant.status == 'PENDING') lottieFile = 'assets/growing.json';

    Color statusColor;
    String statusText = plant.status;
    if (plant.status == 'FAILED') { statusColor = Colors.red; }
    else if (plant.status == 'DEPLOYING' || plant.status == 'PENDING') { statusColor = Colors.orange; }
    else if (plant.status == 'SLEEPING') { // (신규) 겨울잠 상태
      statusColor = Colors.grey[400]!;
      statusText = l10n.plantStatusSleeping; // "겨울잠"
    }
    else { statusColor = Colors.green; }

    return Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: Lottie.asset(lottieFile, width: 52, height: 52, fit: BoxFit.contain),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plant.version, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: statusColor),
                              SizedBox(width: 6),
                              Text(statusText, style: theme.textTheme.bodySmall), // (수정)
                              SizedBox(width: 6),
                              Text(plant.reactions.join(' '), style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
                  ],
                ),
              ),
            ),
          ),
          if (plant.isSparkling)
            IgnorePointer(
              child: Center(
                child: Lottie.asset('assets/sparkles.json', width: 150, height: 150, repeat: false),
              ),
            ),
        ]
    );
  }
}