# Jefajefa Backup Bundle

Contents:
- db/migrate/* : staging imports, normalized census tables, pg_trgm, locator fields, remove pg from sources
- app/models/census.rb, app/models/census_entry.rb
- app/controllers/censuses_controller.rb and app/views/censuses/show.html.erb
- lib/tasks/census_import.rake (copy_load + normalize)
- lib/tasks/census_link.rake (fuzzy match to soldiers via pg_trgm)
- app/jobs/census_ingest_image_job.rb (optional Active Storage ingest from remote URLs)
- docs/ROUTES_PATCH.txt (what to add to routes)

Usage (Postgres):
  bin/rails db:migrate
  CSV=/abs/path/to/your.csv bin/rails census:copy_load
  bin/rails census:normalize
  SIM=0.35 bin/rails census:link_soldiers

Notes:
  - The Census model prefers `image_url` (e.g., SmugMug). If you later want local copies,
    enable Active Storage and use CensusIngestImageJob.
  - The citations locator fields are additive and safe to run alongside your existing schema.
