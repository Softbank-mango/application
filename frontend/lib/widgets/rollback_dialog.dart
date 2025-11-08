import 'package:flutter/material.dart';
import '../pages/deployment.dart';

// --- 데이터를 전달하기 위한 간단한 모델 ---
// (실제 사용 중인 모델로 대체하거나, 이 구조에 맞게 데이터를 전달해야 합니다.)
class DeploymentHistoryItem {
  final String id;
  final String version;
  final String statusText;
  final Color statusColor;
  final DateTime deployedAt;
  final String deployer;
  final String commitSha;
  final String commitMessage;
  final bool isCurrentVersion;

  DeploymentHistoryItem({
    required this.id,
    required this.version,
    required this.statusText,
    required this.statusColor,
    required this.deployedAt,
    required this.deployer,
    required this.commitSha,
    required this.commitMessage,
    this.isCurrentVersion = false,
  });
}

// --- 롤백 모달 위젯 ---
class RollbackDialog extends StatefulWidget {
  final String currentAppName;
  final List<DeploymentHistoryItem> history;
  final Function(DeploymentHistoryItem selectedItem) onRollbackConfirmed;

  const RollbackDialog({
    Key? key,
    required this.currentAppName,
    required this.history,
    required this.onRollbackConfirmed,
  }) : super(key: key);

  @override
  _RollbackDialogState createState() => _RollbackDialogState();
}

class _RollbackDialogState extends State<RollbackDialog> {
  // 선택된 롤백 버전을 관리
  DeploymentHistoryItem? _selectedItem;

  // --- 이미지와 100% 일치시키기 위한 색상 정의 ---
  static const Color _iconBgColor = Color(0xFFFEF3E8); // 주황색 아이콘 배경
  static const Color _iconColor = Color(0xFFF57C00); // 주황색 아이콘
  static const Color _warningBgColor = Color(0xFFFFFBEA); // 주의사항 노란 배경
  static const Color _warningBorderColor = Color(0xFFFFEEB3); // 주의사항 노란 테두리
  static const Color _warningIconColor = Color(0xFFF57C00); // 주의사항 아이콘
  static const Color _dangerColor = Color(0xFFD32F2F); // 롤백 실행 버튼 (빨간색)
  static const Color _infoBarBgColor = Color(0xFFF0F4FF); // 하단 정보 바 배경
  static const Color _infoBarTextColor = Color(0xFF3F51B5); // 하단 정보 바 텍스트
  static const Color _primaryColor = Color(0xFF3F51B5); // 선택된 테두리 (파란색)
  static const Color _textColor = Color(0xFF212121);
  static const Color _subTextColor = Color(0xFF616161);
  static const Color _borderColor = Color(0xFFE0E0E0); // 기본 테두리

  @override
  void initState() {
    super.initState();

    // 1. "현재"가 아닌 모든 항목을 찾습니다.
    final nonCurrentHistory = widget.history.where(
            (item) => !item.isCurrentVersion
    );

    if (nonCurrentHistory.isNotEmpty) {
      // 2. "현재"가 아닌 항목이 있다면, 그 중 첫 번째를 기본 선택합니다.
      _selectedItem = nonCurrentHistory.first;
    } else {
      // 3. "현재"가 아닌 항목이 없다면(리스트가 비었거나 "현재" 버전만 있다면),
      //    리스트의 첫 번째 항목을 선택합니다 (null일 수 있음).
      _selectedItem = widget.history.isNotEmpty ? widget.history.first : null;
    }
  }

  // 날짜 포매터 (간단 버전)
  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // 모든 Padding을 수동으로 제어
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      // 모달이 너무 커지지 않도록 최대 너비/높이 제한
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600, // 모달 최대 너비
          maxHeight: MediaQuery.of(context).size.height * 0.8, // 화면 높이의 80%
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // content 크기에 맞게 조절
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더 (아이콘, 제목, 닫기 버튼)
            _buildHeader(theme),

