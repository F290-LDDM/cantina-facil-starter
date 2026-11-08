# Receitas GraphQL — GitHub Projects v2

Complemento da skill `github-projects-kanban`. Use somente depois de `APROVO PUBLICAR`.

## Convenções

- `OWNER`, `REPO`, `PROJECT_NUMBER`, `PROJECT_ID`, `ISSUE_URL`, `ISSUE_ID`, `ITEM_ID`, `FIELD_ID`, `OPTION_ID` são variáveis já resolvidas.
- `gh api graphql -f` envia strings; `-F` converte tipos (números, booleanos).
- Para listas/objetos, use `--input -` com JSON montado por `jq` (mais seguro que escapar inline).
- Toda mutation retorna erro em `.errors`; verifique com `jq -e '.errors == null'`.

## 1. Resolver o Project v2

```bash
# Descobrir o tipo de owner
if gh api graphql -f query='query($l:String!){user(login:$l){login}}' -f l="$OWNER" \
     --jq '.data.user.login' >/dev/null 2>&1; then
  OWNER_TYPE="user"
else
  OWNER_TYPE="organization"
fi

# Consultar
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

Guarde `PROJECT_ID`:

```bash
PROJECT_ID=$(gh api graphql -f query='
query($login: String!, $number: Int!) {
  user(login: $login) { projectV2(number: $number) { id } }
}' -f login="$OWNER" -F number="$PROJECT_NUMBER" --jq '.data.user.projectV2.id')
```

## 2. Listar campos e opções

```bash
gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 50) {
        nodes {
          ... on ProjectV2Field { id name dataType }
          ... on ProjectV2SingleSelectField { id name dataType options { id name } }
          ... on ProjectV2IterationField { id name dataType }
        }
      }
    }
  }
}' -f projectId="$PROJECT_ID" | jq '.data.node.fields.nodes'
```

## 3. Criar campo single select

```bash
jq -n --arg pid "$PROJECT_ID" '{
  query: "mutation($input: CreateProjectV2FieldInput!) { createProjectV2Field(input: $input) { projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } } } }",
  variables: {
    input: {
      projectId: $pid,
      name: "Prioridade",
      dataType: "SINGLE_SELECT",
      singleSelectOptions: [
        {name: "P0 - Bloqueante", color: "RED",    description: "Impede entrega"},
        {name: "P1 - Alta",       color: "ORANGE", description: "Entra na sprint atual"},
        {name: "P2 - Média",      color: "YELLOW", description: "Próximas sprints"},
        {name: "P3 - Baixa",      color: "GRAY",   description: "Backlog"}
      ]
    }
  }
}' | gh api graphql --input -
```

Cores válidas: `BLUE`, `GRAY`, `GREEN`, `ORANGE`, `PINK`, `PURPLE`, `RED`, `YELLOW`.

## 4. Substituir as opções do Status

> **Cuidado:** `updateProjectV2Field` substitui **todas** as opções. Em projeto com itens, inclua o `id` das opções existentes para preservar os valores. Em projeto novo, é seguro.

```bash
STATUS_FIELD_ID=$(gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      field(name: "Status") { ... on ProjectV2SingleSelectField { id } }
    }
  }
}' -f projectId="$PROJECT_ID" --jq '.data.node.field.id')

