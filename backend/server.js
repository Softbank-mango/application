const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const bodyParser = require('body-parser'); // (신규) Slack 웹훅용

const app = express(); 
app.use(bodyParser.json()); // (신규)
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// --- 가짜 데이터베이스 ---
let nextId = 4;
let shelf = [
  { id: 1, plant: 'rose', version: 'Unicef_dev', description: 'Unicef 본 프로젝트 demo입니다.', status: 'HEALTHY', owner: 'Alex', reactions: ['🎉', '👍'] },
  { id: 2, plant: 'cactus', version: 'poc_app', description: "don't use", status: 'FAILED', owner: 'Sarah', reactions: [] },
  { id: 3, plant: 'sunflower', version: 'CJ_ENM', description: 'CJ ENM 메인 앱', status: 'HEALTHY', owner: 'Alex', reactions: ['❤️'] },
];
let metrics = { cpu: 5.0, mem: 128.0 };
let globalTraffic = ['Tokyo', 'Seoul', 'London', 'San Francisco', 'Singapore'];
const plantTypes = ['rose', 'cactus', 'bonsai', 'sunflower', 'maple', 'cherry_blossom'];

// (신규) 1. "PaaS 겨울잠" 시뮬레이션
setInterval(() => {
  const plantToSleep = shelf.find(p => p.id === 1 && p.status === 'HEALTHY'); // 1번 앱을 대상으로
  if (plantToSleep) {
    console.log('Hibernation: 1번 앱을 "SLEEPING" 상태로 변경합니다.');
    plantToSleep.status = 'SLEEPING';
    io.emit('plant-update', plantToSleep); // UI에 상태 변경 알림
  }
}, 60000); // 1분에 한 번씩 1번 앱을 강제로 재움

