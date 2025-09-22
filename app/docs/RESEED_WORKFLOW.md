# Reseed Workflow Cheat-Sheet

cumulative_bundle_MEGA_all_inclusive_WITH_RELATIONS_checklist_contents.zip
Generated: 2025-09-10

This app includes a reset script and seed data. Use these commands when you want to wipe and reload.

## 1. Drop, create, migrate fresh (optional)
```bash
bin/rails db:drop db:create db:migrate
```

## 2. Reset custom seedables (safe shortcut)
This clears soldiers, sources, medals, wars, battles, cemeteries, and their join data:
```bash
bin/rails runner db/seeds_reset.rb
```

## 3. Load seeds
Repopulate lookup tables and a couple of sample soldiers:
```bash
bin/rails db:seed
```

## 4. Verify
Use Rails console:
```ruby
Soldier.count
Source.count
Category.count
```

## 5. Optional: regenerate slugs
If you need to rebuild slugs for testing, use the admin-only **Regenerate slug** button on show pages.

---
Keep this file around as a quick reference whenever you need to reseed.
