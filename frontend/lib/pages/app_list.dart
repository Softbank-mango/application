// app_list.dart (ShelfPage)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timeago/timeago.dart' as timeago; // 시간 표시 (예: "2시간 전")
import 'package:percent_indicator/percent_indicator.dart'; // 프로그레스 바

import '../models/plant_model.dart'; // (수정된 Plant 모델 임포트)
import '../models/user_data.dart';

class ShelfPage extends StatefulWidget {
  final String workspaceId;
  final String workspaceName;
  final VoidCallback onDeploy; // "+ 새 앱 배포" 버튼에 연결됨
  final Function(Plant) onPlantTap;
  final Function(String, String) onSlackReaction;
  final User currentUser;
  final UserData? userData;
  final IO.Socket socket;
  final List<dynamic> workspaces; // (TopBar용 - 현재는 사용 안함)
  final Function(String, String) onCreateWorkspace; // (TopBar용)

  const ShelfPage({
    Key? key,
    required this.workspaceId,
    required this.workspaceName,
    required this.onDeploy,
    required this.onPlantTap,
    required this.onSlackReaction,
    required this.currentUser,
    this.userData,
    required this.socket,
    required this.workspaces,
    required this.onCreateWorkspace,
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
    widget.socket.on('current-shelf', _onCurrentShelf);
    widget.socket.emit('get-current-shelf', widget.workspaceId);
    timeago.setLocaleMessages('ko', timeago.KoMessages());
  }

  @override
  void dispose() {
    widget.socket.off('current-shelf', _onCurrentShelf);
    super.dispose();
  }

  // (수정) 새 Plant 모델에 맞게 리스너 콜백 업데이트
  void _onCurrentShelf(dynamic data) {
    if (!mounted) return;
    setState(() {
      shelf = (data as List)
          .map((p) => Plant.fromMap(p as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  // (신규) 페이지 헤더 빌드
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "앱 대시보드", //
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${widget.workspaceName}의 배포된 앱들을 관리하세요", //
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        // (신규) "+ 새 앱 배포" 버튼
        ElevatedButton.icon(
          onPressed: widget.onDeploy, // AppCore의 onDeploy 함수 연결
          icon: Icon(Icons.add, size: 18),
          label: Text("새 앱 배포"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF678AFB), // 이미지 기준 파란색
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 쉘프가 비어있을 때 처리
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 페이지 헤더 (제목 + 버튼)
          _buildHeader(context),
          SizedBox(height: 24),

          // 2. 앱 카드 그리드
          Expanded(
            child: shelf.isEmpty
                ? Center(child: Text('앱이 없습니다. "새 앱 배포"를 눌러 시작하세요.'))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4열 그리드
                crossAxisSpacing: 24, // 가로 간격
                mainAxisSpacing: 24, // 세로 간격
                childAspectRatio: 1.4, // 카드 종횡비 (조절 필요)
              ),
              itemCount: shelf.length,
              itemBuilder: (context, index) {
                final plant = shelf[index];
                // (신규) 앱 대시보드 카드 위젯 사용
                return _AppDashboardCard(
                  plant: plant,
                  onTap: () => widget.onPlantTap(plant),
                  // "깨우기" 버튼 등 카드 내부 액션 (추후 구현)
                  // onWakeUp: () => ...
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- (신규) 이미지와 100% 동일한 앱 대시보드 카드 위젯 ---
class _AppDashboardCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  // final VoidCallback onWakeUp; (추후 구현)

  const _AppDashboardCard({
    Key? key,
    required this.plant,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 카드 헤더 (아이콘, 이름, URL)
              _buildCardHeader(context, plant),
              SizedBox(height: 16),
              // 2. 상태에 따른 본문
              Expanded(child: _buildCardBody(context, plant)),
            ],
          ),
        ),
      ),
    );
  }

  // 카드 헤더 (아이콘, 이름, URL)
  Widget _buildCardHeader(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFFF0F4FF), // 연한 보라색 배경
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.desktop_windows, color: Color(0xFF678AFB)), //
        ),
        SizedBox(width: 12),
        // 이름, URL
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.name,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                plant.githubUrl,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 카드 본문 (상태에 따라 분기)
  Widget _buildCardBody(BuildContext context, Plant plant) {
    // "2시간 전" 계산
    final String timeAgo = timeago.format(plant.lastDeployedAt.toDate(), locale: 'ko');

    switch (plant.status) {
      case 'HEALTHY': // "정상" 상태
      case 'NORMAL':
      // (수정) 0.0 ~ 1.0 사이의 비율로 정규화
      // ⚠️ 중요: plant.cpuLimit, plant.memLimit 필드명은
      //           실제 Plant 모델에 맞게 수정해야 합니다.

      // 1. 0으로 나누기 방지를 위해 기본값(1.0) 설정
      //   final double cpuLimit = plant.cpuLimit ?? 1.0;
      //   final double memLimit = plant.memLimit ?? 1.0;

        // 2. 0으로 나누기 방지 로직 추가
      final double cpuPercent = plant.cpuUsage / 100.0;
      final double memPercent = plant.memUsage / 100.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(Icons.check_circle, "정상", Color(0xFF00B894)),
            SizedBox(height: 4),
            Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Spacer(),
            // (수정) 정규화된 비율(percent)을 전달
            _buildProgressBar("CPU", cpuPercent, Color(0xFF678AFB)),
            SizedBox(height: 8),
            _buildProgressBar("메모리", memPercent, Color(0xFF00B894)),
          ],
        );
      case 'SLEEPING': // "겨울잠" 상태
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(Icons.pause_circle_outline, "겨울잠", Color(0xFFFDCB6E)),
            SizedBox(height: 4),
            Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Spacer(),
            Text("앱이 겨울잠 상태입니다", style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () { /* 깨우기 로직 (onPlantTap으로 대체) */ },
              child: Text("깨우기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF0F4FF),
                foregroundColor: Color(0xFF678AFB),
                elevation: 0,
              ),
            )
          ],
        );
      case 'DEPLOYING': // "배포중" 상태
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(Icons.sync, "배포중", Color(0xFF678AFB)),
            SizedBox(height: 4),
            Text("배포중...", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Spacer(),
            LinearProgressIndicator(color: Color(0xFF678AFB)),
            SizedBox(height: 4),
            Text("배포가 진행 중입니다...", style: TextStyle(color: Colors.grey[600])),
          ],
        );
      case 'FAILED': // "오류" 상태
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusChip(Icons.error, "오류", Color(0xFFD63031)),
            SizedBox(height: 4),
            Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Spacer(),
            Text("배포에 실패했습니다.", style: TextStyle(color: Color(0xFFD63031))),
            // (오류 로그 등 추가 정보)
          ],
        );
    }
  }

  // (Helper) 상태 칩
  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // (Helper) 프로그레스 바
  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearPercentIndicator(
                percent: percent,
                lineHeight: 8,
                backgroundColor: Colors.grey[200],
                progressColor: color,
                barRadius: Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "${(percent * 100).toInt()}%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}