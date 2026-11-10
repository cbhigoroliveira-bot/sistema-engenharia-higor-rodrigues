// Conexão com o Supabase e controle de login.
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
import { SUPABASE_URL, SUPABASE_CHAVE, RESPONSAVEL } from './config.js';
import { esc } from './ui.js';

export const sb = createClient(SUPABASE_URL, SUPABASE_CHAVE);

// Endereço da raiz do site (funciona no GitHub Pages e localmente)
export const RAIZ = new URL('../', import.meta.url).href;

export const MODULOS = [
  { id: 'painel',  nome: 'Painel',         href: 'index.html',        pronto: true },
  { id: 'kanban',  nome: 'Tarefas',        href: 'kanban/index.html', pronto: true },
  { id: 'manutencoes', nome: 'Manutenções', href: 'manutencoes/index.html', pronto: true },
  { id: 'pscip',   nome: 'PSCIP',          href: 'pscip/index.html',  pronto: true },
  { id: 'obras',   nome: 'Obras e medições', href: null, pronto: false },
  { id: 'relatorio', nome: 'Relatório de obra', href: null, pronto: false },
  { id: 'orcamento', nome: 'Orçamento SINAPI', href: null, pronto: false },
  { id: 'laudos',  nome: 'Laudos',         href: null, pronto: false },
  { id: 'processos', nome: 'Processos SIGED', href: null, pronto: false },
];

// Exige sessão; se não houver, manda para o login e volta depois.
export async function exigirLogin() {
  const { data: { session } } = await sb.auth.getSession();
  if (!session) {
    const voltar = location.pathname + location.search;
    location.replace(RAIZ + 'login.html?voltar=' + encodeURIComponent(voltar));
    return new Promise(() => {});
  }
  sb.auth.onAuthStateChange((ev) => { if (ev === 'SIGNED_OUT') location.replace(RAIZ + 'login.html'); });
  return session.user;
}

export function montarCabecalho(ativo, user) {
  const links = MODULOS.filter(m => m.pronto).map(m =>
    `<a href="${RAIZ + m.href}" class="${m.id === ativo ? 'ativo' : ''}">${esc(m.nome)}</a>`).join('');
  const h = document.createElement('header');
  h.className = 'topo';
  h.innerHTML = `
    <a class="marca" href="${RAIZ}index.html"><span class="logo">HR</span><span>Sistema de Engenharia</span></a>
    <nav>${links}</nav>
    <div class="usuario"><span title="${esc(RESPONSAVEL.crea)}">${esc(user?.email || '')}</span>
      <button class="btn fino" id="btnSair">Sair</button></div>`;
  document.body.prepend(h);
  h.querySelector('#btnSair').onclick = async () => { await sb.auth.signOut(); location.replace(RAIZ + 'login.html'); };
}
