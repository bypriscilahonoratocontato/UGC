begin;

-- ============================================================
-- BANCO DE DADOS DO PAINEL DA PRISCILA
--
-- ONDE COLAR: entre no Supabase, abra o seu projeto,
-- clique em "SQL Editor" no menu da esquerda, clique em
-- "New query", cole TUDO que está neste arquivo e clique em "Run".
--
-- Pode rodar mais de uma vez sem medo. O arquivo foi escrito
-- para nao apagar nada que ja existe.
-- ============================================================


-- ============================================================
-- BLOCO 1: QUEM E A DONA
--
-- Esta funcao responde uma pergunta simples: "quem esta logado
-- agora e a Priscila?". Ela compara o e-mail de quem esta logado
-- com o seu e-mail. Todas as travas mais abaixo usam ela.
--
-- Isso protege voce ate se outra pessoa conseguir criar uma conta
-- no seu projeto Supabase: mesmo logada, ela nao vera nada seu.
-- ============================================================

create or replace function public.e_dona()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists(select 1 from auth.users
    where id = (select auth.uid())
    and lower(email) = 'bypriscilahonorato.contato@gmail.com'
    and email_confirmed_at is not null);
$$;


-- ============================================================
-- BLOCO 2: AS TABELAS
-- Cada tabela e uma "planilha" dentro do banco.
-- ============================================================

