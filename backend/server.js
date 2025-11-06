const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const bodyParser = require('body-parser');
const path = require('path');
const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  // Cloud Run 환경: 자동으로 기본 인증 정보 사용 (파일 필요 없음)
  admin.initializeApp();
}

// Firestore DB 인스턴스
const db = admin.firestore();

const app = express();
app.use(bodyParser.json());

// 2. API 및 Webhook 라우트 (기존 로직 유지 - 'CJ_ENM' 앱을 직접 찾음)
app.post('/webhook/slack-command', async (req, res) => {
  try {
    const plantQuery = await db.collection('plants').where('version', '==', 'CJ_ENM').limit(1).get();
    if (plantQuery.empty) return res.status(404).send('Plant not found');
    
    const plantDoc = plantQuery.docs[0];
    const plantRef = plantDoc.ref;
    const plantData = plantDoc.data();
    
    if (plantData.status === 'DEPLOYING' || plantData.status === 'ROLLBACK') {
      return res.status(409).send('Action already in progress.');
    }
    
    await plantRef.update({ status: 'DEPLOYING', aiInsight: 'AI가 Slack 명령을 분석 중입니다...' });
    io.emit('plant-update', { id: plantDoc.id, status: 'DEPLOYING', aiInsight: 'AI가 Slack 명령을 분석 중입니다...' });
    emitLog(plantDoc.id, 'SYSTEM', 'Slack 명령에 의해 배포 시작');
    runFakeSelfHealingDeploy(plantDoc.id, false);
    res.send('Slack command received. Deployment started.');
  } catch (err) {
    console.error("Slack Webhook Error:", err);
    res.status(500).send('Internal Server Error');
  }
});

// 3. Flutter Web 빌드 결과 정적 경로
app.use(express.static(path.join(__dirname, '../frontend/build/web')));

// 4. "catch-all" 라우트
app.get(/(.*)/, (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/build/web/index.html'));
});

// --- Socket.io 서버 생성 ---
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// (★★★★★ 수정 ★★★★★: "PaaS 겨울잠" 시뮬레이션 - 'Unicef_dev' 앱을 직접 찾음)
setInterval(async () => {
  try {
    const query = db.collection('plants')
      .where('version', '==', 'Unicef_dev')
      .where('status', '==', 'HEALTHY');
      
    const snapshot = await query.get();
    if (snapshot.empty) return;

    snapshot.forEach(doc => {
      doc.ref.update({ status: 'SLEEPING', updatedAt: new Date() });
      console.log(`Hibernation: ${doc.id} 앱을 "SLEEPING" 상태로 변경합니다.`);
      
      // (중요) 해당 plant가 속한 workspaceId를 가져와서 '그 방'에만 알림
      const workspaceId = doc.data().workspaceId;
      if(workspaceId) {
        io.to(workspaceId).emit('plant-update', { id: doc.id, status: 'SLEEPING' });
      }
    });
  } catch (err) {
    console.error("Hibernation Error:", err);
  }
}, 60000);

// Socket.io 연결 미들웨어: (토큰 검증 - 수정 없음)
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication Error: No token provided'));
    const decodedToken = await admin.auth().verifyIdToken(token);
    socket.user = decodedToken; 
    next(); 
  } catch (err) {
    console.error('Socket Auth Error:', err.message);
    next(new Error('Authentication Error')); 
  }
});

