const { z } = require('zod');

// 1. 새 워크스페이스 생성 스키마 (NewWorkspaceDialog)
const createWorkspaceSchema = z.object({
  name: z.string().min(1, "이름은 필수입니다."),
  description: z.string().min(1, "설명은 필수입니다."),
  type: z.enum(['development', 'operations'], "잘못된 유형입니다."), // '개발' 또는 '운영'
});

// 2. 새 앱 배포 스키마 (NewDeploymentDialog)
const startDeploySchema = z.object({
  workspaceId: z.string().min(5), // Firestore ID (간단히 검사)
  gitUrl: z.string().url("유효한 URL이 아닙니다."), // URL 형식 검사
  version: z.string().optional(), // '앱 이름' (선택)
  description: z.string().optional(), // (선택)
});

// 3. 새 시크릿 추가 스키마 (NewSecretDialog)
// (이 핸들러는 아직 server.js에 없지만, 미리 정의)
const addSecretSchema = z.object({
  workspaceId: z.string().min(5),
  name: z.string()
    .min(1)
    .regex(/^[A-Z_][A-Z0-9_]*$/, "환경 변수 이름 형식이 아닙니다 (예: DATABASE_URL)."),
  value: z.string().min(1, "값은 필수입니다."),
  
  // 프론트엔드에서 null을 보낼 수 있고, 값이 없어도 되도록 수정
  description: z.string().nullable().optional(), 
  
  // .nullable() 은 null 값을 허용하고,
  // .optional() 은 아예 필드가 존재하지 않아도 허용합니다.
  // 프론트에서 명시적으로 null을 보내므로 .nullable()이 필수입니다.
});

// 4. 롤백 스키마 (RollbackDialog)
const startRollbackSchema = z.object({
  plantId: z.string().min(5),
  // (롤백할 버전 ID 등 추가 데이터가 필요하면 여기에 추가)
});

// 시크릿 삭제 스키마
const deleteSecretSchema = z.object({
  workspaceId: z.string().min(5),
  name: z.string().min(1, "삭제할 Secret 이름은 필수입니다."),
});

// 시크릿 수정 스키마
const updateSecretSchema = z.object({
  workspaceId: z.string().min(5),
  name: z.string().min(1),
  value: z.string().min(1, "새 값은 필수입니다."),
});


module.exports = {
  createWorkspaceSchema,
  startDeploySchema,
  addSecretSchema,
  startRollbackSchema,
  deleteSecretSchema, 
  updateSecretSchema,
};