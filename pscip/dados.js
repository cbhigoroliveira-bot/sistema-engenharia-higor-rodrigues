// Etapas e tabelas de apoio do módulo PSCIP.

export const ETAPAS = [
  { id: 'orcamento',    nome: 'Orçamento enviado',      cor: 'cinza' },
  { id: 'contratado',   nome: 'Contratado',             cor: 'azul' },
  { id: 'levantamento', nome: 'Levantamento / vistoria prévia', cor: 'azul' },
  { id: 'projeto',      nome: 'Projeto em elaboração',  cor: 'azul' },
  { id: 'protocolado',  nome: 'Protocolado no CBMMT',   cor: 'roxo' },
  { id: 'exigencia',    nome: 'Em exigência / correção', cor: 'vermelho' },
  { id: 'aprovado',     nome: 'Projeto aprovado',       cor: 'verde' },
  { id: 'vistoria',     nome: 'Aguardando vistoria',    cor: 'amarelo' },
  { id: 'concluido',    nome: 'Concluído (CA emitido)', cor: 'verde' },
  { id: 'cancelado',    nome: 'Cancelado / não fechou', cor: 'cinza' },
];
export const ETAPA = Object.fromEntries(ETAPAS.map(e => [e.id, e]));
export const ENCERRADAS = ['concluido', 'cancelado'];

export const TIPOS_SERVICO = [
  'PSCIP', 'PSCIP simplificado', 'Substituição / atualização de PSCIP',
  'Renovação de Certificado de Aprovação', 'Vistoria / laudo', 'Isenção (TASEG)', 'Consultoria',
];

// Classificação quanto à altura (referência usual das normas de incêndio; confira na NTCB vigente)
export function classeAltura(alturaM, pavimentos) {
  if (alturaM == null) return pavimentos === 1 ? 'Tipo I – térrea' : '';
  const h = Number(alturaM);
  if (h <= 0 || pavimentos === 1) return 'Tipo I – térrea';
  if (h <= 6) return 'Tipo II – baixa (H ≤ 6 m)';
  if (h <= 12) return 'Tipo III – baixa-média (6 < H ≤ 12 m)';
  if (h <= 23) return 'Tipo IV – média (12 < H ≤ 23 m)';
  if (h <= 30) return 'Tipo V – mediamente alta (23 < H ≤ 30 m)';
  return 'Tipo VI – alta (H > 30 m)';
}

export function seloEtapa(id) {
  const e = ETAPA[id] || { nome: id, cor: 'cinza' };
  return `<span class="selo ${e.cor}">${e.nome}</span>`;
}
