// app_state.dart

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'models/plant_model.dart'; // (수정) Plant 모델 import

/// 앱의 글로벌 UI 및 탐색 상태를 관리합니다.
class AppState {
  // --- 싱글톤 ---
  static final AppState instance = AppState._internal();
  factory AppState() => instance;
  AppState._internal();

  // --- 기존 UI 상태 ---
  /// 현재 테마 모드(system, light, dark)
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  /// 현재 언어(locale)
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ko'));

  // --- (신규) AppCore에서 가져온 탐색 상태 ---
  final ValueNotifier<int> currentIndex = ValueNotifier(0);
  final ValueNotifier<String?> selectedWorkspaceId = ValueNotifier(null);
  final ValueNotifier<String> selectedWorkspaceName = ValueNotifier("");
  final ValueNotifier<Plant?> selectedPlant = ValueNotifier(null);

  // --- (신규) 소켓 인스턴스 (UI 상태가 아니므로 Notifier 불필요) ---
  IO.Socket? socket;
  void setSocket(IO.Socket s) {
    socket = s;
  }

  // --- (신규) 페이지 이동 함수 (AppCore의 setState 로직) ---

  void onWorkspaceSelected(String workspaceId, String workspaceName) {
    socket?.emit('join-workspace', workspaceId);
    selectedWorkspaceId.value = workspaceId;
    selectedWorkspaceName.value = workspaceName;
    currentIndex.value = 1; // Shelf
  }

  void showProfilePage() {
    currentIndex.value = 2; // Profile
  }

  void showShelfPage() {
    // (수정) 인덱스를 *먼저* 변경합니다.
    if (selectedWorkspaceId.value == null) {
      currentIndex.value = 0; // WorkspaceSelection
    } else {
      currentIndex.value = 1; // Shelf
    }
    // (수정) 인덱스 변경 *후에* plant를 null로 설정합니다.
    selectedPlant.value = null; // 식물 선택 해제
  }

  void showSettingsPage() {
    currentIndex.value = 3; // Settings
  }

  void goBackToProfile() {
    currentIndex.value = 2; // Profile
  }

  void navigateToDeployment(Plant plant) {
    // (수정) plant를 *먼저* 설정합니다.
    selectedPlant.value = plant;
    // (수정) plant 설정 *후에* 인덱스를 변경합니다.
    currentIndex.value = 4; // Deployment
  }

  void goBackToWorkspaceSelection() {
    selectedWorkspaceId.value = null;
    selectedWorkspaceName.value = "";
    currentIndex.value = 0; // WorkspaceSelection
  }
}