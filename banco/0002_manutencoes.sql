-- =====================================================================
-- 0002 · Manutenções escolares (TMF / D3) + importação do quadro antigo
-- Como rodar: Supabase → Editor SQL → Nova consulta → colar tudo → Executar.
-- Pode rodar de novo: não duplica as demandas importadas.
-- =====================================================================

create table if not exists public.manutencoes (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  escola       text not null,
  servico      text not null,
  empresa      text,
  tipo         text default 'Manutenção predial',
  recebido     date,
  prazo        date,
  prioridade   text not null default 'media' check (prioridade in ('baixa','media','alta')),
  status       text not null default 'afazer' check (status in ('afazer','andamento','concluido','cancelada')),
  os           text,                    -- nº da OS / processo
  concluido    date,
  cancelado    date,
  obs          text,
  motivo       text,                    -- motivo do cancelamento
  id_origem    text,                    -- id no quadro antigo (importação)
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (user_id, id_origem)
);
create index if not exists manutencoes_user_idx on public.manutencoes(user_id, status, prazo);
drop trigger if exists manutencoes_updated on public.manutencoes;
create trigger manutencoes_updated before update on public.manutencoes
  for each row execute function public.tg_updated_at();

alter table public.manutencoes enable row level security;
drop policy if exists manutencoes_dono on public.manutencoes;
create policy manutencoes_dono on public.manutencoes for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.manutencoes to authenticated;

-- ---------------------------------------------------------------------
-- Importação das demandas do quadro "Kanban Manutenções Escolares"
-- (ficam no usuário do e-mail abaixo — o seu login no sistema)
-- ---------------------------------------------------------------------
insert into public.manutencoes
  (user_id, id_origem, escola, servico, empresa, tipo, recebido, prazo, prioridade, status, os, concluido, cancelado, obs, motivo, created_at)
select u.id, v.id_origem, v.escola, v.servico, v.empresa, v.tipo, v.recebido::date, v.prazo::date, v.prioridade, v.status,
       v.os, v.concluido::date, v.cancelado::date, v.obs, v.motivo, v.criado