            // 2. 스크롤 가능한 본문
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2-1. 주의사항 박스
                      _buildWarningBox(theme),
                      const SizedBox(height: 24),
                      // 2-2. 배포 히스토리
                      Text(
                        "배포 히스토리",
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
                      ),
                      const SizedBox(height: 12),
                      // 2-3. 히스토리 목록
                      ListView.builder(
                        shrinkWrap: true, // 내부 content 크기만큼 높이 차지
                        physics: const NeverScrollableScrollPhysics(), // 부모 스크롤 사용
                        itemCount: widget.history.length,
                        itemBuilder: (context, index) {
                          final item = widget.history[index];
                          return _buildHistoryItem(theme, item);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. 하단 액션 버튼
            _buildActionButtons(theme),

            // 4. 하단 정보 바 (동적 텍스트)
            _buildInfoBar(theme),
          ],
        ),
      ),
    );
  }

  // --- 1. 헤더 위젯 빌더 ---
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _iconBgColor,
            radius: 20,
            child: const Icon(Icons.history, color: _iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "앱 롤백",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
                ),
                Text(
                  widget.currentAppName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: _subTextColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _subTextColor),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // --- 2-1. 주의사항 박스 빌더 ---
  Widget _buildWarningBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _warningBgColor,
        border: Border.all(color: _warningBorderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _warningIconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "주의사항",
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "롤백을 실행하면 선택한 버전으로 앱이 되돌아갑니다. 현재 버전 이후의 모든 변경사항이 손실될 수 있습니다.",
                  style: theme.textTheme.bodySmall?.copyWith(color: _subTextColor),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2-3. 히스토리 아이템 빌더 ---
  Widget _buildHistoryItem(ThemeData theme, DeploymentHistoryItem item) {
    // 현재 선택된 아이템인지 확인
    final bool isSelected = _selectedItem?.id == item.id;
    // "현재" 버전인지 확인
    final bool isCurrent = item.isCurrentVersion;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        // "현재" 버전은 롤백 대상으로 선택할 수 없음
        onTap: isCurrent ? null : () {
          setState(() {
            _selectedItem = item;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              // 선택 시 파란색, 아니면 회색, 현재 버전이면 투명
              color: isSelected ? _primaryColor : (isCurrent ? Colors.transparent : _borderColor),
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            // 현재 버전은 약간 회색 배경
            gradient: isCurrent
                ? const LinearGradient(colors: [Color(0xFFF5F5F5), Color(0xFFF9F9F9)])
                : null,
            boxShadow: isCurrent
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        item.version,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
                      ),
                      const SizedBox(width: 8),
                      // 상태 칩 (현재, 성공 등)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (isCurrent)
                              Icon(Icons.check_circle, color: item.statusColor, size: 14)
                            else if (item.statusText == "성공")
                              Icon(Icons.check, color: item.statusColor, size: 14)
                            else
                              Icon(Icons.error_outline, color: item.statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              item.statusText,
                              style: TextStyle(
                                color: item.statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(item.deployedAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: _subTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "배포자: ${item.deployer}  커밋: ${item.commitSha}",
                style: theme.textTheme.bodySmall?.copyWith(color: _subTextColor),
              ),
              const SizedBox(height: 4),
              Text(
                item.commitMessage,
                style: theme.textTheme.bodySmall?.copyWith(color: _textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. 하단 액션 버튼 빌더 ---
  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textColor,
                side: BorderSide(color: _borderColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("취소", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              // 선택된 항목이 없거나, 그게 현재 버전이면 비활성화
              onPressed: (_selectedItem == null || _selectedItem!.isCurrentVersion)
                  ? null
                  : () {
                if (_selectedItem != null) {
                  widget.onRollbackConfirmed(_selectedItem!);
                  Navigator.of(context).pop(); // 성공 시 닫기
                }
              },
              icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
              label: const Text("롤백 실행", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dangerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. 하단 정보 바 빌더 ---
  Widget _buildInfoBar(ThemeData theme) {
    // 선택된 항목이 없거나 현재 버전이면 안내 문구 표시
    String infoText;
    if (_selectedItem == null || _selectedItem!.isCurrentVersion) {
      infoText = "롤백할 버전을 선택해주세요.";
    } else {
      // 이미지와 100% 일치하는 동적 텍스트
      infoText = "${_selectedItem!.version} 버전으로 롤백됩니다.";
    }

    return Container(
      width: double.infinity,
      color: _infoBarBgColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Text(
        infoText,
        style: const TextStyle(
          color: _infoBarTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}