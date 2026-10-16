# PermitPath

Permit readiness for short-term rental hosts. Rules are versioned data; eligibility verdicts come from deterministic code over the rules table, never from a model. A Raken AI Labs product; Airbnb is the first customer, for City of Los Angeles hosts.

## Read first, every session and after any compaction

1. This file.
2. The newest file in `ai_docs/handoff/` (local only): where the last session left things.
3. `GLOSSARY.md`, `docs/adr/` and `docs/spec/` once they exist: the decisions.
4. `ai_docs/brief.md`, then `ai_docs/research/` newest first. Research notes are dated and never edited after the fact; a correction is a new dated note.

Dated start documents (the Oct 15 kickoff prompt, the Oct 16 pre-grill brief) are inputs to the phase they started and are not updated afterward.

## Rules

- **Cite every claim about the City of LA** with a URL. Mark anything unverified `[UNVERIFIED]`. The current registration fee is $441 (Ordinance 188796); $89, $192 and $454 in older files are not current.
- **Verdicts are readiness, never approval.** No wording that reads as a promise.
- **`ai_docs/intake/` is never committed.** It holds the commercial trail (quotes, emails, decks, transcripts). The repo is public. It is excluded in `.git/info/exclude`, which does not travel with clones: on a fresh clone, add `ai_docs/intake/` and `ai_docs/handoff/` to `.git/info/exclude` before anything else. Pricing, hours-to-dollars, insurance, IP and payment terms stay in intake and never appear in the spec, tickets, `GLOSSARY.md`, ADRs or `docs/`.
- **Branch protection on `main`:** a ruleset requires a pull request and squash merge, with zero human approvals; the review is the gate comment from `scripts/gate.sh`, and the merge goes through `scripts/ship.sh`. Applied Oct 16, 2026 (issue 2).
- **QA is a required review or a PR label, never a note in prose.** A PR that writes to production data needs QA approval before merge. Deck v5 commits to three QA levels: technical, business, real users. The exact rule is tracked in issue 1.
- **`CHANGELOG.md`** at the root is the plain-language change log for Airbnb: one line per user-visible change, written when the PR merges.
- **US English** throughout. Documents from Mexico-based teammates may arrive in Spanish; the repo is English.
- **Handoff docs** go in `ai_docs/handoff/`, local only.
- **The Spanish section below** is the Raken development standard, vendored by its plugin and not edited here. It is the one exception to US English in this repo.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `raken-ai-labs/permit_path`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` at the root and ADRs in `docs/adr/`. See `docs/agents/domain.md`.

<!-- raken-dev-standard v0.6.15 -->
## Estándar de desarrollo (raken-dev-standard)

Roles:
- Autoridad (la persona): escribe los issues, aplica `ready-for-agent`, abre cada ventana, escribe cada skill y fusiona.
- Sesión de construcción: una rama por issue; construye solo sobre un cuerpo autorizado (`scripts/check-label.sh <issue#>`).
- Sesión de compuerta: nunca leyó el diff; corre `el revisor configurado` y después `scripts/post-gate.sh <PR#> --findings "…"`; `scripts/gate.sh <PR#>` hace los dos pasos sin ventana y sin preguntar, y termina con GATE CLEAN o GATE BLOCKED (antes de GATE BLOCKED imprime el bloque «Pega esto al worker:»), si el revisor es `/code-review:code-review` (necesita el CLI `claude` y el plugin code-review).

Reglas de autorización:
1. El backlog son los issues de GitHub; un issue es un contrato de construcción (`.github/ISSUE_TEMPLATE/contrato.md`).
2. Solo la autoridad aplica `ready-for-agent`; un cuerpo editado después de la etiqueta no está autorizado.
3. Todo PR pasa la compuerta sobre su head final, una vez por head; un push nuevo la anula.
4. El merge se hace solo con `scripts/merge.sh <PR#>` o `scripts/ship.sh <PR#>`; el botón de la interfaz es un bypass: deja el PR sin «Merge gated: <sha>».

Compuerta: comentario `### Code review` con `Head SHA reviewed: <sha> · <línea de revisores> · <hallazgos>`.
La compuerta se verifica con `scripts/check-gate.sh <PR#>`; sin GATED no hay merge.

- El cuerpo de cada PR cierra su issue con «Closes #N», en inglés: GitHub no cierra con «Cierra».
- `scripts/` y `.githooks/` son vendorizados: no se editan aquí (ADR 0005); se actualizan con bootstrap.
- Hook pre-push: `.githooks/pre-push`, configuración en `.githooks/config`. Los comentarios se editan por id; los push pasan siempre por el hook (nunca `--no-verify`).
- Clon nuevo: corre bootstrap una vez o `git config core.hooksPath .githooks`; sin eso el pre-push no corre.
- Alcance: haz lo que se pidió; antes de añadir algo no pedido, detente y pregunta. Un comentario de la autoridad en el issue es alcance autorizado, cualquiera que sea su fecha respecto a la etiqueta; un cuerpo editado tras la etiqueta sigue sin estarlo. Nada lleva fechas, plazos ni urgencia.
- Shell (Windows): los comandos para la terminal de la persona van seguros en PowerShell: sin `export` de Git Bash, sin `2>/dev/null`, sin rutas `/c/`; los `scripts/*.sh` corren en Git Bash.