jq -n --arg fid "$STATUS_FIELD_ID" '{
  query: "mutation($input: UpdateProjectV2FieldInput!) { updateProjectV2Field(input: $input) { projectV2Field { ... on ProjectV2SingleSelectField { id name options { id name } } } } }",
  variables: {
    input: {
      fieldId: $fid,
      singleSelectOptions: [
        {name: "Backlog",      color: "GRAY",   description: "Não priorizado"},
        {name: "Ready",        color: "BLUE",   description: "Pronto para começar"},
        {name: "Em progresso", color: "YELLOW", description: "Em desenvolvimento"},
        {name: "Em revisão",   color: "PURPLE", description: "Aguardando review"},
        {name: "Done",         color: "GREEN",  description: "Concluído"}
      ]
    }
  }
}' | gh api graphql --input -
```

Para preservar opções existentes, busque os IDs antes e inclua `id` em cada objeto.

## 5. Criar campo de iteração (sprints nativas)

```bash
jq -n --arg pid "$PROJECT_ID" '{
  query: "mutation($input: CreateProjectV2FieldInput!) { createProjectV2Field(input: $input) { projectV2Field { ... on ProjectV2IterationField { id name configuration { iterations { id title startDate duration } } } } } }",
  variables: {
    input: {
      projectId: $pid,
      name: "Sprint",
      dataType: "ITERATION",
      iterationConfiguration: {
        startDate: "2026-11-09",
        duration: 7,
        iterations: [
          {title: "Sprint 1", startDate: "2026-11-09", duration: 7},
          {title: "Sprint 2", startDate: "2026-11-16", duration: 7},
          {title: "Sprint 3", startDate: "2026-11-23", duration: 7}
        ]
      }
    }
  }
}' | gh api graphql --input -
```

## 6. Criar views

```bash
gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $layout: ProjectV2ViewLayout!) {
  createProjectV2View(input: {projectId: $projectId, name: $name, layout: $layout}) {
    projectV2View { id name number }
  }
}' -f projectId="$PROJECT_ID" -f name="Kanban — Sprint atual" -f layout=BOARD_LAYOUT
```

Layouts: `BOARD_LAYOUT`, `TABLE_LAYOUT`, `ROADMAP_LAYOUT`.

Aplicar filtro:

```bash
gh api graphql -f query='
mutation($viewId: ID!, $filter: String!) {
  updateProjectV2View(input: {viewId: $viewId, filter: $filter}) {
    projectV2View { id name }
  }
}' -f viewId="$VIEW_ID" -f filter='-status:Done'
```

Exemplos de filtro:

| Objetivo | Filtro |
|---|---|
| Esconder concluídos | `-status:Done` |
| Só backlog | `status:Backlog` |
| Bugs | `label:"tipo:bug"` |
| Minha fila | `assignee:@me` |
| Sprint 1 | `sprint:"Sprint 1"` |
| Sem responsável | `no:assignee` |

> A API de views expõe apenas `visibleFieldIds` em `configuration`. Agrupamento e ordenação podem precisar de ajuste manual na UI.

## 7. Adicionar issue ao projeto

```bash
ISSUE_ID=$(gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --json id --jq '.id')

gh api graphql -f query='
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
    item { id }
  }
}' -f projectId="$PROJECT_ID" -f contentId="$ISSUE_ID"
```

## 8. Definir valor de campo

Single select:

```bash
gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId,
    itemId: $itemId,
    fieldId: $fieldId,
    value: {singleSelectOptionId: $optionId}
  }) {
    projectV2Item { id }
  }
}' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" \
   -f fieldId="$FIELD_ID" -f optionId="$OPTION_ID"
```

Número:

```graphql
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $number: Float!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId, itemId: $itemId, fieldId: $fieldId,
    value: {number: $number}
  }) { projectV2Item { id } }
}
```

Data:

```graphql
value: {date: "2026-11-20"}
```

Texto:

```graphql
value: {text: "..."}
```

## 9. Consultar itens com valores

```bash
gh api graphql -f query='
query($projectId: ID!, $cursor: String) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          content {
            ... on Issue { number title url state }
            ... on PullRequest { number title url state }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2Field { name } ... on ProjectV2SingleSelectField { name } }
              }
              ... on ProjectV2ItemFieldNumberValue {
                number
                field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldTextValue {
                text
                field { ... on ProjectV2Field { name } }
              }
            }
          }
        }
      }
    }
  }
}' -f projectId="$PROJECT_ID" | jq '.data.node.items.nodes'
```

Paginação: repita passando `-f cursor="<endCursor>"` enquanto `hasNextPage` for `true`.

## 10. Boas práticas

1. Valide a resposta: `... | jq -e '.errors == null'` e pare se houver erro.
2. Uma mutation por campo; não tente atualizar vários campos de uma vez.
3. Prefira nomes exatos retornados pela API; não normalize acentos.
4. Registre cada ID resolvido em `docs/plano/publicacao.jsonl`.
5. Em caso de `403`, aguarde e reduza o lote; não faça retry infinito.
