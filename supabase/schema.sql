-- GameEnglish AI 상담 기록용 테이블
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 Run

-- 1) 대화 전체 기록 (세션 1개 = 행 1개, 대화가 이어질 때마다 갱신)
create table if not exists public.conversations (
  id            text primary key,              -- 브라우저 세션 ID
  messages      jsonb not null default '[]',   -- [{role, content}, ...]
  message_count int   not null default 0,
  user_agent    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2) 정리된 문의 (AI가 연락처·요구사항을 확보하면 기록)
create table if not exists public.inquiries (
  id              bigint generated always as identity primary key,
  conversation_id text not null unique references public.conversations(id) on delete cascade deferrable initially deferred,
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

create index if not exists inquiries_created_at_idx on public.inquiries (created_at desc);
create index if not exists conversations_updated_at_idx on public.conversations (updated_at desc);

-- 3) 보안: RLS를 켜고 정책은 만들지 않음
--    → 브라우저(anon 키)로는 읽기/쓰기 불가, 서버의 service_role 키만 접근 가능
alter table public.conversations enable row level security;
alter table public.inquiries     enable row level security;

-- 4) 담당자용 보기: 문의 + 대화 원문을 한 번에
create or replace view public.inquiry_overview
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
from public.inquiries i
left join public.conversations c on c.id = i.conversation_id
order by i.created_at desc;
