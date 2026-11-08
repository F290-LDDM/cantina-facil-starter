# Guia de compartilhamento com a turma

Como distribuir o kit do **Cantina Fácil** para vários alunos ou grupos, cada um com seu próprio repositório e seu próprio Kanban.

## Recomendação em uma frase

Use um **repositório-template no GitHub** (ou **GitHub Classroom** se você precisar corrigir/avaliar) e garanta **um repositório + um Project v2 por grupo**.

> Regra de ouro: **nunca** compartilhe o mesmo repositório ou o mesmo Project entre grupos. Labels, issues e campos colidem e o Kanban perde a utilidade.

## Template já publicado

| Item | Valor |
|---|---|
| Repositório | <https://github.com/F290-LDDM/cantina-facil-starter> |
| Organização | `F290-LDDM` |
| Visibilidade | **privada** |
| Template | ✅ habilitado (`isTemplate: true`) |
| Branch padrão | `main` |

> Por ser **privado**, os alunos só conseguem usar o botão **Use this template** se forem membros da organização `F290-LDDM` com permissão de **leitura** no repositório. Veja a seção *Liberar acesso*.

## Comparativo

| Opção | Ideal para | Prós | Contras |
|---|---|---|---|
| **Repositório-template** (recomendado) | Turma com grupos, cada um com seu repo/Project | Isolamento, versionamento, `.opencode` viaja junto, atualização via upstream | Exige organização e um push inicial |
| **GitHub Classroom** | Avaliação individual ou por grupo | Cria repos automaticamente, prazos, painel do professor | Configuração inicial maior; menos flexível para times |
| **ZIP / Drive** | Oficina rápida, sem Git | Simples | Sem versionamento nem atualização; risco de perder a pasta oculta `.opencode` |
| **Fork** | Alunos já dominam Git | Rápido | Rede de forks confusa; PRs vão para o upstream; menos controle |
| **Repo único com branches por grupo** | Nunca | — | Colisão de labels e Projects; difícil isolar e corrigir |

---

## Opção A — Repositório-template (recomendado)

### 1. Professor: organização da turma

A organização `F290-LDDM` já existe e a conta `esdrascps` tem papel de **admin**. Nenhuma ação necessária aqui.

### 2. Professor: publicar o kit como template

✅ **Já executado.** Para referência, o comando usado foi:

```bash
cd "/Users/esdras/Documents/Default Project"
git init -b main
git add -A
git commit -m "Kit de planejamento agil - Cantina Facil"
gh repo create F290-LDDM/cantina-facil-starter --private --source=. --remote=origin --push
gh repo edit F290-LDDM/cantina-facil-starter --template
```

Se precisar republicar do zero em outra organização, troque `F290-LDDM` pelo owner desejado.

Confirme que a pasta oculta foi versionada:

```bash
git ls-files | grep -E '^\.opencode/' | head
```

Devem aparecer o agente e a skill. Se não aparecerem, rode `git add -A` novamente.

### 3. Professor: liberar acesso

O template é **privado**. Duas opções:

**A. Time da organização (recomendado)**

```bash
# criar o time (uma vez)
gh api orgs/F290-LDDM/teams -f name=alunos -f privacy=closed

# dar leitura no template ao time
gh api -X PUT "orgs/F290-LDDM/teams/alunos/repos/F290-LDDM/cantina-facil-starter" \
  -f permission=pull
```

Depois adicione cada aluno ao time (pela UI da organização ou convidando por e-mail). Só membros do time verão o repositório.

**B. Template público**

Deixe o template público e mantenha os repositórios dos grupos privados:

```bash
gh repo edit F290-LDDM/cantina-facil-starter --visibility public --accept-visibility-change-consequences
```

É o caminho mais simples e não expõe o trabalho dos grupos.

> Para conferir quem já tem acesso: `gh api repos/F290-LDDM/cantina-facil-starter/collaborators --jq '.[].login'`

### 4. Aluno: criar o repositório do grupo

1. Abrir `https://github.com/F290-LDDM/cantina-facil-starter`.
2. Clicar em **Use this template → Create a new repository**.
3. Nome sugerido: `cantina-facil-grupo-01`.
4. Owner: `F290-LDDM` (ou a conta do grupo). Visibilidade: **Private**.
5. Criar e clonar:

```bash
git clone https://github.com/F290-LDDM/cantina-facil-grupo-01.git
cd cantina-facil-grupo-01
```

### 5. Aluno: preparar o ambiente

```bash
gh --version
gh auth status
gh auth refresh -h github.com -s project,read:org   # só se faltar o escopo project
flutter --version
opencode --version
```

Validação somente leitura do kit:

```bash
bash .opencode/skills/github-projects-kanban/scripts/preflight.sh <owner> <repo>
```

> Em organização com SSO, autorize o token na organização antes de publicar.

### 6. Aluno: executar o planejamento

```bash
opencode
```

Selecione o agente **`planejador-cantina`** e envie:

```
Leia PROMPT.md e comece pela Rodada 1.
```

Ou, em qualquer agente com shell:

```
Leia PROMPT.md e comece pela Rodada 1.
```

### 7. Aluno: publicar no GitHub Projects

O fluxo só publica depois de dois gates explícitos:

