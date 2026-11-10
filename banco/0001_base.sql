-- =====================================================================
-- 0001 · Base do sistema: Kanban de tarefas e projetos PSCIP
-- Como rodar: Supabase → SQL Editor → New query → colar tudo → Run.
-- Cada linha tem um dono (user_id); as regras de RLS deixam cada usuário
-- ver e alterar só os próprios dados. Quem não fez login não vê nada.
-- =====================================================================

create or replace function public.tg_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

-- ---------------------------------------------------------------------
-- Kanban
-- ---------------------------------------------------------------------
create table if not exists public.tarefas (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  quadro       text not null default 'Geral',
  titulo       text not null,
  descricao    text,
  coluna       text not null default 'a_fazer' check (coluna in ('a_fazer','fazendo','aguardando','feito')),
  ordem        double precision not null default 0,
  prioridade   text not null default 'media' check (prioridade in ('baixa','media','alta')),
  prazo        date,
  etiqueta     text,
  concluida_em timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists tarefas_user_idx on public.tarefas(user_id, quadro, coluna, ordem);
drop trigger if exists tarefas_updated on public.tarefas;
create trigger tarefas_updated before update on public.tarefas
  for each row execute function public.tg_updated_at();

alter table public.tarefas enable row level security;
drop policy if exists tarefas_dono on public.tarefas;
create policy tarefas_dono on public.tarefas for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.tarefas to authenticated;

-- ---------------------------------------------------------------------
-- PSCIP
-- ---------------------------------------------------------------------
create table if not exists public.pscip_projetos (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente         text not null,
  contato         text,
  telefone        text,
  email           text,
  edificacao      text,                    -- nome / descrição do imóvel
  endereco        text,
  municipio       text default 'Cuiabá',
  tipo_servico    text default 'PSCIP',
  ocupacao        text,                    -- grupo/divisão (ex.: D-1, E-5, F-6)
  area_m2         numeric(12,2),
  altura_m        numeric(7,2),
  pavimentos      integer,
  lotacao         integer,
  etapa           text not null default 'orcamento' check (etapa in
                  ('orcamento','contratado','levantamento','projeto','protocolado',
                   'exigencia','aprovado','vistoria','concluido','cancelado')),
  protocolo       text,                    -- nº do processo no CBMMT
  data_protocolo  date,
  art             text,
  prazo           date,                    -- data da próxima ação
  proxima_acao    text,
  honorarios      numeric(14,2),
  valor_recebido  numeric(14,2) default 0,
  observacoes     text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists pscip_user_idx on public.pscip_projetos(user_id, etapa, prazo);
drop trigger if exists pscip_updated on public.pscip_projetos;
create trigger pscip_updated before update on public.pscip_projetos
  for each row execute function public.tg_updated_at();

create table if not exists public.pscip_eventos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  projeto_id  uuid not null references public.pscip_projetos(id) on delete cascade,
  data        date not null default current_date,
  descricao   text not null,
  created_at  timestamptz not null default now()
);
create index if not exists pscip_eventos_proj_idx on public.pscip_eventos(projeto_id, data);

alter table public.pscip_projetos enable row level security;
alter table public.pscip_eventos  enable row level security;

drop policy if exists pscip_dono on public.pscip_projetos;
create policy pscip_dono on public.pscip_projetos for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists pscip_eventos_dono on public.pscip_eventos;
create policy pscip_eventos_dono on public.pscip_eventos for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.pscip_projetos p where p.id = projeto_id and p.user_id = (select auth.uid())));

grant select, insert, update, delete on public.pscip_projetos to authenticated;
grant select, insert, update, delete on public.pscip_eventos  to authenticated;
