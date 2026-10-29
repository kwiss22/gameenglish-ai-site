# GameEnglish AI 홈페이지 + AI 상담 에이전트

홈페이지(`index.html`)와 AI 상담 API(`api/chat.js`)로 이루어진 Vercel 배포용 프로젝트입니다.
방문자가 홈페이지 하단의 채팅창에서 AI와 대화하면, AI가 요구사항·일정·예산·연락처를 물어보며 정리하고 Supabase에 기록합니다.

```
index.html            홈페이지 (에이전트 콘솔 데모 + AI 상담 채팅)
api/chat.js           AI 상담 API — Claude가 응답하고, 대화·문의를 Supabase에 저장
supabase/schema.sql   Supabase 테이블 생성 SQL
```

## 1. Supabase 준비 (5분)

1. supabase.com 에서 새 프로젝트 생성
2. 왼쪽 메뉴 **SQL Editor** → `supabase/schema.sql` 내용 붙여넣기 → **Run**
3. **Project Settings → API** 에서 두 값을 복사
   - `Project URL` → `SUPABASE_URL`
   - `service_role` 키 → `SUPABASE_SERVICE_ROLE_KEY` (이 키는 서버에만 넣고 절대 공개하지 마세요)

## 2. Claude API 키

console.anthropic.com → API Keys 에서 키 발급 → `ANTHROPIC_API_KEY`
사용량 한도(Spend limit)를 꼭 설정해 두세요. 홈페이지가 공개되면 누구나 채팅할 수 있습니다.

## 3. Vercel 배포

1. 이 폴더를 GitHub 저장소로 올리고 Vercel에서 Import (Framework: **Other**, 빌드 설정 없음)
2. **Settings → Environment Variables** 에 추가
   | 이름 | 값 |
   |---|---|
   | `ANTHROPIC_API_KEY` | Claude API 키 |
   | `SUPABASE_URL` | Supabase Project URL |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase service_role 키 |
   | `CLAUDE_MODEL` | (선택) 기본값 `claude-sonnet-5-5`. 비용을 줄이려면 `claude-haiku-5-5` |
3. 환경변수 저장 후 **Redeploy**
4. 도메인 연결: Vercel → Settings → Domains

## 4. 상담 기록 확인

Supabase → **Table Editor**
- `inquiries` — AI가 정리한 문의 (이름, 연락처, 서비스 유형, 요약, 일정, 예산). `status`, `memo` 칸은 담당자가 직접 수정해서 관리
- `conversations` — 모든 대화 원문 (연락처를 남기지 않은 방문자 포함)
- `inquiry_overview` — 문의와 대화 원문을 한 줄에 같이 보는 뷰 (SQL Editor에서 `select * from inquiry_overview;`)

## 5. 바꾸고 싶을 때

- **AI 말투·안내 내용·가격**: `api/chat.js` 의 `SYSTEM_PROMPT`
- **AI가 수집하는 항목**: `api/chat.js` 의 `TOOLS` 와 `supabase/schema.sql` 의 `inquiries` 테이블을 같이 수정
- **첫 인사말·빠른 질문 버튼**: `index.html` 하단 스크립트의 `GREETING`, `#quick` 버튼들
- **빈칸**: `index.html` 에서 `[이메일]`, `[대표자명]`, `[000-00-00000]`, `[신고번호]`, `[사업장 주소]` 검색해서 교체

## 비용·보안 메모

- 상담 1회(10턴 내외) 비용은 Sonnet 기준 대략 수백 원 이하, Haiku로 바꾸면 그보다 훨씬 적습니다. 정확한 단가는 Anthropic 가격표를 확인하고, 콘솔에서 월 한도를 걸어두세요.
- 메시지 길이(2,000자)와 대화 길이(30개)를 서버에서 제한합니다.
- 브라우저에는 어떤 키도 노출되지 않습니다. Supabase는 RLS가 켜져 있어 service_role 키 없이는 읽기·쓰기가 막혀 있습니다.
- 공격적인 반복 호출을 막으려면 Vercel Firewall(Rate limiting) 규칙을 `/api/chat` 에 추가하는 것을 권장합니다.
- 새 문의가 오면 바로 알림을 받고 싶다면 Supabase **Database Webhooks** 로 `inquiries` INSERT 시 이메일·슬랙으로 보내도록 연결할 수 있습니다.
