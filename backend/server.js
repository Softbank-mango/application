const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const app = express(); const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// --- 가짜 데이터베이스 ---
let nextId = 4;
// "장식장" 데이터 (핵심) - 이미지 2.png의 "Unicef", "poc_app" 포함
let shelf = [
  { id: 1, plant: 'rose', version: 'Unicef_dev', description: 'Unicef 본 프로젝트 demo입니다.', status: 'HEALTHY', owner: 'Alex', reactions: ['🎉', '👍'] },
  { id: 2, plant: 'cactus', version: 'poc_app', description: "don't use", status: 'FAILED', owner: 'Sarah', reactions: [] },
  { id: 3, plant: 'sunflower', version: 'CJ_ENM', description: 'CJ ENM 메인 앱', status: 'HEALTHY', owner: 'Alex', reactions: ['❤️'] },
];
let metrics = { cpu: 5.0, mem: 128.0 };
let globalTraffic = ['Tokyo', 'Seoul', 'London', 'San Francisco', 'Singapore'];
const plantTypes = ['rose', 'cactus', 'bonsai', 'sunflower', 'maple', 'cherry_blossom']; // (신규) 식물 수집용

io.on('connection', (socket) => {
  console.log('Deplight PaaS UI가 접속했습니다!');
  // 접속 즉시 "장식장" 데이터 전송
  socket.emit('current-shelf', shelf);
  
  // 1초마다 가짜 매트릭 전송
  const metricsInterval = setInterval(() => {
    metrics = { cpu: 5.0 + Math.random() * 5, mem: 128.0 + Math.random() * 20 };
    socket.emit('metrics-update', metrics);
  }, 1000);
  
  // 1.5초마다 가짜 글로벌 트래픽 전송
  const trafficInterval = setInterval(() => {
    const location = globalTraffic[Math.floor(Math.random() * globalTraffic.length)];
    const newLog = { time: new Date(), message: `200 OK - /api/ping from ${location}`, status: 'TRAFFIC_HIT' };
    io.emit('new-log', { id: 0, log: newLog }); // id 0: 글로벌 로그
  }, 1500);

  // 배포 시작 ("새 씨앗 심기")
  socket.on('start-deploy', (data) => {
    // 1. 새 화분을 장식장에 추가하고 전파
    const newPlant = {
      id: nextId++,
      plant: 'pot', // "pot.json" (빈 화분)
      version: data.version || `New_App_v1.${nextId-1}`, // (신규) 버전명 수신
      description: data.description || '새 배포입니다...',
      status: 'DEPLOYING',
      owner: 'You',
      reactions: []
    };
    shelf.push(newPlant);
    io.emit('new-plant', newPlant); // 모든 UI에 새 화분 추가 알림
    
    // 2. 배포 시뮬레이션 시작
    runFakeK8sDeployment(socket, newPlant.id);
  });
  
  // (신규) 롤백 시작
  socket.on('start-rollback', (data) => {
    console.log(`UI로부터 롤백 명령 받음: ${data.id}`);
    const plant = shelf.find(p => p.id === data.id);
    if(plant) runFakeRollback(socket, plant);
  });
  
  // (신규) Slack 반응 시뮬레이션
  socket.on('slack-reaction', (data) => {
    const plant = shelf.find(p => p.id === data.id);
    if (plant) {
      const emoji = data.emoji || '🚀';
      plant.reactions.push(emoji);
      // "장식장"의 특정 식물에 반응이 추가되었음을 알림
      io.emit('reaction-update', { id: data.id, reactions: plant.reactions, emoji: emoji });
    }
  });

  // "가짜 콘솔" 명령어 리스너
  socket.on('run-command', (cmd) => {
      emitLog(socket, 0, 'COMMAND', cmd, 0); 
      setTimeout(() => {
        let response = `zsh: command not found: ${cmd}`; let status = 'CONSOLE_ERROR';
        if (cmd.startsWith('kubectl get pods')) { status = 'CONSOLE'; response = `(모든 파드 목록...)\ndeplight-v1-blue-pod-abc12   1/1     Running   0   3h\ndeplight-v2-green-pod-xyz78   1/1     Running   0   1m`; }
        emitLog(socket, 0, status, response, 0);
      }, 1000);
  });

  socket.on('disconnect', () => {
    clearInterval(metricsInterval);
    clearInterval(trafficInterval);
  });
});

