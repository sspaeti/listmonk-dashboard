.DEFAULT_GOAL := start
PORT ?= 9009
RILL_FLAGS := --pull-env=false   # local only, never touch Rill Cloud

.PHONY: help start start-fg stop status validate fetch check pg-check refresh query clean open ev ev-connection ev-validate ev-query

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

URL := http://localhost:$(PORT)

start: ## (default) Start Rill in the background if not running, wait until ready, open the browser
	@if curl -sf -m 2 $(URL)/v1/instances/default/resources > /dev/null; then \
	  echo "rill already running -> $(URL)"; \
	else \
	  mkdir -p tmp; \
	  nohup rill start $(RILL_FLAGS) --no-open --port $(PORT) > tmp/rill.log 2>&1 & \
	  echo "starting rill (pid $$!), log tmp/rill.log"; \
	  until curl -sf -m 2 $(URL)/v1/instances/default/resources > /dev/null; do sleep 1; done; \
	  echo "rill ready -> $(URL)"; \
	fi
	@$(MAKE) --no-print-directory open

start-fg: ## Start Rill in the foreground (Ctrl-C stops it)
	rill start $(RILL_FLAGS) --port $(PORT)

open: ## Open the dashboard in the browser
	@xdg-open $(URL) 2>/dev/null || open $(URL) 2>/dev/null || echo "open $(URL) in your browser"

stop: ## Stop a running rill start
	@pkill -f '^rill start' && echo "rill stopped" || echo "rill not running"

status: ## Show models, metrics views and dashboards with their reconcile status/errors
	@curl -sf localhost:$(PORT)/v1/instances/default/resources \
	  | jq -r '.resources[] | select(.meta.name.kind|test("Model|MetricsView|Explore|Canvas")) | "\(.meta.name.kind|split(".")|last)\t\(.meta.name.name)\t\(.meta.reconcileStatus|sub("RECONCILE_STATUS_";""))\t\(if (.meta.reconcileError // "") == "" then "ok" else (.meta.reconcileError | split("\n")[0]) end)"' \
	  | sort | column -t -s $$'\t' || echo "rill not running on :$(PORT)"

validate: ## Validate the project without the UI (stop rill first)
	rill validate $(RILL_FLAGS) --model-timeout-seconds 180

fetch: ## Pull listmonk's own numbers via the API into data/
	scripts/fetch.sh

check: ## Run the acceptance checks against the running instance
	scripts/check.sh

pg-check: ## Test the Postgres connection via the DuckDB postgres extension
	scripts/pg_check.sh

refresh: fetch ## Re-fetch API data, then fully re-ingest all models on the running instance
	rill project refresh --local --all --full

query: ## Ad-hoc SQL against the running instance, e.g. make query SQL="select * from campaign_summary limit 5"
	rill query --local --sql "$(SQL)"

clean: ## Remove Rill's local state (tmp/); next start re-ingests everything
	rm -rf tmp

# ---- Evidence (evidence/ subfolder, same dashboards in Evidence markdown, live Postgres) ----
EV := EVIDENCE_TELEMETRY_DISABLED=1 evidence --project evidence

ev: ev-connection ## Start the Evidence dev server for evidence/ (writes connection.yaml from .env first)
	$(EV) dev

ev-connection: ## Write evidence/connection.yaml (git-ignored) from .env
	scripts/evidence_connection.sh

ev-validate: ## Validate Evidence markdown and components
	$(EV) validate

ev-query: ## Run a SQL file or query against Postgres via Evidence, e.g. make ev-query SQL="select 1"
	$(EV) query "$(SQL)" --format table
