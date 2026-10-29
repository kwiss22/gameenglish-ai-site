-- GameEnglish AI 상담 기록용 테이블
-- 기존 Supabase 프로젝트에 함께 넣어도 겹치지 않도록 모든 이름에 ge_ 접두사를 붙였습니다.
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 Run (여러 번 실행해도 안전)

-- 1) 대화 전체 기록 (세션 1개 = 행 1개, 대화가 이어질 때마다 갱신)
create table if not exists public.ge_conversations (
  id            text primary key,              -- 브라우저 세션 ID
  messages      jsonb not null default '[]',   -- [{role, content}, ...]
  message_count int   not null default 0,
  user_agent    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2) 정리된 문의 (AI가 연락처·요구사항을 확보하면 기록)
create table if not exists public.ge_inquiries (
  id              bigint generated always as identity primary key,
  conversation_id text not null unique references public.ge_conversations(id) on delete cascade,
  name            text,
  contact         text,
  service_type    text,
  summary         text,
  timeline        text,
  budget          text,
  status          text not null default '신규',   -- 신규 / 연락함 / 견적 발송 / 계약 / 보류
  memo            text,                          -- 담당자 메모
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists ge_inquiries_created_at_idx on public.ge_inquiries (created_at desc);
create index if not exists ge_conversations_updated_at_idx on public.ge_conversations (updated_at desc);

-- 3) 보안: RLS를 켜고 정책은 만들지 않음
--    → 브라우저(anon 키)로는 읽기/쓰기 불가, 서버의 service_role 키만 접근 가능
alter table public.ge_conversations enable row level security;
alter table public.ge_inquiries     enable row level security;

-- 4) 담당자용 보기: 문의 + 대화 원문을 한 번에
create or replace view public.ge_inquiry_overview
with (security_invoker = true) as
select
  i.created_at,
  i.status,
  i.name,
  i.contact,
  i.service_type,
  i.summary,
  i.timeline,
  i.budget,
  c.message_count,
  c.messages,
  i.conversation_id
from public.ge_inquiries i
left join public.ge_conversations c on c.id = i.conversation_id
order by i.created_at desc;
