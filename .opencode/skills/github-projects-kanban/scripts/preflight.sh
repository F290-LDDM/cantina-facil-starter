#!/usr/bin/env bash
# Pre-flight somente leitura para publicar no GitHub Projects v2.
# Uso: ./preflight.sh [owner] [repo] [project-number]
# Não cria, altera nem apaga nada.

set -uo pipefail

OWNER="${1:-}"
REPO="${2:-}"
PROJECT_NUMBER="${3:-}"

ok()   { printf '  [ok]   %s\n' "$1"; }
warn() { printf '  [warn] %s\n' "$1"; }
fail() { printf '  [fail] %s\n' "$1"; }

echo "== Ferramentas =="
for bin in gh git jq; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin: $("$bin" --version 2>/dev/null | head -n1)"
  else
    fail "$bin não encontrado"
  fi
done

echo
echo "== Autenticação =="
AUTH_OUTPUT="$(gh auth status 2>&1 || true)"
if printf '%s' "$AUTH_OUTPUT" | grep -q "Logged in"; then
  ok "gh autenticado"
else
  fail "gh não autenticado — rode: gh auth login"
fi

if printf '%s' "$AUTH_OUTPUT" | grep -q "project"; then
  ok "escopo 'project' presente"
else
  warn "escopo 'project' ausente — rode: gh auth refresh -h github.com -s project,read:org"
fi

if printf '%s' "$AUTH_OUTPUT" | grep -qi "repo"; then
  ok "escopo 'repo' presente"
else
  warn "escopo 'repo' ausente — inclua no gh auth login"
fi

printf '%s\n' "$AUTH_OUTPUT" | grep -v 'Token:' | sed 's/^/         /'

echo
echo "== Repositório =="
if [ -n "$OWNER" ] && [ -n "$REPO" ]; then
  if gh repo view "$OWNER/$REPO" --json nameWithOwner,visibility,defaultBranchRef >/dev/null 2>&1; then
    ok "repositório acessível: $OWNER/$REPO"
    gh repo view "$OWNER/$REPO" --json nameWithOwner,visibility,defaultBranchRef
  else
    fail "repositório inacessível ou inexistente: $OWNER/$REPO"
  fi
else
  warn "owner/repo não informados; pulando verificação"
fi

echo
echo "== Project v2 =="
if [ -n "$OWNER" ] && [ -n "$PROJECT_NUMBER" ]; then
  if PROJECT_JSON=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null); then
    ok "projeto acessível"
    printf '%s' "$PROJECT_JSON" | jq -r '"         \(.title) — \(.url)"' 2>/dev/null || true
  else
    fail "projeto inacessível: owner=$OWNER number=$PROJECT_NUMBER"
  fi
elif [ -n "$OWNER" ]; then
  warn "número do projeto não informado; listando projetos do owner"
  gh project list --owner "$OWNER" --format json 2>/dev/null || warn "não foi possível listar projetos"
else
  warn "owner não informado; pulando verificação de projeto"
fi

echo
echo "== Conclusão =="
echo "  Nada foi criado ou alterado. Revise os avisos antes de publicar."
