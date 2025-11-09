import 'package:flutter/material.dart';
import '../models/pipeline_status.dart'; // PipelineStatus 모델 임포트 (경로 확인 필요)

class PipelineMonitor extends StatelessWidget {
  final PipelineStatus status;
  final String appName;

  const PipelineMonitor({
    Key? key,
    required this.status,
    required this.appName,
  }) : super(key: key);

  // --- 이미지와 100% 일치하는 색상 및 스타일 정의 ---
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1F2937);
  static const Color _subTextColor = Color(0xFF4B5563);
  static const Color _primaryBlue = Color(0xFF4F46E5); // 진한 파란색 (Progress Bar)
  static const Color _lightGreen = Color(0xFFF0FDF4); // 완료 배경
  static const Color _darkGreen = Color(0xFF059669); // 완료 아이콘/체크
  static const Color _lightBlue = Color(0xFFEFF6FF); // 진행 중 배경
  static const Color _darkBlue = Color(0xFF3B82F6); // 진행 중 아이콘
  static const Color _pendingGrey = Color(0xFFD1D5DB); // 대기 중 테두리/아이콘
  static const Color _pendingText = Color(0xFF6B7280); // 대기 중 텍스트

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.all(24.0),
      // (레이아웃 빌더 대신 Row/Column으로 구성하여 컨테이너로 사용)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (앱 이름 및 전체 진행률)
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. 메인 컨텐츠 (이미지 시각화 + 스텝 목록)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2-1. 왼쪽 시각화 (더미 플레이스홀더)
                Expanded(flex: 2, child: _buildVisualizationPlaceholder()),
                const SizedBox(width: 24),
                // 2-2. 오른쪽 스텝 목록
                Expanded(flex: 1, child: _buildStepList(context)),
              ],
            ),
          ),

          // 3. 하단 전체 진행률 바
          const SizedBox(height: 20),
          _buildOverallProgressBar(),
        ],
      ),
    );
  }

  // --- 1. 헤더 (앱 이름 및 전체 진행률 텍스트) ---
  Widget _buildHeader() {
    // 진행률은 0.26이 넘어왔을 때 26%로 표시 (overallProgress는 0.0 ~ 1.0)
    final String progressPercent = (status.overallProgress * 100).toStringAsFixed(0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.corporate_fare_outlined, size: 24, color: _primaryBlue),
            const SizedBox(width: 8),
            Text(
              "배포 진행 중",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
            ),
            const SizedBox(width: 8),
            Text(
              appName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: _textColor),
            ),
          ],
        ),
        Text(
          "$progressPercent%",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryBlue),
        ),
      ],
    );
  }

  // --- 2-1. 시각화 플레이스홀더 (이미지 재현) ---
  Widget _buildVisualizationPlaceholder() {
    // 실제 복잡한 다이어그램을 Lottie나 SVG로 대체하는 것이 좋지만,
    // 여기서는 이미지와 유사한 느낌의 배경 컨테이너를 만듭니다.
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // 연한 회색 배경
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          // 복잡한 다이어그램 이미지는 Dart 코드로 완벽 재현 불가능하므로, 
          // 이전에 약속했던 시각화 다이어그램의 Lottie/SVG 경로로 대체해야 합니다.
          // 현재는 Placeholder 처리합니다.
          image: AssetImage('assets/diagram.png'),
          fit: BoxFit.cover,
        ),
      ),
      // 이미지가 너무 작게 보이지 않도록 최소 높이 지정
      height: 450,
    );
  }

  // --- 2-2. 스텝 목록 ---
  Widget _buildStepList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(), // 스크롤 경계 제한
      itemCount: status.steps.length,
      itemBuilder: (context, index) {
        final step = status.steps[index];
        return _buildStepItem(context, step);
      },
    );
  }

  // --- 개별 스텝 아이템 빌더 ---
  Widget _buildStepItem(BuildContext context, PipelineStep step) {
    // 상태에 따른 색상 및 아이콘 설정
    Color bgColor = _pendingGrey.withOpacity(0.1);
    Color borderColor = _pendingGrey;
    Color iconColor = _pendingGrey;
    Color nameColor = _pendingText;
    IconData icon = Icons.circle_outlined;
    double progressValue = step.progress / 100.0;
    bool showProgress = false;

    switch (step.status) {
      case 'completed':
        bgColor = _lightGreen;
        borderColor = _darkGreen.withOpacity(0.5);
        iconColor = _darkGreen;
        nameColor = _darkGreen;
        icon = Icons.check_circle;
        break;
      case 'active':
        bgColor = _lightBlue;
        borderColor = _darkBlue.withOpacity(0.5);
        iconColor = _darkBlue;
        nameColor = _textColor; // 진행 중일 때는 텍스트 진하게
        icon = Icons.sync_outlined;
        showProgress = true;
        break;
      case 'failed':
        bgColor = const Color(0xFFFEE2E2); // 연한 빨간색
        borderColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFEF4444);
        nameColor = _textColor;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: step.status == 'active' ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    step.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: nameColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // 진행률 텍스트 (active 상태에서만 표시)
              if (step.status == 'active' || step.status == 'pending')
                Text(
                  "${(step.progress).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkBlue, // 진행 중일 때 파란색
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 설명/메시지
          Text(
            // 설명이 없으면 상태 메시지 사용
            step.status == 'completed'
                ? '최신 코드를 가져오고 환경을 설정하는 중...'
                : (step.status == 'active' ? '컨테이너 이미지를 빌드하는 중...' : '대기 중'),
            style: TextStyle(color: _subTextColor, fontSize: 13),
          ),
          // 진행률 바 (Active 상태에서만)
          if (showProgress)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 6,
                backgroundColor: _pendingGrey.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(_darkBlue),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }

  // --- 3. 하단 전체 진행률 바 ---
  Widget _buildOverallProgressBar() {
    final String progressPercent = (status.overallProgress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("전체 진행률", style: TextStyle(color: _textColor, fontSize: 14)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: status.overallProgress,
            minHeight: 12,
            backgroundColor: _pendingGrey.withOpacity(0.5),
            // 이미지와 동일한 그라데이션을 흉내 내기 위해 파란색 사용
            valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 4),
          // 예상 완료 시간 (status.message가 이 역할을 수행한다고 가정)
          Text(
            "예상 완료 시간: ${status.message.contains('오류') ? '실패' : '10초 후'}",
            style: TextStyle(color: _subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}