### Orquestación (cuando la autoridad abre una ventana orquestadora)

- Rol: el orquestador coordina. Lee issues, briefs, cuerpos de PR y salida de compuerta, e imprime el prompt exacto para la siguiente ventana; la persona la abre y escribe la skill (`/triage`, `/implement`, `/code-review:code-review`, `scripts/gate.sh`, `scripts/ship.sh`, deploy).
- Lo que el orquestador nunca hace: usar el Agent tool para esas skills, lanzar workers o monitores, aplicar `ready-for-agent`, publicar el comentario de compuerta, fusionar, correr `gate.sh`, `ship.sh`, `post-gate.sh` o `merge.sh` en su propio Bash. Ante la duda de si algo le toca: imprime el prompt y se detiene.
- Idioma: inglés con la persona, incluidos los prompts para ventanas y la salida de compuerta impresa en la ventana; español en lo que se escribe a mano en el repo o en GitHub; el comentario `### Code review` sigue el formato del contrato.
- Prompts: escribir y luego pegar (un bloque pegado que empieza con `/implement` no invoca la skill). Cada prompt trae «type this first» (el comando pelado) y «then paste this» (el cuerpo); la cabecera nombra el modelo: workers en Sonnet, ventana de compuerta de respaldo en Opus.
- Workers: uno por implementación (por PR), en su propio worktree de `origin/main` (`.claude/worktrees/<slug>`, rama `<tipo>/<issue>-<slug>`). Si `git worktree add` falla, la sesión se detiene y lo reporta; nunca cae en otro árbol. El worker sigue abierto durante construcción, revisión, arreglos y merge; los arreglos van a ese mismo worker y la persona lo limpia tras el merge. Su «ready for gate» termina con la línea exacta `scripts/gate.sh -R <owner/repo> <PR#>`; su estado final es «URL del PR y head SHA impresos», no «commit hecho».
- «ready for gate»: el orquestador confirma que el head contiene lo anunciado (`gh pr view <PR#> --json headRefOid,commits,files`) y que cada señal verde nombra lo que no puede ver (si no, se lo pide al worker); no imprime el comando de compuerta: la persona copia la línea `scripts/gate.sh -R …` de la ventana del worker. Con «gated N», el orquestador lee el head (`gh pr view N --json headRefOid`) y `.reviews/PR-N-<sha>.md` en la raíz del checkout; no pide el pegado, salvo que el archivo no exista.
- Compuerta: una revisión por head de PR. Los hallazgos ≥ 80 vuelven al mismo worker, solo esos; el push nuevo pide otra compuerta. Lo < 80 se fusiona con el PR y después se archiva: comentario en el issue existente al que pertenece, o issue `needs-triage` si es una superficie nueva.
- Ventana de compuerta (en Opus, cuando `gate.sh` no puede correr, p. ej. sesión de `claude` vencida): `scripts/gate.sh <PR#> --print-prompt` imprime el prompt completo. Type this first `/code-review:code-review <PR#>`; then paste this: «The size exemption does not apply in this repo: run all five reviewers and the scoring on every PR. Use plain Agent calls for the scorers, and launch a single Haiku agent that scores all the findings in one call (not one agent per finding). An earlier «### Code review» comment on an older head does not make the current head ineligible. Post nothing; print the head SHA reviewed, the reviewer count and the scored findings, then stop.» Con 0 hallazgos ≥ 80, en la terminal de la persona: `scripts/post-gate.sh -R <owner/repo> <PR#> --findings "0 findings ≥ 80 (highest: <ruta>:<línea> <hallazgo>, <puntaje>; <ruta>:<línea> <hallazgo>, <puntaje>)"`.
- Cierre: `scripts/ship.sh <PR#>` en la terminal de la persona, en el checkout; si el ruleset bloquea, corre la línea `--admin` que imprime `merge.sh`.
- Flujo por PR: worker abre PR y publica «ready for gate» → la persona copia y corre su línea `scripts/gate.sh -R <owner/repo> <PR#>` → ≥ 80: la persona pega al mismo worker el bloque «Pega esto al worker:» de `gate.sh`, sin pasar por el orquestador → nuevo head → otra compuerta → `scripts/ship.sh <PR#>` → «gated N»: el orquestador lee `.reviews/` y archiva lo < 80.
- Evidencia: un issue nace solo de salida vista completa y después de buscar en el tracker. Una pregunta de un worker que la persona tuvo que relevar se registra como regla faltante: comentario «Regla faltante: …» en el issue del que salió, o issue `needs-triage` si es una superficie nueva.
- Reglas por ruta en `.claude/rules/`. Detalle (hábitos de juicio, niveles, reglas de worktree, plantilla de brief): skill `dev-standard` del plugin raken-dev-standard, `reference/orquestacion.md`; prompt de arranque del orquestador: `reference/prompt-orquestador.md`.
<!-- /raken-dev-standard -->