// (★★★★★ 수정 ★★★★★: 'connection' 로직 전체 변경)
io.on('connection', (socket) => {
  console.log(`[${socket.user.email}] 님이 접속했습니다. (UID: ${socket.user.uid})`);
  const userUid = socket.user.uid;
  
  // 현재 이 소켓이 구독 중인 Firestore 리스너(onSnapshot)를 저장할 변수
  let unsubscribeShelfListener = null;

  // (신규) 1. 클라이언트가 "내가 속한 워크스페이스 목록 줘" 요청
  socket.on('get-my-workspaces', async () => {
    try {
      // 'members' 배열에 내 UID가 포함된 워크스페이스 쿼리
      const query = db.collection('workspaces').where('members', 'array-contains', userUid);
      const snapshot = await query.get();
      const workspaces = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // 'WorkspaceSelectionPage'에 표시할 목록 전송
      socket.emit('workspaces-list', workspaces);
    } catch(err) {
      console.error('Error getting workspaces:', err);
      socket.emit('error-message', '워크스페이스 목록 로딩 실패');
    }
  });

  // (신규) 2. 클라이언트가 "이 워크스페이스에 들어갈래" 요청
  socket.on('join-workspace', async (workspaceId) => {
    try {
      // (보안) 이 사용자가 이 워크스페이스의 멤버인지 확인
      const wsDoc = await db.collection('workspaces').doc(workspaceId).get();
      if (!wsDoc.exists || !wsDoc.data().members.includes(userUid)) {
        return socket.emit('error-message', '워크스페이스 접근 권한이 없습니다.');
      }

      // 1. (중요) 이 사용자를 'workspaceId' 이름을 가진 방(Room)에 입장시킴
      socket.join(workspaceId);
      console.log(`[${socket.user.email}] 님이 '${wsDoc.data().name}' 워크스페이스(${workspaceId})에 입장했습니다.`);

      // 2. 이 방에 입장하는 즉시, 이 방에 해당하는 Plant 목록을 실시간(onSnapshot) 감시
      const query = db.collection('plants').where('workspaceId', '==', workspaceId);
      
      // 3. (중요) onSnapshot으로 실시간 감시 시작
      unsubscribeShelfListener = query.onSnapshot(snapshot => {
          const plants = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
          
          // (중요) 'io.emit' (전체)이 아닌 'to(workspaceId)' (이 방에만) 전송
          io.to(workspaceId).emit('current-shelf', plants);
      }, err => {
          console.error(`Shelf Snapshot Error (WS: ${workspaceId}):`, err);
          socket.emit('error-message', '앱 목록을 불러오는 데 실패했습니다.');
      });

    } catch(err) {
      console.error('Error joining workspace:', err);
    }
  });

  // (수정) 3. 'start-deploy' - workspaceId를 받아야 함
  socket.on('start-deploy', async (data) => {
    const { workspaceId, isWakeUp, id: plantIdToWake } = data; // (workspaceId를 받음)

    // (보안) 이 사용자가 이 워크스페이스의 멤버인지 확인 (필수)
    const wsDoc = await db.collection('workspaces').doc(workspaceId).get();
    if (!wsDoc.exists || !wsDoc.data().members.includes(userUid)) {
      return emitLog(0, 'SYSTEM_ERROR', '배포 권한이 없습니다.', 0, socket);
    }

    if (isWakeUp) {
      // "겨울잠" 깨우기
      const plantRef = db.collection('plants').doc(plantIdToWake);
      const doc = await plantRef.get();
      // (보안) 이 plant가 요청한 workspace에 속해있는지 확인
      if (!doc.exists || doc.data().workspaceId !== workspaceId) {
        return emitLog(0, 'SYSTEM_ERROR', '앱을 찾을 수 없습니다.', 0, socket);
      }
      
      await plantRef.update({ status: 'DEPLOYING', aiInsight: 'AI가 "겨울잠"에서 깨어나는 중입니다...', updatedAt: new Date() });
      // (onSnapshot 리스너가 자동 감지)
      runFakeSelfHealingDeploy(plantIdToWake, true); // (true: wakeUp)

    } else {
      // "새 씨앗 심기" (새 문서 생성)
      const newPlant = {
        workspaceId: workspaceId, // (★★★★★) 워크스페이스 ID 저장
        ownerUid: userUid, // 배포를 '시작한' 사용자 저장
        plantType: 'pot',
        version: data.version || `New_App_v1`,
        description: data.description || '새 배포입니다...',
        status: 'DEPLOYING',
        reactions: [],
        aiInsight: 'AI가 배포를 분석 중입니다...',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      
      const docRef = await db.collection('plants').add(newPlant);
      
      // (onSnapshot 리스너가 자동 감지하지만, Flutter의 페이지 이동 트리거를 위해 '보낸 사람'에게만 전송)
      socket.emit('new-plant', { id: docRef.id, ...newPlant });
      runFakeSelfHealingDeploy(docRef.id, false); // (false: new deploy)
    }
  });

  // (수정) 4. 'start-rollback' - 보안 강화
  socket.on('start-rollback', async (data) => {
    const plantRef = db.collection('plants').doc(data.id);
    const doc = await plantRef.get();

    // (보안) plant가 없거나, 멤버가 아닌 workspace의 plant를 롤백 시도 시 거부
    if (!doc.exists) return emitLog(0, 'SYSTEM_ERROR', '앱을 찾을 수 없습니다.', 0, socket);
    const wsDoc = await db.collection('workspaces').doc(doc.data().workspaceId).get();
    if (!wsDoc.exists || !wsDoc.data().members.includes(userUid)) {
      return emitLog(0, 'SYSTEM_ERROR', '롤백 권한이 없습니다.', 0, socket);
    }
    
    const plantData = { id: doc.id, ...doc.data() };
    if (plantData.status === 'DEPLOYING' || plantData.status === 'ROLLBACK') {
      return emitLog(plantData.id, 'SYSTEM_ERROR', '이미 다른 작업이 진행 중입니다.', 0, socket);
    }
    runFakeRollback(plantData);
  });

  // (수정) 5. 'slack-reaction' - 방(Room)에 전파
  socket.on('slack-reaction', async (data) => {
    const plantRef = db.collection('plants').doc(data.id);
    const emoji = data.emoji || '🚀';
    try {
      await plantRef.update({ reactions: admin.firestore.FieldValue.arrayUnion(emoji) });
      const updatedDoc = await plantRef.get();
      const plantData = updatedDoc.data();
      
      // (★★★★★) 이 plant가 속한 workspaceId를 가져와서 '그 방'에만 전파
      if(plantData.workspaceId) {
        io.to(plantData.workspaceId).emit('reaction-update', { id: data.id, reactions: plantData.reactions, emoji });
      }
    } catch(err) { console.error("Reaction update error:", err); }
  });

  // (수정) 6. 전역 이벤트들 (metrics, traffic, run-command) - 전체(io) 또는 개인(socket)에게 전송
  const globalTrafficSources = ['Tokyo', 'Seoul', 'London', 'San Francisco', 'Singapore'];
  const globalRef = db.collection('system').doc('global');
  
  const metricsInterval = setInterval(() => {
    const newMetrics = { cpu: 5.0 + Math.random() * 5, mem: 128.0 + Math.random() * 20 };
    globalRef.set({ currentMetrics: newMetrics }, { merge: true });
    io.emit('metrics-update', newMetrics); // (전체 전송)
  }, 1000);

  const trafficInterval = setInterval(() => {
    const location = globalTrafficSources[Math.floor(Math.random() * globalTrafficSources.length)];
    const newLog = { time: new Date(), message: `200 OK - /api/ping from ${location}`, status: 'TRAFFIC_HIT' };
    globalRef.collection('globalLogs').add(newLog);
    io.emit('new-log', { id: 0, log: newLog }); // (전체 전송)
  }, 1500);

  socket.on('run-command', (cmd) => {
    emitLog(0, 'COMMAND', cmd, 0, socket); // (개인에게만 전송)
    setTimeout(() => {
      let response = `zsh: command not found: ${cmd}`;
      let status = 'CONSOLE_ERROR';
      if (cmd.startsWith('kubectl get pods')) {
        status = 'CONSOLE';
        response = `(모든 파드 목록...)\ndeplight-v1-blue-pod-abc12   1/1     Running\n...`;
      }
      emitLog(0, status, response, 0, socket); // (개인에게만 전송)
    }, 1000);
  });

  // (수정) 7. 연결 종료 시 Firestore 리스너 해제
  socket.on('disconnect', () => {
    if (unsubscribeShelfListener) {
      unsubscribeShelfListener(); // (중요) 실시간 리스너 중지
    }
    clearInterval(metricsInterval);
    clearInterval(trafficInterval);
    console.log(`[${socket.user.email}] 님이 접속 종료했습니다.`);
  });
});


// (★★★★★ 수정 ★★★★★: emitLog - Firestore 서브컬렉션에 로그 저장)
async function emitLog(deployId, status, message, delay = 0, socket = null) {
  const newLog = { 
    time: new Date(), 
    message, 
    status 
  };
  
  setTimeout(async () => {
    if (deployId !== 0) {
      try {
        await db.collection('plants').doc(deployId).collection('logs').add(newLog);
      } catch (e) { console.error("Log write error:", e); }
    }
    
    // socket이 있으면 socket(개인)에게, 없으면 io(전체)에게 전송
    const emitter = socket || io; 
    emitter.emit('new-log', { id: deployId, log: newLog }); 
    
    // (수정) 상태 업데이트는 해당 plant가 속한 '방(Room)'에만 전송
    if (!status.startsWith('CONSOLE') && status !== 'COMMAND' && status !== 'TRAFFIC_HIT') {
      if(deployId !== 0) {
        try {
          const doc = await db.collection('plants').doc(deployId).get();
          const workspaceId = doc.data().workspaceId;
          if(workspaceId) {
            io.to(workspaceId).emit('status-update', { id: deployId, status, message });
          }
        } catch(e) {}
      }
    }
    if (status === 'AI_INSIGHT') {
      if(deployId !== 0) {
        try {
          const doc = await db.collection('plants').doc(deployId).get();
          const workspaceId = doc.data().workspaceId;
          if(workspaceId) {
            io.to(workspaceId).emit('ai-insight', { id: deployId, message });
          }
        } catch(e) {}
      }
    }
  }, delay);
}

// (★★★★★ 수정 ★★★★★: run... Deploy/Rollback - Firestore 업데이트)
// (내부 로직은 이전과 동일 - DB를 업데이트하면 onSnapshot 리스너가 자동 감지)
async function runFakeSelfHealingDeploy(deployId, isWakeUp = false) {
  const plantRef = db.collection('plants').doc(deployId);

  emitLog(deployId, 'linting', '🧐 흙을 고르고 씨앗을 심는 중...', 1000);
  emitLog(deployId, 'testing', '✅ 새싹이 돋아났어요.', 3000);
  emitLog(deployId, 'building', '📦 줄기가 자라고 있어요.', 5000);
  emitLog(deployId, 'deploying', '🚀 Canary 트래픽 10% 전송...', 7000);

  if (isWakeUp) {
    emitLog(deployId, 'done', '✅ 배포 성공! 겨울잠에서 깨어났습니다.', 9000);
    emitLog(deployId, 'AI_INSIGHT', '서비스 안정화 완료', 9500);
    setTimeout(async () => {
      await plantRef.update({ status: 'HEALTHY', plantType: 'rose', updatedAt: new Date() });
    }, 9000);
  } else {
    emitLog(deployId, 'TRAFFIC_ERROR', '500 - /api/checkout', 9000);
    emitLog(deployId, 'AI_INSIGHT', '🚨 에러 감지! 자동 롤백 시작...', 10000);
    setTimeout(async () => {
      const doc = await plantRef.get();
      if(doc.exists) runFakeRollback({ id: doc.id, ...doc.data() });
    }, 11000);
  }
}

async function runFakeRollback(plant) { 
  const plantId = plant.id;
  const plantRef = db.collection('plants').doc(plantId);

  await plantRef.update({ status: 'ROLLBACK', aiInsight: 'AI가 롤백을 분석 중입니다...', updatedAt: new Date() });

  emitLog(plant.id, 'ROLLBACK', `🚨 롤백 시작! ${plant.version} -> 이전 버전`, 500);
  emitLog(plant.id, 'ROUTING', '🚦 트래픽 Blue로 전환', 2000);
  emitLog(plant.id, 'CLEANUP', '🧹 Green 환경 정리', 4000);
  emitLog(plant.id, 'done', '✅ 롤백 완료', 6000);
  emitLog(plant.id, 'AI_INSIGHT', '서비스 안정화 완료', 6500);

  setTimeout(async () => {
    const newVersion = `${plant.version.split(' (')[0]} (Rolled Back)`;
    await plantRef.update({
      status: 'HEALTHY',
      plantType: 'rose', 
      version: newVersion,
      updatedAt: new Date()
    });
  }, 6000);
}

// Cloud Run 포트 사용
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => console.log(`Deplight 서버 실행: ${PORT}번 포트`));