io.on('connection', (socket) => {
  console.log('Deplight PaaS UI가 접속했습니다!');
  socket.emit('current-shelf', shelf);
  
  const metricsInterval = setInterval(() => {
    metrics = { cpu: 5.0 + Math.random() * 5, mem: 128.0 + Math.random() * 20 };
    socket.emit('metrics-update', metrics);
  }, 1000);
  
  const trafficInterval = setInterval(() => {
    const location = globalTraffic[Math.floor(Math.random() * globalTraffic.length)];
    const newLog = { time: new Date(), message: `200 OK - /api/ping from ${location}`, status: 'TRAFFIC_HIT' };
    io.emit('new-log', { id: 0, log: newLog });
  }, 1500);

  // 배포 시작 ("새 씨앗 심기" 또는 "앱 깨우기")
  socket.on('start-deploy', (data) => {
    const isWakeUp = data.isWakeUp || false;
    let plant;
    
    if (isWakeUp) { // "겨울잠"에서 깨우기
      plant = shelf.find(p => p.id === data.id);
      if(plant) {
        plant.status = 'DEPLOYING';
        plant.logs = [];
        plant.aiInsight = 'AI가 "겨울잠"에서 깨어나는 중입니다...';
        io.emit('plant-update', plant); // "잠자는 화분" -> "자라나는 중"
      }
    } else { // "새 씨앗 심기"
      plant = {
        id: nextId++, plant: 'pot', version: data.version || `New_App_v1.${nextId-1}`,
        description: data.description || '새 배포입니다...', status: 'DEPLOYING',
        owner: 'You', reactions: [], logs: [], aiInsight: 'AI가 배포를 분석 중입니다...'
      };
      shelf.push(plant);
      io.emit('new-plant', plant);
    }
    
    // (신규) "AI 자가 치유" 배포 시뮬레이션 시작
    runFakeSelfHealingDeploy(socket, plant.id);
  });
  
  socket.on('start-rollback', (data) => {
    const plant = shelf.find(p => p.id === data.id);
    if(plant) runFakeRollback(socket, plant);
  });
  
  socket.on('slack-reaction', (data) => {
    const plant = shelf.find(p => p.id === data.id);
    if (plant) {
      const emoji = data.emoji || '🚀';
      plant.reactions.push(emoji);
      io.emit('reaction-update', { id: data.id, reactions: plant.reactions, emoji: emoji });
    }
  });

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

// (신규) 3. "Slack 주도 배포" (ChatOps) 웹훅
app.post('/webhook/slack-command', (req, res) => {
  console.log('Slack으로부터 "가짜" 배포 명령을 받았습니다!');
  // (실제로는 req.body에서 앱 이름 등을 파싱해야 함)
  
  // (임시) 3번 앱(CJ_ENM)을 강제로 재배포
  const plant = shelf.find(p => p.id === 3);
  if (!plant) return res.status(404).send('Plant not found');
  
  plant.status = 'DEPLOYING';
  plant.logs = [];
  plant.aiInsight = 'AI가 Slack 명령을 분석 중입니다...';
  io.emit('plant-update', plant); // UI의 "장식장"에 즉시 반영
  
  emitLog(io, plant.id, 'SYSTEM', 'Slack @jaeseok 님에 의해 배포가 시작되었습니다.');
  
  // "자가 치유" 배포 시뮬레이션 시작
  runFakeSelfHealingDeploy(io, plant.id); 
  
  res.send('Slack command received. Deployment started.');
});


function emitLog(socket, deployId, status, message, delay = 0) {
  // (이전과 동일)
  const newLog = { time: new Date(), message, status };
  setTimeout(() => {
    if (deployId !== 0) {
        const plant = shelf.find(p => p.id === deployId);
        if(plant && plant.logs) plant.logs.push(newLog);
    }
    io.emit('new-log', { id: deployId, log: newLog }); 
    if (!status.startsWith('CONSOLE') && status !== 'COMMAND' && status !== 'TRAFFIC_HIT') {
       io.emit('status-update', { id: deployId, status, message });
    }
    if (status === 'AI_INSIGHT') {
       io.emit('ai-insight', { id: deployId, message });
    }
  }, delay);
}

// (신규) "AI 자가 치유" 배포 시뮬레이션
function runFakeSelfHealingDeploy(socket, deployId) {
  const plant = shelf.find(p => p.id === deployId);
  if(!plant) return;
  if(!plant.logs) plant.logs = [];
  if(!plant.aiInsight) plant.aiInsight = '...';

  emitLog(socket, deployId, 'linting', '🧐 흙을 고르고 씨앗을 심는 중...', 1000);
  emitLog(socket, deployId, 'testing', '✅ 좋아요! 건강한 새싹이 돋아났어요.', 3000);
  emitLog(socket, deployId, 'building', '📦 쑥쑥! 줄기가 자라고 있어요.', 5000);
  emitLog(socket, deployId, 'deploying', '🚀 Green 버전에 Canary 트래픽 10% 전송...', 7000);
  
  // (신규) 2. "가짜 에러" 발생
  emitLog(socket, deployId, 'TRAFFIC_ERROR', '500 - /api/checkout from Seoul', 9000);
  
  // (신규) 3. "AI"가 감지하고 "자동 롤백"
  emitLog(socket, deployId, 'AI_INSIGHT', '🚨 AI 긴급 경고: Green 버전(v1.2)에서 "결제" 에러율 15% 감지! 즉시 롤백합니다!', 10000);
  
  setTimeout(() => {
    runFakeRollback(socket, plant); // 4. 자동 롤백 함수 호출
  }, 11000);
}

// (수정) "롤백" 시뮬레이션
function runFakeRollback(socket, plant) {
  if(!plant.logs) plant.logs = [];
  plant.aiInsight = 'AI가 롤백을 분석 중입니다...';
  
  emitLog(socket, plant.id, 'ROLLBACK', `🚨 긴급 롤백 시작! ${plant.version} -> (이전 버전) 복구...`, 500);
  emitLog(socket, plant.id, 'ROUTING', '🚦 트래픽을 즉시 Blue(v1.1)로 되돌립니다.', 2000);
  emitLog(socket, plant.id, 'CLEANUP', '🧹 Green(v1.2) 환경을 정리합니다...', 4000);
  emitLog(socket, plant.id, 'done', '✅ 롤백 완료. 서비스가 이전 버전으로 복구되었습니다.', 6000);
  emitLog(socket, plant.id, 'AI_INSIGHT', 'AI 분석: 서비스가 안정적인 이전 버전으로 복구되었습니다.', 6500);

  setTimeout(() => {
    plant.status = 'HEALTHY'; // (롤백 성공)
    plant.plant = 'rose'; 
    plant.version = `${plant.version.split(' (')[0]} (Rolled Back)`;
    io.emit('plant-update', plant); // (신규) plant-complete 대신 plant-update
  }, 6000);
}

server.listen(4000, () => console.log('Deplight "FINAL" 백엔드 서버가 4000번 포트에서 실행 중입니다.'));