-- Os videos que aparecem no seu portfolio.
-- "ordem" controla a posicao na pagina, "visivel" e o olhinho
-- que mostra ou esconde o video do site.
create table if not exists public.videos (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null default '',
  link        text default '',
  nicho       text default '',
  formato     text default '',
  marca       text default '',
  destaque    text default '',
  ordem       integer not null default 0,
  visivel     boolean not null default true,
  criado_em   timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.videos add column if not exists titulo      text not null default '';
alter table public.videos add column if not exists link        text default '';
alter table public.videos add column if not exists nicho       text default '';
alter table public.videos add column if not exists formato     text default '';
alter table public.videos add column if not exists marca       text default '';
alter table public.videos add column if not exists destaque    text default '';
alter table public.videos add column if not exists ordem       integer not null default 0;
alter table public.videos add column if not exists visivel     boolean not null default true;
alter table public.videos add column if not exists criado_em   timestamptz not null default now();

-- Campos do portfolio autoral.
-- "tipo_midia" separa a galeria de fotos da galeria de videos.
-- "descricao" e a legenda curta que aparece embaixo do titulo.
-- "imagem" aceita um endereco completo (https://...) ou o nome de um
-- arquivo que esteja na pasta fotos do projeto (ex: cozinha.jpg).
alter table public.videos add column if not exists tipo_midia  text not null default 'video';
alter table public.videos add column if not exists descricao   text default '';
alter table public.videos add column if not exists imagem      text default '';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'videos_tipo_midia_valido') then
    alter table public.videos
      add constraint videos_tipo_midia_valido
      check (tipo_midia in ('foto','video'));
  end if;
end $$;

-- A sua base de contatos de empresa.
-- "situacao" so aceita estes quatro valores: lead, conversando, cliente, parada.
create table if not exists public.marcas (
  id              uuid primary key default gen_random_uuid(),
  nome            text not null default '',
  instagram       text default '',
  email           text default '',
  telefone        text default '',
  situacao        text not null default 'lead',
  obs             text default '',
  ultimo_contato  date,
  criado_em       timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.marcas add column if not exists nome            text not null default '';
alter table public.marcas add column if not exists instagram       text default '';
alter table public.marcas add column if not exists email           text default '';
alter table public.marcas add column if not exists telefone        text default '';
alter table public.marcas add column if not exists situacao        text not null default 'lead';
alter table public.marcas add column if not exists obs             text default '';
alter table public.marcas add column if not exists ultimo_contato  date;
alter table public.marcas add column if not exists criado_em       timestamptz not null default now();

-- Trava para ninguem gravar uma situacao que o painel nao entende.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'marcas_situacao_valida') then
    alter table public.marcas
      add constraint marcas_situacao_valida
      check (situacao in ('lead','conversando','cliente','parada'));
  end if;
end $$;

-- O seu calendario de producao.
-- "tipo" e gravar, editar ou postar. "status" e "a fazer" ou "feito".
create table if not exists public.calendario (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null default '',
  marca       text default '',
  tipo        text not null default 'gravar',
  data        date not null default current_date,
  status      text not null default 'a fazer',
  criado_em   timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.calendario add column if not exists titulo      text not null default '';
alter table public.calendario add column if not exists marca       text default '';
alter table public.calendario add column if not exists tipo        text not null default 'gravar';
alter table public.calendario add column if not exists data        date not null default current_date;
alter table public.calendario add column if not exists status      text not null default 'a fazer';
alter table public.calendario add column if not exists criado_em   timestamptz not null default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'calendario_tipo_valido') then
    alter table public.calendario
      add constraint calendario_tipo_valido
      check (tipo in ('gravar','editar','postar'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'calendario_status_valido') then
    alter table public.calendario
      add constraint calendario_status_valido
      check (status in ('a fazer','feito'));
  end if;
end $$;

-- As suas campanhas, com valor, prazo e pagamento.
-- "favorita" e a estrela. "ativa" separa em andamento de finalizada.
create table if not exists public.campanhas (
  id          uuid primary key default gen_random_uuid(),
  campanha    text not null default '',
  cliente     text default '',
  tipo        text not null default 'Conteúdo',
  status      text not null default 'Briefing',
  qtd         integer not null default 1,
  valor       numeric(12,2) not null default 0,
  prazo       date,
  pagamento   text not null default 'pendente',
  ativa       boolean not null default true,
  favorita    boolean not null default false,
  criado_em   timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.campanhas add column if not exists campanha    text not null default '';
alter table public.campanhas add column if not exists cliente     text default '';
alter table public.campanhas add column if not exists tipo        text not null default 'Conteúdo';
alter table public.campanhas add column if not exists status      text not null default 'Briefing';
alter table public.campanhas add column if not exists qtd         integer not null default 1;
alter table public.campanhas add column if not exists valor       numeric(12,2) not null default 0;
alter table public.campanhas add column if not exists prazo       date;
alter table public.campanhas add column if not exists pagamento   text not null default 'pendente';
alter table public.campanhas add column if not exists ativa       boolean not null default true;
alter table public.campanhas add column if not exists favorita    boolean not null default false;
alter table public.campanhas add column if not exists criado_em   timestamptz not null default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'campanhas_tipo_valido') then
    alter table public.campanhas
      add constraint campanhas_tipo_valido
      check (tipo in ('Conteúdo','Publicidade'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'campanhas_pagamento_valido') then
    alter table public.campanhas
      add constraint campanhas_pagamento_valido
      check (pagamento in ('pendente','pago'));
  end if;
end $$;

-- O que voce ja marcou no checklist do portfolio.
-- Cada item marcado vira uma linha com a sua chave de texto.
create table if not exists public.marcados (
  chave          text primary key,
  marcado        boolean not null default true,
  atualizado_em  timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.marcados add column if not exists chave          text;
alter table public.marcados add column if not exists marcado        boolean not null default true;
alter table public.marcados add column if not exists atualizado_em  timestamptz not null default now();

-- O registro de visitas do seu portfolio.
-- Nenhum dado pessoal do visitante e guardado aqui.
create table if not exists public.visitas (
  id        bigserial primary key,
  data      timestamptz not null default now(),
  pagina    text default '',
  origem    text default ''
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.visitas add column if not exists data      timestamptz not null default now();
alter table public.visitas add column if not exists pagina    text default '';
alter table public.visitas add column if not exists origem    text default '';

-- Suas ideias de conteudo.
-- "origem" diz se a ideia nasceu no painel ou veio do seu Trello.
-- "trello_id" evita a mesma ideia entrar duas vezes na sincronizacao.
create table if not exists public.ideias (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null default '',
  descricao   text default '',
  nicho       text default '',
  status      text not null default 'nova',
  origem      text not null default 'admin',
  trello_id   text unique,
  criado_em   timestamptz not null default now()
);

-- Completa campos de uma instalação anterior, preservando os registros.
alter table public.ideias add column if not exists titulo      text not null default '';
alter table public.ideias add column if not exists descricao   text default '';
alter table public.ideias add column if not exists nicho       text default '';
alter table public.ideias add column if not exists status      text not null default 'nova';
alter table public.ideias add column if not exists origem      text not null default 'admin';
alter table public.ideias add column if not exists trello_id   text;
alter table public.ideias add column if not exists criado_em   timestamptz not null default now();


alter table public.ideias add column if not exists trello_url text default '';
alter table public.ideias add column if not exists trello_lista text default '';
create unique index if not exists ideias_trello_unico on public.ideias(trello_id);

-- ============================================================
-- BLOCO 3: INDICES
-- Só deixam as buscas mais rapidas quando a base crescer.
-- ============================================================

create index if not exists videos_ordem_idx      on public.videos (ordem);
create index if not exists marcas_situacao_idx   on public.marcas (situacao);
create index if not exists calendario_data_idx   on public.calendario (data);
create index if not exists campanhas_prazo_idx   on public.campanhas (prazo);
create index if not exists visitas_data_idx      on public.visitas (data);


-- ============================================================
-- BLOCO 4: PERMISSOES BASICAS
--
-- Isso apenas diz que as tabelas existem para o site enxergar.
-- A tranca de verdade e o RLS, que vem no bloco 5.
-- ============================================================

-- Apenas as tabelas deste painel recebem permissões.
grant usage on schema public to anon, authenticated;
revoke all on public.videos,public.marcas,public.calendario,public.campanhas,public.marcados,public.visitas,public.ideias from public,anon,authenticated;
grant select,insert,update,delete on public.videos,public.marcas,public.calendario,public.campanhas,public.marcados,public.visitas,public.ideias to authenticated;
grant select on public.videos,public.marcas,public.calendario,public.campanhas,public.marcados,public.visitas,public.ideias to anon;
grant insert on public.marcas,public.visitas to anon;
grant usage on sequence public.visitas_id_seq to anon,authenticated;
revoke all on function public.e_dona() from public;
grant execute on function public.e_dona() to anon,authenticated;

-- BLOCO 5: fecha todas as tabelas e substitui regras antigas
-- destas sete tabelas. Não altera permissões de outros projetos.
-- Só a dona confirmada pode consultar ou alterar dados privados.
-- Exceções: ler vídeos visíveis, enviar contato Lead e registrar visita.
do $$
declare t text; p record;
begin
  foreach t in array array['videos','marcas','calendario','campanhas','marcados','visitas','ideias'] loop
    execute format('alter table public.%I enable row level security',t);
    for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy %I on public.%I',p.policyname,t);
    end loop;
  end loop;
end $$;

-- VIDEOS
drop policy if exists "videos dona total" on public.videos;
create policy "videos dona total" on public.videos
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

drop policy if exists "videos leitura publica dos visiveis" on public.videos;
create policy "videos leitura publica dos visiveis" on public.videos
  for select to anon, authenticated
  using (visivel = true);

-- MARCAS
drop policy if exists "marcas dona total" on public.marcas;
create policy "marcas dona total" on public.marcas
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

drop policy if exists "marcas entrada do formulario" on public.marcas;
create policy "marcas entrada do formulario" on public.marcas
  for insert to anon, authenticated
  with check (situacao = 'lead' and length(trim(nome)) between 1 and 300 and length(coalesce(obs,'')) <= 10000);

-- CALENDARIO
drop policy if exists "calendario dona total" on public.calendario;
create policy "calendario dona total" on public.calendario
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

-- CAMPANHAS
drop policy if exists "campanhas dona total" on public.campanhas;
create policy "campanhas dona total" on public.campanhas
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

-- MARCADOS
drop policy if exists "marcados dona total" on public.marcados;
create policy "marcados dona total" on public.marcados
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());

-- VISITAS
drop policy if exists "visitas dona leitura" on public.visitas;
create policy "visitas dona leitura" on public.visitas
  for all to authenticated
  using (public.e_dona()) with check (public.e_dona());

drop policy if exists "visitas registro publico" on public.visitas;
create policy "visitas registro publico" on public.visitas
  for insert to anon, authenticated
  with check (length(coalesce(pagina,'')) <= 500 and length(coalesce(origem,'')) <= 300);

-- IDEIAS
drop policy if exists "ideias dona total" on public.ideias;
create policy "ideias dona total" on public.ideias
  for all to authenticated
  using (public.e_dona())
  with check (public.e_dona());


-- ============================================================
-- BLOCO 6: UMA LINHA DE EXEMPLO EM CADA LISTA
--
-- Cada linha comeca com "EXEMPLO" no nome, so para voce ver o
-- formato. Pode apagar todas pelo proprio painel quando entender.
-- Se voce ja tiver dados, este bloco nao duplica nada.
-- ============================================================

insert into public.videos (titulo, descricao, link, nicho, formato, marca, tipo_midia, ordem, visivel)
select 'EXEMPLO Organizacao de um cantinho da casa',
       'Fotografia e composicao com um produto da minha rotina.',
       '', 'casa', 'foto 4:5', 'Tokstok', 'foto', 1, false
where not exists (select 1 from public.videos);

insert into public.marcas (nome, instagram, email, telefone, situacao, obs, ultimo_contato)
select 'EXEMPLO Marca de teste', '', 'contato@example.invalid', '', 'lead', 'Linha de exemplo, pode apagar.', current_date
where not exists (select 1 from public.marcas);

insert into public.calendario (titulo, marca, tipo, data, status)
select 'EXEMPLO Gravar video de teste', 'EXEMPLO Marca', 'gravar', current_date, 'a fazer'
where not exists (select 1 from public.calendario);

insert into public.campanhas (campanha, cliente, tipo, status, qtd, valor, prazo, pagamento, ativa, favorita)
select 'EXEMPLO Campanha de teste', 'EXEMPLO Cliente', 'Conteúdo', 'Briefing', 1, 0, current_date + 7, 'pendente', true, false
where not exists (select 1 from public.campanhas);

insert into public.ideias (titulo, descricao, nicho, status, origem)
select 'EXEMPLO Ideia de conteudo', 'Linha de exemplo, pode apagar.', 'casa', 'nova', 'admin'
where not exists (select 1 from public.ideias);


-- Configurações de validade para novas campanhas. NOT VALID preserva
-- registros antigos, mas exige os valores corretos nas novas gravações.
do $$ begin
  if not exists(select 1 from pg_constraint where conname='campanhas_funil_valido' and conrelid='public.campanhas'::regclass) then
    alter table public.campanhas add constraint campanhas_funil_valido check(status in ('Briefing','Roteiro','Aprovação Roteiro','Gravação','Edição','Aprovado','Entregue')) not valid;
  end if;
  if not exists(select 1 from pg_constraint where conname='campanhas_numeros_validos' and conrelid='public.campanhas'::regclass) then
    alter table public.campanhas add constraint campanhas_numeros_validos check(qtd>=1 and valor>=0) not valid;
  end if;
end $$;

commit;

-- PRONTO. Em uma nova consulta, rode teste-rls.sql.
-- Os exemplos só entram se a tabela estiver vazia. O vídeo de exemplo
-- fica escondido e nenhuma visita artificial é criada.
