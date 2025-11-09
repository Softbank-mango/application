// widgets/deploy_modal.dart (수정된 코드)

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

// (★★★★★ 임포트 경로 확인 및 수정 ★★★★★)
import '../app_state.dart';
import '../models/plant_model.dart'; // Plant 모델 임포트 (경로 확인 필요)
import '../models/pipeline_status.dart'; // PipelineStatus 모델 임포트 (경로 확인 필요)
// import 'widgets/pipeline_monitor.dart'; // PipelineMonitor 위젯 (호출 시 필요)


class DeployModal extends StatefulWidget {
  final Plant plant;
  // final SocketService socketService; // ◀ 삭제됨

  const DeployModal({
    Key? key,
    required this.plant,
    // required this.socketService, // ◀ 삭제됨
  }) : super(key: key);

  // AppCore에서 호출 시 사용
  static void show(BuildContext context, Plant plant) { // (★★★★★ socketService 제거 ★★★★★)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (deployCtx) {
        return DeployModal(plant: plant);
      },
    );
  }

  @override
  State<DeployModal> createState() => _DeployModalState();
}

class _DeployModalState extends State<DeployModal> {
  // --- 상태 변수 ---
  late PipelineStatus _status;
  late final String _deployId;
  final List<dynamic> _logs = [];

  // (★★★★★ 수정: AppState에서 소켓 인스턴스를 직접 가져옵니다 ★★★★★)
  final Socket? socket = AppState.instance.socket;
  final AppState appState = AppState.instance;


  @override
  void initState() {
    super.initState();
    _deployId = widget.plant.id;

    // Plant 데이터를 기반으로 초기 PipelineStatus 생성 (기본값 설정)
    _status = PipelineStatus.fromPlant(widget.plant);

    // 소켓 연결 상태 확인 후 리스너 설정
    if (socket != null && socket!.connected) {
      _setupSocketListeners();
    } else {
      // 소켓이 연결되지 않았다면 오류 메시지 표시
      print("DeployModal Error: Socket is not connected.");
    }
  }

  void _setupSocketListeners() {
    // 1. 파이프라인 업데이트 리스너 ('pipeline-update')
    socket!.on('pipeline-update', (data) {
      if (data['id'] == _deployId && mounted) {
        setState(() {
          _status = PipelineStatus.fromJson(data);
        });
      }
    });

    // 2. 로그 업데이트 리스너 ('new-log')
    socket!.on('new-log', (data) {
      if (data['id'] == _deployId || data['id'] == 0) {
        setState(() {
          _logs.add(data['log']);
        });
      }
    });

    // 3. 완료/종료 리스너 ('pipeline-complete' 또는 'rollback-required')
    socket!.on('pipeline-complete', (data) {
      if (data['id'] == _deployId) {
        _handleCompletion(data['status']);
      }
    });

    socket!.on('rollback-required', (data) {
      if (data['id'] == _deployId) {
        _handleCompletion('FAILED'); // 실패 상태로 간주하고 닫기 로직 실행
      }
    });
  }

  void _handleCompletion(String status) {
    // 최종 상태를 받은 후 모달을 닫고, 필요하다면 해당 Plant 페이지로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        // (완료 후 상세 모니터링 페이지로 이동하는 로직이 필요하면 여기에 추가)
      }
    });
  }

  @override
  void dispose() {
    // (중요) 메모리 누수를 막기 위해 연결 해제 시 소켓 리스너를 반드시 끄세요.
    socket?.off('pipeline-update');
    socket?.off('new-log');
    socket?.off('pipeline-complete');
    socket?.off('rollback-required');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // (PipelineMonitor 위젯은 임시로 주석 처리하고, 상태 객체만 전달)

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: PopScope(
        canPop: false,
        child: Container(
          width: screenSize.width * 0.8,
          height: screenSize.height * 0.9,

          // 여기에 PipelineMonitor와 LogConsole을 배치합니다.
          child: Row(
            children: [
              // 1. 왼쪽: Pipeline Monitor (70%)
              Expanded(
                flex: 7,
                child: Center(
                  // (실제 PipelineMonitor 위젯 호출)
                  child: Text("Pipeline Monitor: ${_status.overallProgress * 100}%", style: TextStyle(color: Colors.black)),
                ),
              ),
              // 2. 오른쪽: 실시간 로그 콘솔 (30%)
              Expanded(
                flex: 3,
                child: _buildLogConsole(), // (아래에서 정의)
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 로그 콘솔 위젯 (간소화) ---
  Widget _buildLogConsole() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM LOGS',
            style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(color: Color(0xFF374151)),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[_logs.length - 1 - index];
                final time = DateTime.parse(log['time']).toString().substring(11, 19);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '[$time] ${log['status']} - ${log['message']}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}