SHELL := /bin/bash
.PHONY: run run-dev run-prod help

help:
	@echo "Gambit TSL — Flutter Run Targets"
	@echo ""
	@echo "  make run          → Interactive prompt for BASE_URL & ANON_KEY"
	@echo "  make run-dev      → Run against local Supabase (localhost:54321)"
	@echo "  make run-prod     → Prompt for production credentials"
	@echo ""

run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "GAMBIT TSL • Flutter Run — Custom Configuration"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@read -p "Enter GAMBIT_BASE_URL (e.g. https://xxx.supabase.co/functions/v1): " BASE_URL; \
	read -p "Enter GAMBIT_ANON_KEY (e.g. sb_publishable_...): " ANON_KEY; \
	flutter run \
		--dart-define=GAMBIT_BASE_URL=$$BASE_URL \
		--dart-define=GAMBIT_ANON_KEY=$$ANON_KEY

run-dev:
	@echo "🚀 Running against LOCAL Supabase (localhost:54321)"
	flutter run \
		--dart-define=GAMBIT_BASE_URL=http://localhost:54321/functions/v1 \
		--dart-define=GAMBIT_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoxODAwMDAwMDAwfQ.PLACEHOLDER

run-prod:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "⚠️  PRODUCTION CREDENTIALS — Handle with care!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@read -p "Enter PRODUCTION GAMBIT_BASE_URL: " PROD_URL; \
	read -sp "Enter PRODUCTION GAMBIT_ANON_KEY: " PROD_KEY; \
	echo ""; \
	flutter run \
		--dart-define=GAMBIT_BASE_URL=$$PROD_URL \
		--dart-define=GAMBIT_ANON_KEY=$$PROD_KEY