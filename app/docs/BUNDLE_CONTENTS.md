# Bundle Contents Overview
Generated: 2025-09-10

This file summarizes everything shipped in this bundle.

## Core Code
- Models/controllers/views for:
  - Articles
  - Sources
  - Soldiers
  - Categories + Categorizations
  - Citations (polymorphic, Article <-> Source <-> Soldier)
  - Relations (generic polymorphic links)
- Concerns:
  - Sluggable (with regenerate_slug!)
  - Citable
  - Categorizable
  - Relatable

## Seeds + Reset
- `db/seeds.rb` (base categories + 2 sample soldiers)
- `db/seeds_reset.rb` (safe reseed/reset flow)

## Features
- Admin-only slug regeneration:
  - Concern, controller snippets, routes, view buttons
- Citations fields partial:
  - Supports full Source attributes (title, author, publisher, year, url, details, repository, link_url)
- Soldiers wired like Articles, with awards, medals, wars, battles, cemetery

## Documentation inside this bundle
- `INSTALL_NOTES.md` (setup, migrate, seed)
- `db/RESEED_WORKFLOW.md` (reset/reseed quick steps)
- `CONSOLE_TRICKS.md` (Rails console + grep cheats)
- `docs/SOLDIER_CHECKLIST.md` (verify Soldiers)
- `docs/ARTICLE_SOURCE_CHECKLIST.md` (verify Articles <-> Sources)
- `docs/RELATIONS_CHECKLIST.md` (verify Relations polymorphic links)
- `BUNDLE_CONTENTS.md` (this file)

## Not included
- User/auth system (Devise etc.) → stubbed `current_user&.admin?`
- Extra Stimulus/JS controllers (beyond form basics)
- Old experimental zips (folded into this bundle)
