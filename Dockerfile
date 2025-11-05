# Node.js 18 slim 버전 사용 (경량 + 최신 LTS)
FROM node:18-slim

# 1️⃣ 작업 디렉토리 설정
WORKDIR /usr/src/app

# 2️⃣ backend 의존성 설치 (캐시 효율을 위해 package.json만 복사)
COPY backend/package*.json ./backend/
RUN cd backend && npm install --production

# 3️⃣ backend 전체 복사
COPY backend ./backend

# 4️⃣ Flutter Web 빌드 결과 복사
COPY frontend/build/web ./frontend/build/web

# 5️⃣ 환경 변수 설정
ENV NODE_ENV=production
ENV PORT=8080

# 6️⃣ 포트 개방
EXPOSE 8080

# 7️⃣ 서버 실행 (backend/server.js 기준)
WORKDIR /usr/src/app/backend
CMD ["node", "server.js"]
