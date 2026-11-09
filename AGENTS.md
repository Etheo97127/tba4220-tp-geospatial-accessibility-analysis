# AGENTS.md

How to work in this repo, for AI coding agents (Claude Code, Codex, Copilot, Cursor)
and the people steering them. What the project is lives in [README.md](README.md);
read it first.

## Project in one paragraph

R pipeline for TBA4220 Group 3: an access score for Singapore's 332 MP19 subzones,
an OSM coverage check, and three analysis stages (Q1 spatial, Q2 regression, Q3
typology) that read the score. One owner and one folder per stage (README table).
Working plans: `docs/plans/<stage>.md`. Decisions: `docs/consideration.md`. Schedule and
hand-off IDs: `docs/archive/team_plan.html` (archived, 70 KB; open it only when a task needs dates or
H-numbers).

## Commands

```bash
Rscript R/run_all.R              # whole pipeline
Rscript R/run_all.R score q1     # selected stages (upstream outputs must exist)
```

On Windows `Rscript` may not be on PATH: call `"C:/Program Files/R/R-<version>/bin/Rscript.exe"`.
`R/01_prep/00_fetch_*.R` download raw data and are run by hand, never by `run_all.R`.

## Invariants (break none)

- `data/raw/` is read-only. A new raw file needs a `00_fetch_*.R` script and a row in
  `docs/data_log.md` (URL, date, md5, licence).
- Join key `subzone_c`. CRS EPSG:3414; EPSG:4326 only for I/O.
- Stages read only `data/processed/` and `data/external/` (plus their own
  `data/interim/`) and write outputs prefixed by stage: `coverage_`, `score_`, `q1_` ...
  One exception: coverage and score also read prep's layers in `data/interim/`
  (subzones, OSM POIs, reference lists, buildings), which are rebuilt rather than
  committed; `run_all.R` runs prep first when they are missing.
- Hand-off columns in each plan are a contract. Renaming or dropping one means
  updating the plan and the README hand-off table in the same PR, and telling the
  stage owners who read it.
- Decision constants (radius, residential cut-off ...) live only in `R/00_setup.R`,
  tagged with their item number in `docs/consideration.md`.
- Scripts run from the repo root, are idempotent, and reset `set.seed(SEED)` before
  any sampling or permutation.
- Edit only your own stage's folder. Another stage's folder: ask its owner first.

## Code style

Concise, easy to read, modular. Write for a teammate who knows R but not this script.

**Files**
- One numbered script per step: `R/<stage>/NN_verb_noun.R`, registered in
  `R/run_all.R` with a one-line comment.
- Aim for under ~150 lines. Past ~200, split into another numbered script with an
  `data/interim/*.rds` between them.
- Order inside a script: header, `source("R/00_setup.R")`, extra `library()` calls,
  inputs, constants, `# --- section ---` blocks, outputs written last.
- Header, as in every existing script:
  ```r
  # 03_score/02_score.R -----------------------------------------------------------
  # One to five lines: what this step produces and why it is done this way.
  ```

**Functions**
- Small, single-purpose, top-level, named as verbs (`build_candidates()`).
- A helper used by two or more stages moves to `R/00_setup.R`; otherwise it stays in
  its script. No `utils.R` grab-bags.
- Data in, data out. The only globals a function may read are `DIR_*`, `CRS_*`,
  `SEED`, `CATEGORIES` and the decision constants.

**Lines**
- tidyverse + sf with the `%>%` pipe, as in the existing code. `snake_case` objects,
  `UPPER_SNAKE` constants at the top of the script.
- Paths only through `file.path(DIR_*, ...)`.
- Comments say *why* (a method choice, a data quirk, where a number comes from), not
  what the next line does.
- Progress through `log_step()`. No leftover `print()` or `View()`.
- No dead code, commented-out blocks, unused arguments or speculative options.
- A clear two-step beats a clever one-liner. Vectorise, but don't golf.

## Commits and branches

Small commits, each reviewable in a few minutes.

- One logical change per commit: a new step, a fix, a data download, a doc update. If
  the subject needs "and", it is probably two commits. Code may share a commit with
  the outputs it regenerates.
- Rough size: under ~150 changed lines of R. Data and regenerated outputs don't count,
  but the body says what they are.
- Never mix stages in one commit.
- Message: imperative subject of 60 characters or fewer, blank line, body wrapped at
  ~75 saying what changed, why, and any number that moved ("201 of 332 subzones are
  residential"). `git log` shows the house style.
- Branch per task, prefixed by workstream: `score/`, `coverage/`, `q1/`, `q2/`, `q3/`,
  `docs/`. PR to `master`; never commit to `master` directly.
- Before committing, run the stage you touched and update whatever the change makes
  stale, in the same commit: plan checkbox, `docs/data_log.md`,
  `data/DATA_SOURCES.md`, README hand-off table, `docs/consideration.md`.
- Never commit `data/interim/`, `*.osm.pbf`, `.Renviron`, credentials or
  `.claude/worktrees/`.

## Sessions and effort

Agent sessions are cheap to start and costly to keep long. Split the work so most of
it runs at low effort.

**One session = one task = one branch (or worktree) = ends in commits.** The usual
task is one checkbox in `docs/plans/<stage>.md`.

**Plan high, build low, review high.** Set the model and effort when you start the
session.

| Phase | Typical work | Effort |
|---|---|---|
| Plan | Choose a method, settle a decision, design a contract, chase a number that looks wrong | High (Opus-class) |
| Build | Implement a step the plan already specifies; follow an existing script's pattern | Medium |
| Chore | Regenerate outputs, re-run a fetch script, update logs, plans or README tables, rename | Low (Sonnet/Haiku-class) |
| Review | Before every PR: the `deep-reviewer` subagent | High (set in its definition) |

A planning session's deliverable is the hand-off: it writes the step into
`docs/plans/<stage>.md` concretely enough (files, inputs, output columns, the check that
proves it works) that a fresh low-effort session can build it without the planning
conversation.

**Start a new session when**
- the current task is committed;
- you move from planning to building, or from building to review;
- you switch stage, branch or owner area;
- the context is long or has taken in large files;
- a side issue turns up. Note it under the step in the plan; don't fix it in passing.

**The repo is the memory, not the chat.**
- End a session with: commits made, the plan checkbox ticked, and a `Next:` line under
  the step for anything left (open question, what to verify).
- Start one with: "Read AGENTS.md and `docs/plans/<stage>.md`, then do step X." Nothing
  else should be needed.

**Keep context small.**
- Read the plan, the scripts the step touches and `R/00_setup.R`, not the whole repo.
- Don't open raw GeoJSON, Overpass JSON or `team_plan.html` whole; use `head`, `jq` or
  a short R summary.
- Hand wide searches to a subagent so file dumps stay out of the main session.

**Parallel sessions** each get their own git worktree and branch. Two sessions never
write the same files.

## Review: `deep-reviewer`

[`.claude/agents/deep-reviewer.md`](.claude/agents/deep-reviewer.md) defines a
read-only, high-effort reviewer for this pipeline. It checks correctness (geometry,
CRS, joins, missing data, statistics), hand-off contracts, reproducibility, the style
and commit rules above, verifies each finding, and returns them ranked with
`file:line`. It never edits.

Run it:
- before opening any PR;
- after any change that moves a score, coverage or test number;
- when a hand-off contract or a decision constant changes.

Ask for it with the range, e.g. "Use the deep-reviewer on `master...HEAD`". Fix its
findings in a medium-effort session, one commit per fix. In tools without subagents,
use the body of that file as the review prompt.