from auth.users u
cross join (values
('benedita-forro-1', 'CEIC Benedita Dias Evangelista', 'Reparo do forro que está cedendo', 'TMF', 'Manutenção predial', '2026-10-20', null, 'alta', 'afazer', null, null, null, 'Contato: Diretora Cátia. Forro cedendo: risco de queda, isolar a área até o reparo e verificar a causa (infiltração, estrutura de sustentação).', null, '2026-10-20T21:00:00.001000+00:00'::timestamptz),
('d3-benedita-0', 'CEIC Benedita Dias Evangelista', 'Reparo do forro que está cedendo', 'D3', 'Manutenção predial', '2026-10-20', null, 'alta', 'afazer', null, null, null, 'Contato: Diretora Cátia (telefone não informado). Urgência: Urgente (risco de queda do forro).', null, '2026-10-20T09:53:20.052000+00:00'::timestamptz),
('d3-eldorado-0', 'CAIC Eldorado', 'Reparo e troca de revestimento nos banheiros das salas', 'D3', 'Manutenção predial', '2026-10-20', null, 'media', 'afazer', null, null, null, 'Contato: Diretora Nair (telefone não informado). Urgência: Normal.', null, '2026-10-20T09:53:20.053000+00:00'::timestamptz),
('d3-lais-1', 'CEIC Lais Amicucci Soares Martins', '1) Reparo no banheiro (cano de saída furado); 2) Nivelamento do refeitório; 3) Manutenção no tanque de lavar roupas', 'D3', 'Manutenção predial', '2026-09-08', null, 'alta', 'afazer', null, null, null, 'Contato: Diretora Rosangela. Urgência: item 1 Urgente. Demais: Normal.', null, '2026-10-20T09:53:20.046000+00:00'::timestamptz),
('d3-meirelles-1', 'CMEI Coronel José Meirelles', 'Manutenção corretiva no quadro de distribuição: disjuntor danificado, com fusão junto ao barramento inferior. Trocar por disjuntor de 25 A curva C, verificar cabo de 4 mm², avaliar e trocar o barramento se preciso, checar as demais conexões e testar (Ofício 113/2026)', 'D3', 'Elétrica', '2026-09-21', null, 'alta', 'afazer', null, null, null, 'Urgência: Emergencial (risco de incêndio). Executar por eletricista habilitado, NBR 5410. Contato não informado.', null, '2026-10-20T09:53:20.049000+00:00'::timestamptz),
('d3-pedroso-1', 'EMEB Francisco Pedroso da Silva', 'Transferência de carga do T6 para o posto de transformação (112,5 kVA), hoje ligado direto sem medição: retirar cabos antigos, passar fiação nova 3#185(95) mm² XLPE/EPR em eletroduto de 100 mm, abrir rasgo no piso da caixa de passagem até o pé da parede, puxar até o quadro geral na secretaria e instalar disjuntor de 300 A', 'D3', 'Elétrica', '2026-09-08', null, 'alta', 'afazer', null, null, null, 'Contato: Diretora Lindalva 65 9223-3883. Urgência: Emergencial. Repassada da TMF (OS 40) para a D3 em 20/10/2026 por demora. Exigir ART de execução e conferir seletividade da proteção.', null, '2026-10-20T09:53:20.050000+00:00'::timestamptz),
('eldorado-banheiros-1', 'CAIC Eldorado', 'Reparo e troca de revestimento nos banheiros das salas', 'TMF', 'Manutenção predial', '2026-10-20', null, 'media', 'afazer', null, null, null, 'Contato: Diretora Nair.', null, '2026-10-20T21:00:00.002000+00:00'::timestamptz),
('tmf-altosgloria-0', 'CEIC Altos da Glória', 'Reparo do forro que caiu no corredor de circulação da entrada', 'TMF', 'Manutenção predial', '2026-10-20', null, 'alta', 'afazer', null, null, null, 'Contato: (não informado). Urgência: Urgente. Forro caído no corredor de circulação da entrada.', null, '2026-10-20T18:45:00+00:00'::timestamptz),
('tmf-darcy-0', 'EMEB Senador Darcy Ribeiro', '1) Pintura geral. 2) Reforma dos banheiros: pintura, forro, piso e portas. 3) Reforma das portas enferrujadas. 4) Reparo estrutural de dois pilares. 5) Abertura de vão em parede com vidro e bancada para recepção.', 'TMF', 'Manutenção predial', '2026-11-06', null, 'alta', 'afazer', null, null, null, 'Contato: Diretor Michel 65 99214-4464. Urgência: Urgente.', null, '2026-10-28T19:28:20+00:00'::timestamptz),
('tmf-ezequiel-0', 'EMEB Prof. Ezequiel Pompeu Ribeiro de Siqueira', '1) Banheiro PCD: transformar em depósito. 2) Banheiro do fundo: reforma. 3) Cozinha: passa-prato e solução da pia que está inundando. 4) Portas de ferro da sala dos professores: troca e recomposição. 5) Caixa d''água tipo taça. 6) Portão de correr na entrada. 7) Fechar sala e derrubar parede.', 'TMF', 'Manutenção predial', '2026-11-04', null, 'alta', 'afazer', null, null, null, 'Contato: (não informado). Urgência: Urgente.', null, '2026-10-26T11:15:00+00:00'::timestamptz),
('tmf-os01', 'EMEB Francisca Figueiredo', 'Vazamento de água no banheiro masculino', 'TMF', 'Hidráulica', '2026-08-12', null, 'alta', 'afazer', '1', null, null, 'Contato: Diretora Lilian 65 99217-1198. Urgência: Urgente.', null, '2026-10-20T09:53:20.001000+00:00'::timestamptz),
('tmf-os02', 'CEIC São Mateus', 'Fornecimento de caminhão-pipa', 'TMF', 'Hidráulica', '2026-08-12', null, 'alta', 'afazer', '2', null, null, 'Contato: Diretora Rosely. Urgência: Urgente.', null, '2026-10-20T09:53:20.002000+00:00'::timestamptz),
('tmf-os03', 'EMEB Hélio de Souza Vieira', '1) Porta do banheiro danificada, válvula de descarga (hidra) com defeito e drenagem ruim; 2) Vistoria nas tomadas das salas de aula para o uso das urnas eletrônicas; 3) Piso solto na cozinha e no banheiro (risco de queda)', 'TMF', 'Manutenção predial', '2026-09-02', null, 'alta', 'afazer', '3–5', null, null, 'Contato: Diretora Simone 65 9911-1057. Urgência: todos Urgente. O item 2 é ligado à eleição.', null, '2026-10-20T09:53:20.003000+00:00'::timestamptz),
('tmf-os06', 'EMEB Cel. Octayde Jorge da Silva', 'Refazer o quadro geral de distribuição e trocar os cabos para 25 mm² (problema de aquecimento)', 'TMF', 'Elétrica', '2026-09-03', null, 'alta', 'afazer', '6', null, null, 'Urgência: Emergencial (risco de incêndio). Contato não informado.', null, '2026-10-20T09:53:20.006000+00:00'::timestamptz),
('tmf-os07', 'EMEB Gastão Muller', '1) Revitalização do reservatório subterrâneo de 12 m³ (revestimento desplacando); 2) Banheiro com retorno de mau cheiro (sem tubulação de ventilação); 3) Reparo no tanque (cuba solta); 4) Troca da pia da cozinha; 5) Troca do piso da cozinha (granilite, a confirmar); 6) Coifa queimada; 7) Forrar a área externa (fiação exposta e pombos)', 'TMF', 'Manutenção predial', '2026-09-04', null, 'alta', 'afazer', '7–13', null, null, 'Contato: Diretor Wanderson Miranda 63 9295-3353. Urgentes: itens 1, 2, 6 e 7. Demais: Normal.', null, '2026-10-20T09:53:20.007000+00:00'::timestamptz),
('tmf-os14', 'Creche Municipal Jamil Boutros Nadaf', '1) Toldo na entrada, onde os pais aguardam; 2) Fechamento de forro e acabamento do beiral de madeira; 3) Tubulação externa do dreno do ar-condicionado; 4) Mudar a saída de calha do meio da fachada para o canto; 5) Retirar vaso sanitário adulto sem uso no maternal; 6) Porta de ferro das salas com buracos, acumulando baratas; 7) Manutenção das janelas emperradas; 8) Avaliar troca das janelas redondas por quadradas', 'TMF', 'Manutenção predial', '2026-09-04', null, 'alta', 'afazer', '14–21', null, null, 'Contato: Diretora Andressa 65 9941-7292. Urgente: item 6. Item 5 é preventivo. Demais: Normal. Os itens 4 e 8 podem extrapolar o escopo de manutenção.', null, '2026-10-20T09:53:20.014000+00:00'::timestamptz),
('tmf-os22', 'CEIC Helenita', '1) Reparo de beiral e forro; 2) Reparo de telhado (telhas quebradas no depósito e na direção, com vazamento); 3) Cobertura para remanejar a lavanderia para o fundo e transformar a antiga em sala dos professores; 4) Reabastecer o gás dos ares-condicionados; 5) Vedação do rodapé da sala modular (radier com a base); 6) Instalação de coifa na cozinha', 'TMF', 'Manutenção predial', '2026-09-04', null, 'alta', 'afazer', '22–27', null, null, 'Contato: Diretora Daniely 65 9937-1394. Urgente: item 2. Demais: Normal. O item 3 é reforma com mudança de uso: verificar enquadramento no contrato.', null, '2026-10-20T09:53:20.022000+00:00'::timestamptz),
('tmf-os28', 'CEIC Rosângela Campos', 'Levantamento de carga da alimentação principal (verificar corrente) e dimensionamento dos pontos com desarme, como o ar-condicionado (aumentar diâmetro do cabeamento)', 'TMF', 'Elétrica', '2026-09-04', null, 'alta', 'afazer', '28', null, null, 'Urgência: Urgente. Contato não informado.', null, '2026-10-20T09:53:20.028000+00:00'::timestamptz),
('tmf-os29', 'Creche Municipal Ale Guilherme Arfux da Costa Ribeiro', 'Reparo no forro que caiu com a forte chuva e na calha que passa no meio do ambiente', 'TMF', 'Manutenção predial', '2026-09-04', null, 'alta', 'afazer', '29', null, null, 'Contato: Rejane 65 99807-2851. Urgência: Emergencial (forro colapsado). Corrigir também a causa: escoamento da calha.', null, '2026-10-20T09:53:20.029000+00:00'::timestamptz),
('tmf-os30', 'EMEB Profa Rita Caldas Castrillon', '1) Demolir e construir a parede do refeitório; 2) Retirar a caixa de gordura da cozinha; 3) Troca do forro da cozinha; 4) Trocar o revestimento da parede por placa 32x60 cm; 5) Amarração nas rachaduras da parede da cozinha; 6) Revitalizar o granilite da cozinha; 7) Troca das esquadrias', 'TMF', 'Manutenção predial', '2026-09-08', null, 'alta', 'afazer', '30–36', null, null, 'Contato: Diretor Leandro 65 9913-2145. Urgente: item 5 (diagnosticar a origem das fissuras antes de amarrar). Demais: Normal.', null, '2026-10-20T09:53:20.030000+00:00'::timestamptz),
('tmf-os37', 'EMEB Maria da Glória de Souza', '1) Orçamento da execução do muro de arrimo com drenagem; 2) Orçamento da execução da quadra poliesportiva', 'TMF', 'Outro', '2026-09-08', null, 'media', 'afazer', '37–38', null, null, 'Contato: Diretora Solange 65 99265-8811. Urgência: Normal. Obra nova: só orçamento, sem autorizar execução.', null, '2026-10-20T09:53:20.037000+00:00'::timestamptz),
('tmf-os39', 'EMEB Francisco Pedroso da Silva', 'Vedação da lateral da base (encontro piso/parede) contra infiltração de água', 'TMF', 'Manutenção predial', '2026-09-08', null, 'alta', 'afazer', '39', null, null, 'Contato: Diretora Lindalva 65 9223-3883. Urgência: Urgente. A demanda elétrica desta escola (OS 40) foi repassada para a D3 por demora.', null, '2026-10-20T09:53:20.039000+00:00'::timestamptz),
('tmf-os40-repassada', 'EMEB Francisco Pedroso da Silva', 'Transferência de carga do T6 para o posto de transformação (112,5 kVA), com troca de fiação, rasgo no piso e disjuntor de 300 A', 'TMF', 'Elétrica', '2026-09-08', null, 'alta', 'cancelada', '40', null, '2026-10-20', 'Contato: Diretora Lindalva 65 9223-3883. Urgência: Emergencial. Continua em aberto no cartão da D3.', 'Repassada para a D3 por demora na execução', '2026-10-20T09:53:20.051000+00:00'::timestamptz),
('tmf-os41', 'EMEB Maria Elazir Corrêa de Figueiredo', 'Revisão e manutenção corretiva nos banheiros e salas de aula para a eleição', 'TMF', 'Manutenção predial', '2026-09-08', null, 'alta', 'afazer', '41', null, null, 'Contato: Diretora Larissa Villanova 65 9951-0315. Urgência: Urgente. Unidade usada como local de votação.', null, '2026-10-20T09:53:20.041000+00:00'::timestamptz),
('tmf-os42', 'EMEB Clóvis Hugueney Neto', 'Limpeza da fossa', 'TMF', 'Hidráulica', '2026-09-18', null, 'alta', 'afazer', '42', null, null, 'Urgência: Urgente. Contato não informado.', null, '2026-10-20T09:53:20.042000+00:00'::timestamptz),
('tmf-os43', 'Creche Municipal Professora Maria de Figueiredo Nunes', 'Pane elétrica desde 07/09: tomadas sem funcionar, ponto eletrônico prejudicado, ventilador do refeitório e lâmpadas queimados. Vistoria técnica, identificar a causa e fazer a manutenção da rede elétrica', 'TMF', 'Elétrica', '2026-09-21', null, 'alta', 'afazer', '43', null, null, 'Urgência: Urgente. Contato não informado.', null, '2026-10-20T09:53:20.043000+00:00'::timestamptz),
('tmf-os44', 'EMEB Hélio de Souza Vieira', 'Falta de água somente na pia da cozinha; a equipe da escola não achou a causa', 'TMF', 'Hidráulica', '2026-09-21', null, 'alta', 'afazer', '44', null, null, 'Contato: Diretora Simone 65 9911-1057. Urgência: Urgente.', null, '2026-10-20T09:53:20.044000+00:00'::timestamptz),
('tmf-os45', 'EMEB Paulo de Campos Borges', 'Levantamento da rede hidráulica com vazamento: achar o ponto e resolver. Suspeita no trecho do hidrômetro (relógio) até a caixa d''água. Conta de água muito acima do normal', 'TMF', 'Hidráulica', '2026-09-28', null, 'alta', 'afazer', '45', null, null, 'Urgência: Urgente. Contato não informado. Sugerido teste de estanqueidade antes de abrir valas.', null, '2026-10-20T09:53:20.045000+00:00'::timestamptz),
('tmf-os46', 'CEIC Benedita Dias Evangelista', 'Reparo do forro que está cedendo', 'TMF', 'Manutenção predial', '2026-10-20', null, 'alta', 'afazer', '46', null, null, 'Contato: Diretora Cátia (telefone não informado). Urgência: Urgente (risco de queda do forro).', null, '2026-10-20T09:53:20.052000+00:00'::timestamptz),
('tmf-os47', 'CAIC Eldorado', 'Reparo e troca de revestimento nos banheiros das salas', 'TMF', 'Manutenção predial', '2026-10-20', null, 'media', 'afazer', '47', null, null, 'Contato: Diretora Nair (telefone não informado). Urgência: Normal.', null, '2026-10-20T09:53:20.053000+00:00'::timestamptz)
) as v(id_origem, escola, servico, empresa, tipo, recebido, prazo, prioridade, status, os, concluido, cancelado, obs, motivo, criado)
where u.email = 'cbhigoroliveira@gmail.com'
on conflict (user_id, id_origem) do nothing;

-- conferência: deve mostrar 30 demandas importadas
select count(*) as demandas_importadas from public.manutencoes where id_origem is not null;
