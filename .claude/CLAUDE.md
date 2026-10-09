# Rill Project

This is a [Rill](https://docs.rilldata.com) project. Before making any changes to the project, you MUST load the `rill-development` skill to understand the project structure, resource types, and development workflow.

Project rules (run `rill init --template claude` once to get the Rill skills into .claude/skills):
- Local only. Never use Rill Cloud. Always run `rill start --pull-env=false` and `rill validate --pull-env=false`.
- Secrets live in `.env` (never read or print its values). Non-secret settings live in `rill.yaml` under `env:`.
- Raw data comes from listmonk's Postgres via the DuckDB `postgres` extension (`models/pg_*.yaml`); listmonk API snapshots come from `scripts/fetch.sh` into `data/`.
- Do not name a derived model `campaigns`, `lists`, `subscribers`, etc.: Rill's reference detection would treat `lm.public.<table>` in the Postgres models as a reference to it and report a cyclic dependency.
- See README.md for setup, run and known data quirks.
