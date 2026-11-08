---
name: GitHub Projects Kanban
description: Publica um backlog de issues no GitHub Projects v2 (Kanban) de forma idempotente — labels, milestones, issues, campos, itens, views, vínculo com repositório e verificação final.
---

# GitHub Projects Kanban

Playbook operacional para transformar `docs/plano/backlog.json` em um Kanban funcional no GitHub Projects v2.

## Quando usar

- Depois de o executor aprovar o plano (`APROVO O PLANO`).
- Ao criar/atualizar labels, milestones, issues, campos, itens e views de um Project v2.
- Ao verificar ou corrigir uma publicação parcial.

## Regras de segurança

1. **Só execute após `APROVO PUBLICAR`.**
2. **Nunca apague** issues, campos ou projetos. Em caso de erro, corrija ou peça decisão.
3. **Nunca imprima tokens.** Use `gh auth`.
4. **Idempotência sempre:** busque `[CF-xxx]` antes de criar.
5. **Não invente IDs.** Liste campos e opções com `gh project field-list`.
6. Trabalhe com `set -euo pipefail` e registre cada ação em `docs/plano/publicacao.jsonl`.

## 0. Pré-flight (somente leitura)

```bash
gh --version          # confira suporte a --field/--value por nome (presente na 2.100)
gh auth status        # exige escopos repo e project
git --version
jq --version
```

Se faltar o escopo `project`, o **executor** deve rodar (comando interativo):

```bash
gh auth refresh -h github.com -s project,read:org
```

Para organização com SSO, autorize o token na organização antes de continuar.

## 1. Variáveis de trabalho

```bash
export OWNER="<usuario-ou-org>"
export REPO="cantina-facil"
export PROJECT_NUMBER="<numero>"      # vazio se for criar
export PROJECT_TITLE="Cantina Fácil — Kanban"
export BACKLOG="docs/plano/backlog.json"
export OUT="docs/plano"
mkdir -p "$OUT/issues"
```

Confirme com o executor antes de exportar. Nunca deduza o owner. Use o **login real** (não `@me`), porque as consultas GraphQL de projeto precisam do login.

## 2. Repositório

```bash
gh repo view "$OWNER/$REPO" --json nameWithOwner,visibility,defaultBranchRef
```

Se não existir, peça aprovação e então:

```bash
gh repo create "$OWNER/$REPO" --private \
  --description "Cantina Fácil — app Flutter de pedidos" \
  --clone
```

## 3. Labels

Crie/atualize com `--force` (idempotente):

```bash
gh label create "tipo:feature" --repo "$OWNER/$REPO" --color "1D76DB" --description "Nova funcionalidade" --force
gh label create "tipo:bug"     --repo "$OWNER/$REPO" --color "D73A4A" --description "Defeito" --force
gh label create "tipo:tech"    --repo "$OWNER/$REPO" --color "5319E7" --description "Trabalho técnico" --force
gh label create "tipo:docs"    --repo "$OWNER/$REPO" --color "0075CA" --description "Documentação" --force
gh label create "tipo:spike"   --repo "$OWNER/$REPO" --color "FBCA04" --description "Investigação" --force

gh label create "area:cardapio" --repo "$OWNER/$REPO" --color "0E8A16" --description "Catálogo e cardápio" --force
gh label create "area:pedido"   --repo "$OWNER/$REPO" --color "0E8A16" --description "Carrinho e pedido" --force
gh label create "area:pagamento" --repo "$OWNER/$REPO" --color "0E8A16" --description "Pagamentos" --force
gh label create "area:conta"    --repo "$OWNER/$REPO" --color "0E8A16" --description "Conta e acesso" --force
gh label create "area:admin"    --repo "$OWNER/$REPO" --color "0E8A16" --description "Gestão da cantina" --force
gh label create "area:infra"    --repo "$OWNER/$REPO" --color "0E8A16" --description "Infra, CI e qualidade" --force

gh label create "prio:p0" --repo "$OWNER/$REPO" --color "B60205" --description "Bloqueante" --force
gh label create "prio:p1" --repo "$OWNER/$REPO" --color "D93F0B" --description "Alta" --force
gh label create "prio:p2" --repo "$OWNER/$REPO" --color "FBCA04" --description "Média" --force
gh label create "prio:p3" --repo "$OWNER/$REPO" --color "0E8A16" --description "Baixa" --force

gh label create "tam:pp" --repo "$OWNER/$REPO" --color "C5DEF5" --description "1 ponto" --force
gh label create "tam:p"  --repo "$OWNER/$REPO" --color "BFD4F2" --description "2 pontos" --force
gh label create "tam:m"  --repo "$OWNER/$REPO" --color "BFDADC" --description "3 pontos" --force
gh label create "tam:g"  --repo "$OWNER/$REPO" --color "D4C5F9" --description "5+ pontos" --force

gh label create "bloqueado" --repo "$OWNER/$REPO" --color "000000" --description "Impedimento ativo" --force
gh label create "dependencia-externa" --repo "$OWNER/$REPO" --color "E99695" --description "Depende de terceiros" --force
```

