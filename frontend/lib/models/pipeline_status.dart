import 'plant_model.dart';

// 서버가 보내주는 파이프라인의 전체 상태
class PipelineStatus {
  final String id; // plant.id
  final List<PipelineStep> steps;
  final double overallProgress;
  final String message;
  final bool isFailed; // (★★★★★ 신규 ★★★★★) 실패 상태 플래그

  PipelineStatus({
    required this.id,
    required this.steps,
    required this.overallProgress,
    required this.message,
    this.isFailed = false, // 기본값 false
  });

  // 서버의 JSON (Map<String, dynamic>)을 Dart 객체로 변환하는 factory
  factory PipelineStatus.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List;
    List<PipelineStep> steps = stepsList.map((i) => PipelineStep.fromJson(i)).toList();

    // (수정) isFailed는 서버에서 오지 않으므로 기본값 false
    return PipelineStatus(
      id: json['id'],
      steps: steps,
      overallProgress: (json['overallProgress'] as num).toDouble() / 100.0,
      message: json['message'],
      isFailed: false, // 진행 중인 배포는 false로 간주
    );
  }

  factory PipelineStatus.fromPlant(Plant plant) {
    // 상태 결정
    bool isCompleted = plant.status == 'HEALTHY';
    bool isFailed = plant.status == 'FAILED'; // (★★★★★ 신규 ★★★★★)

    String stepStatus = isCompleted ? 'completed' : (isFailed ? 'failed' : 'pending');
    double stepProgress = isCompleted ? 100 : 0;

    // FAILED 상태는 모든 스텝이 'failed'로 표시되도록
    if (isFailed) {
      stepStatus = 'failed';
    }


    // 이미지에 있던 8개의 스텝 목록을 생성
    final steps = [
      PipelineStep(id: 'git_clone', name: 'Git Clone & Setup', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'ai_analysis', name: 'AI Code Analysis', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'docker_build', name: 'Docker Build', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'ecr_push', name: 'ECR Push', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'infra_update', name: 'Infrastructure Update', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'ecs_deploy', name: 'ECS Deployment', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'health_check', name: 'Health Check', status: stepStatus, progress: stepProgress),
      PipelineStep(id: 'verification', name: 'Verification', status: stepStatus, progress: stepProgress)
    ];

    String message = "배포가 완료되었습니다.";
    if (plant.status == 'SLEEPING') {
      message = "앱이 '겨울잠' 상태입니다.";
    } else if (isFailed) { // (★★★★★ 수정 ★★★★★)
      message = "이전 배포가 실패했습니다.";
    }

    return PipelineStatus(
      id: plant.id,
      steps: steps,
      overallProgress: isCompleted ? 1.0 : 0.0, // (100% 또는 0%)
      message: message,
      isFailed: isFailed, // (★★★★★ 신규 ★★★★★★)
    );
  }
}

// 파이프라인의 각 단계 (Git Clone, Docker Build 등)
class PipelineStep {
  final String id;
  final String name;
  final String status; // 'pending', 'active', 'completed', 'failed'
  final double progress; // (0-100)

  PipelineStep({
    required this.id,
    required this.name,
    required this.status,
    required this.progress,
  });

  // JSON을 Dart 객체로 변환
  factory PipelineStep.fromJson(Map<String, dynamic> json) {
    return PipelineStep(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      progress: (json['progress'] as num).toDouble(),
    );
  }
}