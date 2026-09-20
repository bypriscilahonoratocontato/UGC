-- ============================================================
-- REFERENCIAS DE VIDEO
--
-- Rode este arquivo uma vez no Supabase, em SQL Editor,
-- New query, colar tudo, Run.
--
-- Ele so cria a lista nova de referencias e a tranca dela.
-- Nao mexe em nada que ja existe no seu painel.
-- Rodar duas vezes nao faz mal nenhum.
-- ============================================================

begin;

-- Suas referencias de video, na aba Checklist.
-- Sao videos de outras pessoas que voce estudou e quer guardar
-- destrinchados, para consultar na hora de escrever o seu roteiro.
-- "roteiro" guarda um pedaco por linha, no formato "0 a 5s | o que acontece".
create table if not exists public.referencias (
  id           uuid primary key default gen_random_uuid(),
  titulo       text not null default '',
  emoji        text default '',
  estilo       text default '',
  duracao      text default '',
  marca        text default '',
  link         text default '',
  gancho       text default '',
  porque       text default '',
  diferencial  text default '',
  erro         text default '',
  roteiro      text default '',
  criado_em    timestamptz not null default now()
);

-- Completa campos caso a tabela ja exista de uma versao anterior.
alter table public.referencias add column if not exists titulo      text not null default '';
alter table public.referencias add column if not exists emoji       text default '';
alter table public.referencias add column if not exists estilo      text default '';
alter table public.referencias add column if not exists duracao     text default '';
alter table public.referencias add column if not exists marca       text default '';
alter table public.referencias add column if not exists link        text default '';
alter table public.referencias add column if not exists gancho      text default '';
alter table public.referencias add column if not exists porque      text default '';
alter table public.referencias add column if not exists diferencial text default '';
alter table public.referencias add column if not exists erro        text default '';
alter table public.referencias add column if not exists roteiro     text default '';
alter table public.referencias add column if not exists criado_em   timestamptz not null default now();

create index if not exists referencias_data_idx on public.referencias (criado_em);

-- Permissao basica: so quem esta logado enxerga a tabela existir.
revoke all on public.referencias from public, anon, authenticated;
grant select, insert, update, delete on public.referencias to authenticated;

-- A tranca de verdade: so a dona confirmada le e grava.
alter table public.referencias enable row level security;
drop policy if exists "referencias dona total" on public.referencias;
create policy "referencias dona total" on public.referencias
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

commit;

-- PRONTO. Volte no painel, aba Checklist, Referencias de video,
-- e o botao Adicionar referencia ja vai funcionar.