Verificação:

```bash
gh label list --repo "$OWNER/$REPO" --limit 100
```

## 4. Milestones (sprints)

`gh` não tem subcomando de milestone; use a API REST:

```bash
gh api "repos/$OWNER/$REPO/milestones" \
  -f title="Sprint 1" \
  -f description="Meta: fundação e cardápio" \
  -f due_on="2026-11-20T23:59:59Z"
```

Idempotência:

```bash
gh api "repos/$OWNER/$REPO/milestones?state=all&per_page=100" \
  --jq '.[] | select(.title=="Sprint 1") | .number'
```

Se retornar número, use `PATCH` em vez de `POST`:

```bash
gh api -X PATCH "repos/$OWNER/$REPO/milestones/<numero>" -f due_on="2026-11-20T23:59:59Z"
```

## 5. Issues

### 5.1 Localizar existente

```bash
gh issue list --repo "$OWNER/$REPO" --state all --limit 100 \
  --search 'in:title "[CF-004]"' --json number,title,url,state
```

- 0 resultados → criar.
- 1 resultado → atualizar com `gh issue edit <numero> --body-file ...`.
- 2+ resultados → **parar** e pedir decisão.

### 5.2 Criar

```bash
gh issue create \
  --repo "$OWNER/$REPO" \
  --title "[CF-004] Consultar cardápio do dia por categoria" \
  --body-file "$OUT/issues/CF-004.md" \
  --label "tipo:feature,area:cardapio,prio:p1,tam:m" \
  --milestone "Sprint 1"
```

A saída é a URL da issue. Extraia o número:

```bash
ISSUE_URL=$(gh issue create ... )
ISSUE_NUMBER=$(basename "$ISSUE_URL")
```

### 5.3 Atualizar

```bash
gh issue edit "$ISSUE_NUMBER" --repo "$OWNER/$REPO" \
  --title "[CF-004] Consultar cardápio do dia por categoria" \
  --body-file "$OUT/issues/CF-004.md" \
  --add-label "tipo:feature,area:cardapio,prio:p1,tam:m" \
  --milestone "Sprint 1"
```

> `--add-label` não remove labels antigas. Se precisar substituir, use `--remove-label` antes ou revise manualmente.

### 5.4 Loop a partir do backlog

```bash
jq -c '.itens[]' "$BACKLOG" | while read -r item; do
  ID=$(jq -r '.id' <<<"$item")
  TITULO=$(jq -r '.titulo' <<<"$item")
  BODY=$(jq -r '.corpo_arquivo' <<<"$item")
  LABELS=$(jq -r '.labels | join(",")' <<<"$item")
  MILESTONE=$(jq -r '.milestone // empty' <<<"$item")

  if [ ! -f "$BODY" ]; then
    echo "ERRO: corpo ausente para $ID: $BODY" >&2
    continue
  fi

  EXISTENTE=$(gh issue list --repo "$OWNER/$REPO" --state all --limit 100 \
    --search "in:title \"[$ID]\"" --json number --jq '.[0].number // empty')

  if [ -n "$EXISTENTE" ]; then
    gh issue edit "$EXISTENTE" --repo "$OWNER/$REPO" --title "[$ID] $TITULO" \
      --body-file "$BODY" --add-label "$LABELS" ${MILESTONE:+--milestone "$MILESTONE"}
    echo "{\"id\":\"$ID\",\"numero\":$EXISTENTE,\"acao\":\"update\"}" >> "$OUT/publicacao.jsonl"
  else
    URL=$(gh issue create --repo "$OWNER/$REPO" --title "[$ID] $TITULO" \
      --body-file "$BODY" --label "$LABELS" ${MILESTONE:+--milestone "$MILESTONE"})
    echo "{\"id\":\"$ID\",\"numero\":$(basename "$URL"),\"url\":\"$URL\",\"acao\":\"create\"}" >> "$OUT/publicacao.jsonl"
  fi
done
```

## 6. Project v2

### 6.1 Criar ou reutilizar