// 로그/상태 전송 (특정 배포 ID에 대한)
function emitLog(socket, deployId, status, message, delay = 0) {
  const newLog = { time: new Date(), message, status };
  setTimeout(() => {
    if (deployId !== 0) { // 0번(글로벌)이 아닌 특정 배포 로그일 때
        const plant = shelf.find(p => p.id === deployId);
        if(plant && plant.logs) plant.logs.push(newLog); // 서버에도 로그 저장
    }
    io.emit('new-log', { id: deployId, log: newLog }); 
    // 메인 상태 (나무 키우기)도 ID별로 전송
    if (!status.startsWith('CONSOLE') && status !== 'COMMAND' && status !== 'TRAFFIC_HIT') {
       io.emit('status-update', { id: deployId, status, message });
    }
    // AI 인사이트도 ID별로 전송
    if (status === 'AI_INSIGHT') {
       io.emit('ai-insight', { id: deployId, message });
    }
  }, delay);
}

// 가짜 배포 시뮬레이션
function runFakeK8sDeployment(socket, deployId) {
  const plant = shelf.find(p => p.id === deployId);
  if(!plant) return;
  plant.logs = []; // 로그 초기화
  plant.aiInsight = 'AI가 배포를 분석 중입니다...';
  
  emitLog(socket, deployId, 'linting', '🧐 흙을 고르고 씨앗을 심는 중...', 1000);
  // (매트릭 상승 시뮬레이션 - 생략)
  emitLog(socket, deployId, 'testing', '✅ 좋아요! 건강한 새싹이 돋아났어요.', 3000);
  emitLog(socket, deployId, 'building', '📦 쑥쑥! 줄기가 자라고 있어요.', 5000);
  emitLog(socket, deployId, 'deploying', '🚀 잎이 무성해지는 중... (Green 배포)', 8000);
  emitLog(socket, deployId, 'routing', '🚦 두근두근... 꽃이 피기 직전이에요!', 11000);
  emitLog(socket, deployId, 'done', '✨ 완벽해요! 예쁜 꽃이 피었어요!', 13000);
  emitLog(socket, deployId, 'AI_INSIGHT', 'AI 분석: k6 테스트 통과. v1.1이 v1.0 대비 응답속도 12% 향상.', 13500);

  // 장식장의 식물을 "완성"시킴
  setTimeout(() => {
    plant.status = 'HEALTHY';
    plant.plant = plantTypes[Math.floor(Math.random() * plantTypes.length)]; // (신규) 랜덤 식물
    io.emit('plant-complete', plant); // "장식장" 업데이트
  }, 13000);
}

// (신규) 가짜 롤백 시뮬레이션
function runFakeRollback(socket, plant) {
  plant.logs = []; // 로그 초기화
  plant.aiInsight = 'AI가 롤백을 분석 중입니다...';
  
  emitLog(socket, plant.id, 'ROLLBACK', `🚨 긴급 롤백 시작! ${plant.version} -> (이전 버전) 복구...`, 500);
  emitLog(socket, plant.id, 'ROUTING', '🚦 트래픽을 즉시 Blue(v1.1)로 되돌립니다.', 2000);
  emitLog(socket, plant.id, 'CLEANUP', '🧹 Green(v1.2) 환경을 정리합니다...', 4000);
  emitLog(socket, plant.id, 'done', '✅ 롤백 완료. 서비스가 이전 버전으로 복구되었습니다.', 6000);
  emitLog(socket, plant.id, 'AI_INSIGHT', 'AI 분석: 서비스가 안정적인 이전 버전으로 복구되었습니다.', 6500);

  setTimeout(() => {
    plant.status = 'HEALTHY';
    plant.plant = 'rose'; // (예시) 이전 버전의 식물로 되돌림
    plant.version = `${plant.version.split(' (')[0]} (Rolled Back)`;
    io.emit('plant-complete', plant);
  }, 6000);
}

// (가짜 실패 시뮬레이션 - runFakeK8sDeployment와 유사하게 구현)
function runFakeFail(socket, deployId) {
    // (이전 버전의 runFakeFail 코드와 동일, deployId만 추가)
}

// (가짜 콘솔 응답 - 이전 버전과 동일)
function runFakeConsole(socket, cmd) {
    // (이전 버전의 runFakeConsole 코드와 동일)
}

server.listen(4000, () => console.log('Deplight "FINAL" 백엔드 서버가 4000번 포트에서 실행 중입니다.'));