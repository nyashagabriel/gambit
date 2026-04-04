SHELL := /bin/bash
.PHONY: help run run-dev run-prod build-web push-src push-web

help:
	@echo "Gonyeti TLS — Flutter Run Targets"
	@echo ""
	@echo "  make run          → Interactive prompt for BASE_URL & ANON_KEY"
	@echo "  make run-dev      → Run against local Supabase (localhost:54321)"
	@echo "  make run-prod     → Prompt for production credentials"
	@echo "  make build-web    → Build web release (reads env or prompts)"
	@echo "  make push-src     → Commit and push source changes"
	@echo "  make push-web     → Force-add build/web and push (if you want artifacts in git)"
	@echo ""

run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "GONYETI TLS • Flutter Run — Custom Configuration"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@read -p "Enter GONYETI_BASE_URL (e.g. https://xxx.supabase.co/functions/v1): " BASE_URL; \
	read -p "Enter GONYETI_ANON_KEY (e.g. sb_publishable_...): " ANON_KEY; \
	flutter run \
		--dart-define=GONYETI_BASE_URL=$$BASE_URL \
		--dart-define=GONYETI_ANON_KEY=$$ANON_KEY

run-dev:
	@echo "🚀 Running against LOCAL Supabase (localhost:54321)"
	flutter run \
		--dart-define=GONYETI_BASE_URL=http://localhost:54321/functions/v1 \
		--dart-define=GONYETI_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoxODAwMDAwMDAwfQ.PLACEHOLDER

run-prod:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "⚠️  PRODUCTION CREDENTIALS — Handle with care!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@read -p "Enter PRODUCTION GONYETI_BASE_URL: " PROD_URL; \
	read -sp "Enter PRODUCTION GONYETI_ANON_KEY: " PROD_KEY; \
	echo ""; \
	flutter run \
		--dart-define=GONYETI_BASE_URL=$$PROD_URL \
		--dart-define=GONYETI_ANON_KEY=$$PROD_KEY

build-web:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "GONYETI TLS • Flutter Web Build (Release)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@BASE_URL="$$GONYETI_BASE_URL"; \
	ANON_KEY="$$GONYETI_ANON_KEY"; \
	if [[ -z "$$BASE_URL" ]]; then read -p "Enter GONYETI_BASE_URL: " BASE_URL; fi; \
	if [[ -z "$$ANON_KEY" ]]; then read -sp "Enter GONYETI_ANON_KEY: " ANON_KEY; echo ""; fi; \
	flutter build web --release \
		--dart-define=GONYETI_BASE_URL=$$BASE_URL \
		--dart-define=GONYETI_ANON_KEY=$$ANON_KEY

push-src:
	@read -p "Commit message: " MSG; \
	git add .; \
	git commit -m "$$MSG"; \
	git push

push-web:
	@read -p "Commit message for web artifacts: " MSG; \
	git add build/web; \
	git commit -m "$$MSG"; \
	git push