```bash
if [ -z "${PROJECT_NUMBER:-}" ]; then
  gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json \
    | tee "$OUT/project.json"
  PROJECT_NUMBER=$(jq -r '.number' "$OUT/project.json")
fi
```

### 6.2 Obter o node ID

```bash
if gh api graphql -f query='query($l:String!){user(login:$l){login}}' -f l="$OWNER" --jq '.data.user.login' >/dev/null 2>&1; then
  OWNER_TYPE="user"
else
  OWNER_TYPE="organization"
fi

if [ "$OWNER_TYPE" = "user" ]; then
  gh api graphql -f query='
  query($login: String!, $number: Int!) {
    user(login: $login) { projectV2(number: $number) { id number title url } }
  }' -f login="$OWNER" -F number="$PROJECT_NUMBER"
else
  gh api graphql -f query='
  query($login: String!, $number: Int!) {
    organization(login: $login) { projectV2(number: $number) { id number title url } }
  }' -f login="$OWNER" -F number="$PROJECT_NUMBER"
fi
```

Guarde `.data.*.projectV2.id` em `PROJECT_ID`.

## 7. Campos

### 7.1 Criar via CLI

```bash
gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
  --name "Prioridade" --data-type SINGLE_SELECT \
  --single-select-options "P0 - Bloqueante,P1 - Alta,P2 - Média,P3 - Baixa"

gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
  --name "Tamanho" --data-type SINGLE_SELECT \
  --single-select-options "1,2,3,5,8,13"

gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
  --name "Sprint" --data-type SINGLE_SELECT \
  --single-select-options "Backlog,Sprint 1,Sprint 2,Sprint 3,Sprint 4,Sprint 5,Sprint 6"

gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
  --name "Área" --data-type SINGLE_SELECT \
  --single-select-options "Cardápio,Pedido,Pagamento,Conta,Admin,Infra"

gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
  --name "Estimativa" --data-type NUMBER
```

> `gh project field-create` não cria `ITERATION`. Se quiser iteração nativa, use `createProjectV2Field` com `dataType: ITERATION` (ver `references/graphql.md`).

### 7.2 Conferir antes de usar

```bash
gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
  | jq '.fields[] | {id, name, type, options}'
```

Nunca presuma o ID de um campo ou de uma opção.

### 7.3 Ajustar as colunas do Status

O campo `Status` já existe. Para renomear/adicionar opções, use `updateProjectV2Field` (ver `references/graphql.md`).

> **Atenção:** essa mutation **substitui** todas as opções. Em projeto novo, sem itens, é seguro. Em projeto existente, pode limpar valores. Confirme antes.

## 8. Itens e valores

```bash
gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" \
  --url "$ISSUE_URL" --format json
```

Se a issue já estiver no projeto, o comando pode falhar. Verifique antes:

```bash
gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --query "..." --format json
```

Defina um campo por chamada:

```bash
gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Status" --value "Ready"

gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Prioridade" --value "P1 - Alta"

gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Tamanho" --value "3"

gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Sprint" --value "Sprint 1"

gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Área" --value "Cardápio"

gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE_URL" \
  --field "Estimativa" --number 3
```

Em `gh` anterior a 2.100, use IDs:

```bash
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" \
  --field-id "$FIELD_ID" --single-select-option-id "$OPTION_ID"
```

### 8.1 Loop de itens + campos

```bash
jq -c '.itens[]' "$BACKLOG" | while read -r item; do
  ID=$(jq -r '.id' <<<"$item")
  NUM=$(jq -r --arg id "$ID" 'select(.id==$id) | .numero' "$OUT/publicacao.jsonl" | tail -n1)
  [ -z "$NUM" ] && { echo "sem número para $ID" >&2; continue; }
  URL="https://github.com/$OWNER/$REPO/issues/$NUM"

  # Auto-add pode já ter inserido o item; falha aqui não é fatal.
  gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" >/dev/null 2>&1 || true

  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Status" --value "$(jq -r '.status' <<<"$item")"
  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Prioridade" --value "$(jq -r '.prioridade' <<<"$item")"
  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Tamanho" --value "$(jq -r '.tamanho' <<<"$item")"
  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Sprint" --value "$(jq -r '.sprint' <<<"$item")"
  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Área" --value "$(jq -r '.area' <<<"$item")"
  gh project item-edit "$PROJECT_NUMBER" --owner "$OWNER" --url "$URL" \
    --field "Estimativa" --number "$(jq -r '.tamanho' <<<"$item")"
done
```

## 9. Views

Use GraphQL. Crie e depois ajuste o filtro:

```bash
PROJECT_ID="<node-id>"

gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $layout: ProjectV2ViewLayout!) {
  createProjectV2View(input: {projectId: $projectId, name: $name, layout: $layout}) {
    projectV2View { id name number }
  }
}' -f projectId="$PROJECT_ID" -f name="Kanban — Sprint atual" -f layout=BOARD_LAYOUT
```

Views sugeridas:

| Nome | Layout | Filtro |
|---|---|---|
| Kanban — Sprint atual | `BOARD_LAYOUT` | `-status:Done` |
| Backlog | `TABLE_LAYOUT` | `status:Backlog` |
| Bugs | `TABLE_LAYOUT` | `label:"tipo:bug"` |
| Roadmap | `ROADMAP_LAYOUT` | — |
| Meus itens | `TABLE_LAYOUT` | `assignee:@me` |

Aplicar filtro:

```bash
gh api graphql -f query='
mutation($viewId: ID!, $filter: String!) {
  updateProjectV2View(input: {viewId: $viewId, filter: $filter}) {
    projectV2View { id name }
  }
}' -f viewId="<view-id>" -f filter='-status:Done'
```

Limitações conhecidas da API: `configuration` só expõe `visibleFieldIds`; agrupamento, ordenação e demais preferências podem exigir ajuste manual na UI. Se a view não abrir como esperado, registre no relatório e oriente o ajuste.

## 10. Vincular projeto ao repositório

```bash
gh project link "$PROJECT_NUMBER" --owner "$OWNER" --repo "$OWNER/$REPO"
```

## 11. Workflows (UI)

Não há mutation pública estável para criar workflows. Oriente o executor:

1. Abrir o Project → menu `⋯` → **Workflows**.
2. Ativar **Auto-add to project** para o repositório.
3. Ativar **Item closed** → status `Done`.
4. Ativar **Pull request merged** → status `Done`.
5. Ativar **Auto-archive** para itens concluídos há mais de 30 dias (opcional).

## 12. Verificação final

```bash
# --format json já inclui todos os valores de campo; NÃO combine com --field.
gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 500 \
  --format json > "$OUT/items.json"
```

Estrutura do JSON (chaves de campo em camelCase, a partir do nome do campo):

```json
{
  "totalCount": 42,
  "items": [
    {
      "id": "PVTI_...",
      "content": { "type": "Issue", "title": "...", "number": 4, "url": "...", "body": "..." },
      "status": "Ready",
      "prioridade": "P1 - Alta",
      "tamanho": "3",
      "sprint": "Sprint 1",
      "área": "Cardápio"
    }
  ]
}
```

```bash
jq '{total: .totalCount, itens: (.items|length)}' "$OUT/items.json"

jq '[.items[] | select((.status // "") == "") | .content.title]' "$OUT/items.json"
jq '[.items[] | select((.prioridade // "") == "") | .content.title]' "$OUT/items.json"
jq '[.items[] | select((.sprint // "") == "") | .content.title]' "$OUT/items.json"
jq '[.items[].content.title] | group_by(.) | map(select(length > 1))' "$OUT/items.json"
```

> Acentuação importa: `Área` vira `área`. Se o campo não aparecer, inspecione as chaves com `jq '.items[0] | keys'`.

Confirme também:

```bash
gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json
gh project field-list "$PROJECT_NUMBER" --owner "$OWNER"
```

Checklist:

- [ ] Itens = total do backlog
- [ ] Sem títulos duplicados
- [ ] Todos com Status, Prioridade, Tamanho, Sprint e Área
- [ ] Views criadas
- [ ] Projeto vinculado ao repositório
- [ ] `docs/plano/relatorio-publicacao.md` gerado

## 13. Tratamento de erros

| Erro | Causa | Correção |
|---|---|---|
| `unknown owner type` | Owner inválido | Conferir `gh auth status` e o login |
| `Could not resolve to a ProjectV2` | Número errado / sem escopo | `gh auth refresh -s project`; reconferir número |
| `Resource not accessible by integration` | SSO ou permissão | Autorizar o token na organização |
| `HTTP 403` | Rate limit | Aguardar; lotear; usar `--limit` |
| `already exists` no item-add | Issue já no projeto | Buscar item existente e só editar campos |
| Campo não encontrado | Nome divergente | `gh project field-list` e usar o nome exato |
| Acentuação quebrada | Encoding | `--body-file` em UTF-8 |

## 14. Saída esperada

- `docs/plano/publicacao.jsonl` — log de cada criação/atualização
- `docs/plano/relatorio-publicacao.md` — contagens, links, divergências e próximos passos
- Project e views funcionando, com link entregue ao executor