1. `APROVO O PLANO` — valida escopo, arquitetura, backlog e diagramas.
2. `APROVO PUBLICAR` — valida o dry-run de labels, milestones, issues, campos e views.

Cada grupo cria o **próprio Project v2**. O prompt já pergunta owner, repo e número do projeto na Rodada 3.

---

## Opção B — GitHub Classroom (se houver avaliação)

Use quando você precisa:

- criar um repositório por aluno ou por grupo automaticamente;
- controlar prazo de entrega;
- ver todos os repositórios em um painel;
- corrigir com feedback por issue/PR.

Passos:

1. Acesse `https://classroom.github.com` e crie uma classroom vinculada à organização.
2. Crie um **assignment**:
   - tipo **Group assignment** (se for por grupo) ou individual;
   - **Starter code repository** = `cantina-facil-starter`;
   - visibilidade **private**;
   - prazo e regras de aceitação.
3. Compartilhe o **accept link** com a turma.
4. Cada aluno/grupo aceita e recebe um repositório próprio, já com `PROMPT.md` e `.opencode/`.

> O Classroom cria o repositório, mas **não cria o Project v2**. Cada grupo continua responsável por rodar o prompt e publicar o Kanban na própria conta/organização.

---

## Regras de ouro para a turma

1. **Um repositório e um Project por grupo.** Nunca compartilhe o Project do professor.
2. **Cada aluno usa a própria conta GitHub.** Nunca compartilhe token, senha ou sessão do `gh`.
3. **A pasta `.opencode/` é oculta, mas precisa ser versionada.** Confira com `git ls-files | grep .opencode`.
4. **`PROMPT.md` é a fonte de verdade.** Se o grupo quiser adaptar, faça um commit explicando o motivo.
5. **Não versione segredos:** `.env`, keystores, `local.properties`, tokens.
6. **Mantenha `docs/plano/` no repositório.** É a evidência do planejamento e ajuda na avaliação.
7. **Commits pequenos e com sentido.** O histórico também é avaliado em muitos cursos.
8. **Proteja a `main`** nos repositórios dos grupos: PR obrigatório e pelo menos uma revisão.
9. **Se o projeto tiver app + backend**, vincule os dois repositórios ao mesmo Project e diferencie por `Área`.
10. **Não edite issues manualmente sem necessidade.** O `backlog.json` é a fonte de verdade; mudanças devem ser refletidas nele.

---

## Como atualizar o kit depois da distribuição

Cópias feitas a partir de um template **não recebem atualizações automaticamente**. Se você corrigir o `PROMPT.md` ou a skill:

```bash
# no repositório do grupo
git remote add kit https://github.com/F290-LDDM/cantina-facil-starter.git
git fetch kit
git merge kit/main --allow-unrelated-histories
```

Resolva conflitos em `PROMPT.md` e `.opencode/` manualmente. Se preferir, distribua apenas os arquivos alterados e peça um commit.

---

## Checklist de distribuição

- [ ] Organização da turma criada
- [ ] `cantina-facil-starter` publicado e marcado como template
- [ ] `.opencode/` e `PROMPT.md` presentes no repositório
- [ ] `.gitignore` presente
- [ ] Alunos com acesso de leitura (ou template público)
- [ ] Cada grupo criou o repositório a partir do template
- [ ] Cada grupo rodou `gh auth status` e tem os escopos `repo` e `project`
- [ ] Cada grupo criou o próprio Project v2
- [ ] Professor com acesso de admin à organização (para suporte)
- [ ] Link do template e instruções enviados no canal da turma

---

## Mensagem pronta para o grupo

```text
Olá, pessoal!

O kit de planejamento do Cantina Fácil está em:
https://github.com/F290-LDDM/cantina-facil-starter

Passos:
1. Clique em "Use this template" → "Create a new repository".
2. Nome: cantina-facil-grupo-XX. Marque como privado.
3. Clone o repositório e abra a pasta no terminal.
4. Rode: gh auth status
   Se faltar o escopo project:
   gh auth refresh -h github.com -s project,read:org
5. Abra o OpenCode na pasta e selecione o agente planejador-cantina.
6. Envie: "Leia PROMPT.md e comece pela Rodada 1."
7. Respondam uma rodada por vez. Nada é publicado no GitHub sem "APROVO PUBLICAR".
8. Cada grupo usa o próprio repositório e o próprio Project v2.

Não compartilhem tokens nem usem a conta de outra pessoa.
Dúvidas: <SEU_CANAL_DE_SUPORTE>
```

---

## Observações finais

- **OpenCode não é obrigatório.** O `PROMPT.md` funciona em qualquer agente com acesso a shell, `git` e `gh`. O agente e a skill são um atalho para quem usa OpenCode.
- **Codespaces é opcional.** O `GITHUB_TOKEN` do Codespaces costuma não ter o escopo `project`; nesse caso, o aluno precisa autenticar com um PAT ou rodar localmente.
- **Licença:** se o template for público, inclua um `LICENSE` (MIT para código, CC BY-NC-SA para material didático) e combine com a instituição.
- **Privacidade:** não coloque nomes, e-mails ou matrículas de alunos em issues públicas. Use repositórios privados.
