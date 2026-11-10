# Sistema de Engenharia — Eng. Higor Rodrigues

Sistema web pessoal de engenharia: tarefas, projetos de incêndio (PSCIP), obras e medições, orçamento, laudos e processos.
HTML + JavaScript puro, publicado no GitHub Pages; login e banco de dados no Supabase.

Eng. Higor Junior Rodrigues de Oliveira — Engenheiro Civil e de Segurança do Trabalho — CREA-MT 53684.

## Módulos

| Fase | Módulo | Situação |
| --- | --- | --- |
| 0 | Login, painel com prazos | pronto |
| 0 | Tarefas (Kanban): quadros, arrastar entre colunas, prioridade, prazo, etiqueta | pronto |
| 0 | Manutenções escolares (TMF / D3): demandas por empresa, OS, prazos, canceladas — importadas do quadro antigo | pronto |
| 1 | PSCIP: clientes, edificação, etapas no CBMMT, exigências, protocolo, ART, honorários, histórico | pronto |
| 2 | Obras e medições (BM): planilha, aditivos, boletim em PDF | a fazer |
| 3 | Relatório de obra / diário com fotos | a fazer |
| 4 | Orçamento SINAPI-MT: BDI, curva ABC, cronograma | a fazer |
| 5 | Laudos de vistoria e de avaliação | a fazer |
| 6 | Processos SIGED: prazos em dias úteis com feriados de Cuiabá | a fazer |

## Estrutura

```
index.html            Painel (exige login): indicadores e próximos prazos
login.html            Entrar, criar conta, recuperar senha
kanban/index.html     Quadros de tarefas
manutencoes/index.html Manutenções nas escolas (TMF / D3)
pscip/index.html      Projetos de incêndio
pscip/dados.js        Etapas, tipos de serviço, classificação por altura
comum/config.js       Endereço e chave PÚBLICA do Supabase
comum/supabase.js     Conexão, exigência de login, cabeçalho
comum/ui.js           R$, números, datas, prazos, avisos, formulários
comum/estilo.css      Visual do sistema
banco/                SQL do banco, em ordem (0001, 0002…) — rodar no SQL Editor do Supabase
```

## Banco de dados

- Rode os arquivos de `banco/` no **SQL Editor** do Supabase, na ordem dos números. Cada um pode ser rodado de novo sem estragar nada.
- Cada linha tem um dono (`user_id`); as regras de RLS fazem cada usuário ver e alterar só os próprios dados.
- Quem não fez login não consulta nenhuma tabela.
- Nunca coloque no código a chave secreta (`sb_secret_…` / `service_role`).

## Configuração do Supabase (uma vez)

Em **Authentication → URL Configuration**:
- Site URL: `https://cbhigoroliveira-bot.github.io/sistema-engenharia-higor-rodrigues/`
- Redirect URLs: `https://cbhigoroliveira-bot.github.io/sistema-engenharia-higor-rodrigues/**`
