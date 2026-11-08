# Kit de Planejamento — Cantina Fácil

Kit para conduzir o planejamento do app **Cantina Fácil** e publicar o backlog como um **Kanban no GitHub Projects v2**, com histórias, critérios de aceite, BDD e diagramas Mermaid.

> **Usando em sala de aula?** Este repositório é um *template* em `F290-LDDM/cantina-facil-starter`. Clique em **Use this template → Create a new repository** e siga o [`GUIA-COMPARTILHAMENTO.md`](GUIA-COMPARTILHAMENTO.md) para o passo a passo do professor e dos alunos.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `PROMPT.md` | **Prompt mestre.** Contém papel, contrato de interação, 6 rodadas, templates, critérios de qualidade e comandos de publicação. É o arquivo principal. |
| `.opencode/agents/planejador-cantina.md` | Agente primário do OpenCode que executa o `PROMPT.md` com postura de especialista. |
| `.opencode/skills/github-projects-kanban/SKILL.md` | Playbook de publicação: labels, milestones, issues, campos, itens, views e verificação. |
| `.opencode/skills/github-projects-kanban/references/graphql.md` | Receitas GraphQL para campos, views, itens e valores. |
| `.opencode/skills/github-projects-kanban/scripts/preflight.sh` | Checagem somente leitura do ambiente (não altera nada). |
| `docs/exemplos/CF-014-acompanhar-status.md` | Exemplo de issue no padrão de qualidade esperado. |

## Pré-requisitos

- [OpenCode](https://opencode.ai) instalado (ou outro agente com shell e escrita de arquivos)
- [GitHub CLI](https://cli.github.com) (`gh`) autenticado
- `git` e `jq`
- Escopos `repo` e `project` no token

```bash
gh auth status
gh auth refresh -h github.com -s project,read:org
```

Verificação rápida:

```bash
bash .opencode/skills/github-projects-kanban/scripts/preflight.sh
```

## Como usar

### Opção 1 — Agente (recomendado)

```bash
opencode
```

Selecione o agente **`planejador-cantina`** e envie:

```
Comece o planejamento do Cantina Fácil pela Rodada 1.
```

### Opção 2 — Prompt em qualquer agente

Copie o conteúdo de `PROMPT.md` em uma sessão com acesso a shell, `git` e `gh`, e envie:

```
Leia PROMPT.md e comece pela Rodada 1.
```

### Opção 3 — Skill isolada

Se o plano já existe e você só quer publicar:

```
Use a skill github-projects-kanban para publicar docs/plano/backlog.json.
```

## Fluxo

```
Rodada 1  Produto e escopo          → docs/plano/01-visao.md
Rodada 2  Técnica e arquitetura     → docs/plano/02-arquitetura.md + 5 diagramas
Rodada 3  Processo e GitHub         → docs/plano/03-processo.md
Rodada 4  Plano consolidado         → docs/plano/04-backlog.md + backlog.json
          gate: "APROVO O PLANO"
Rodada 5  Dry-run                   → tabela do que será criado
          gate: "APROVO PUBLICAR"
Rodada 6  Publicação + verificação  → docs/plano/relatorio-publicacao.md
```

Nada é criado no GitHub antes do segundo gate.

## O que será gerado no GitHub

- **Labels** de tipo, área, prioridade e tamanho
- **Milestones** por sprint
- **Issues** com contexto, regras, critérios de aceite, BDD e notas técnicas
- **Project v2** com campos `Status`, `Prioridade`, `Tamanho`, `Sprint`, `Área` e `Estimativa`
- **Views**: Kanban, Backlog, Bugs, Roadmap e Meus itens
- **Vínculo** projeto ↔ repositório
- **Relatório** de publicação com contagens e divergências

## Estrutura de saída do planejamento

```
docs/plano/
├── 01-visao.md
├── 02-arquitetura.md
├── 03-processo.md
├── 04-backlog.md
├── backlog.json          # fonte de verdade da publicação
├── publicacao.jsonl      # log ID → issue → item
├── relatorio-publicacao.md
└── issues/
    ├── CF-001.md
    └── ...
```

## Segurança

- O agente **nunca** imprime tokens nem grava credenciais.
- Comandos de escrita no GitHub só rodam após `APROVO PUBLICAR`.
- `gh project delete`, `gh repo delete` e `gh api -X DELETE` estão bloqueados no agente.
- Em caso de duplicidade, o agente para e pede decisão em vez de apagar.

## Personalização

- **Outro produto?** Troque o nome e o backlog sugerido na seção 6 do `PROMPT.md`.
- **Outro backend?** Ajuste a Rodada 2 e as notas técnicas dos templates.
- **Outra equipe/processo?** Ajuste a Rodada 3 (capacidade, sprints, colunas).
- **Sem Project v2 ainda?** O fluxo cria o projeto do zero.
- **Projeto existente?** Informe o número na Rodada 3; o fluxo reutiliza e só completa o que falta.

## Solução de problemas

| Problema | Solução |
|---|---|
| `gh: command not found` | Instale o GitHub CLI e rode `gh auth login` |
| `missing required scope 'project'` | `gh auth refresh -h github.com -s project,read:org` |
| `Could not resolve to a ProjectV2` | Confira o número do projeto e o owner |
| `Resource not accessible by integration` | Autorize o token na organização (SSO) |
| Issues duplicadas | O agente deve parar; revise `docs/plano/publicacao.jsonl` |
| Acentos quebrados | Use `--body-file` com arquivo UTF-8 |

## Referências

- [GitHub Projects — documentação](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [GitHub CLI — manual](https://cli.github.com/manual/)
- [Flutter — documentação](https://docs.flutter.dev/)
- [Mermaid — sintaxe](https://mermaid.js.org/intro/)
