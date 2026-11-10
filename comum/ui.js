// Utilidades de tela e formatos no padrão brasileiro.

export function esc(v) {
  return String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

const fMoeda = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
export const moeda = v => (v == null || v === '' || isNaN(v)) ? '—' : fMoeda.format(Number(v));
export const numero = (v, casas = 2) => (v == null || v === '' || isNaN(v)) ? '—'
  : Number(v).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });

// "1.234,56" ou "1234.56" -> 1234.56 ; vazio -> null
export function lerNumero(txt) {
  if (txt == null) return null;
  let s = String(txt).trim().replace(/[R$\s]/g, '');
  if (!s) return null;
  if (s.includes(',')) s = s.replace(/\./g, '').replace(',', '.');
  const n = Number(s);
  return isNaN(n) ? null : n;
}

// 'AAAA-MM-DD' -> 'DD/MM/AAAA'
export function data(iso) {
  if (!iso) return '—';
  const [a, m, d] = String(iso).slice(0, 10).split('-');
  return `${d}/${m}/${a}`;
}

export function hojeISO() {
  const h = new Date();
  return new Date(h.getTime() - h.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
}

// dias de hoje até a data (negativo = vencido)
export function diasAte(iso) {
  if (!iso) return null;
  const alvo = new Date(iso + 'T00:00:00');
  const hoje = new Date(hojeISO() + 'T00:00:00');
  return Math.round((alvo - hoje) / 86400000);
}

// selo de prazo: vencido / hoje / em N dias
export function seloPrazo(iso) {
  const d = diasAte(iso);
  if (d == null) return '';
  let cls = 'ok', txt = `em ${d} dias`;
  if (d < 0) { cls = 'vencido'; txt = `vencido há ${-d} dia${d === -1 ? '' : 's'}`; }
  else if (d === 0) { cls = 'alerta'; txt = 'vence hoje'; }
  else if (d === 1) { cls = 'alerta'; txt = 'vence amanhã'; }
  else if (d <= 5) cls = 'alerta';
  return `<span class="prazo ${cls}" title="${data(iso)}">${data(iso)} · ${txt}</span>`;
}

export function aviso(msg, tipo = 'ok') {
  let box = document.getElementById('avisos');
  if (!box) { box = document.createElement('div'); box.id = 'avisos'; document.body.append(box); }
  const el = document.createElement('div');
  el.className = `aviso ${tipo}`;
  el.textContent = msg;
  box.append(el);
  setTimeout(() => el.remove(), tipo === 'erro' ? 7000 : 3500);
}

export function erro(e, contexto = '') {
  console.error(contexto, e);
  aviso(`${contexto ? contexto + ': ' : ''}${e?.message || e}`, 'erro');
}

// Guarda/lê preferência leve do navegador (pode falhar em alguns contextos)
export const pref = {
  ler(chave, padrao = null) { try { return localStorage.getItem(chave) ?? padrao; } catch { return padrao; } },
  gravar(chave, v) { try { localStorage.setItem(chave, v); } catch { /* sem armazenamento */ } },
};

// Preenche um <form> a partir de um objeto e lê de volta
export function preencherForm(form, obj) {
  for (const el of form.elements) {
    if (!el.name) continue;
    const v = obj?.[el.name];
    if (el.dataset.tipo === 'numero') el.value = v == null ? '' : numero(v, Number(el.dataset.casas ?? 2));
    else el.value = v ?? '';
  }
}
export function lerForm(form) {
  const o = {};
  for (const el of form.elements) {
    if (!el.name) continue;
    let v = el.value.trim();
    if (el.dataset.tipo === 'numero') v = lerNumero(v);
    else if (el.dataset.tipo === 'inteiro') v = v === '' ? null : parseInt(v, 10);
    else if (v === '') v = null;
    o[el.name] = v;
  }
  return o;
}
