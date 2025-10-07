# Rake & Script Tasks Reference

This document consolidates all the custom Rake tasks and helper scripts for importing, verifying, and maintaining categories, articles, and related associations in your Rails project.

---

## Category Reset

Delete all categories and categorizations (FK‑safe):

```bash
bin/rails cat:reset!
```

```ruby
# lib/tasks/cat_reset.rake
namespace :cat do
  desc "Delete ALL categories and categorizations (FK-safe)"
  task reset!: :environment do
    puts "Deleting #{Categorization.count} categorizations…"
    Categorization.delete_all
    puts "Deleting #{Category.count} categories…"
    Category.delete_all
    puts "Done."
  end
end
```

---

## Category Import

### Import Categories

CSV format: `name,category_type,slug,description`

```bash
bin/rails cat:import_categories CSV=tmp/categories.csv DRY_RUN=1
bin/rails cat:import_categories CSV=tmp/categories.csv
bin/rails cat:import_categories CSV=tmp/categories.csv UPDATE=1
```

Export:

```bash
bin/rails cat:export_categories CSV=tmp/categories_export.csv
```

---

### Import Article ↔ Category (Legacy IDs)

CSV headers: `id,article_id,category_id,created_at,updated_at`

```bash
bin/rails cat:import_articles_and_categories_from_csv \
  CSV=tmp/article_categories_legacy.csv DRY_RUN=1
```

With ID maps:

```bash
bin/rails cat:import_articles_and_categories_from_csv \
  CSV=tmp/article_categories_legacy.csv \
  ARTICLE_ID_MAP=tmp/article_id_map.csv \
  CATEGORY_ID_MAP=tmp/category_id_map.csv
```

---

### Import Article ↔ Category (By Title + Name)

CSV headers: `article_title,category_name,category_type`

```bash
bin/rails cat:import_by_title_and_name \
  CSV=tmp/article_categories_by_title.csv DRY_RUN=1
```

Auto-create missing categories:

```bash
bin/rails cat:import_by_title_and_name \
  CSV=tmp/article_categories_by_title.csv CREATE_CATEGORIES=1
```

---

### Build ID Maps

From old → new IDs.

```bash
bin/rails cat:build_article_id_map  OLD=tmp/old_articles.csv OUT=tmp/article_id_map.csv
bin/rails cat:build_category_id_map OLD=tmp/old_categories.csv OUT=tmp/category_id_map.csv
```

---

## Reports

Main report:

```bash
bin/rails cat:report
bin/rails categories:report
```

Breakdown by type & usage:

```bash
bin/rails cat:breakdown
```

Orphaned categorizations:

```bash
bin/rails cat:orphans
```

Duplicate categorizations:

```bash
bin/rails cat:duplicates
```

---

## Utility Scripts

### CSV Splitters

Split a mixed CSV by type:

```bash
bin/rails runner lib/tasks/split_csv_by_type.rb input.csv outdir
```

Enhanced version (shapes Article CSV for title importer):

```bash
bin/rails runner lib/tasks/split_and_shape_csv.rb input.csv outdir
```

---

### Asset/Import Checkers

- **bin/check-broken-imports** → scans for broken JS/CSS import paths  
- **bin/check-import-meta-glob** → verifies `import.meta.glob("./images/**")` in `application.js`  
- **bin/grep_view_usage** → greps through `app/views` for a search term

Usage:

```bash
bin/check-broken-imports
bin/check-import-meta-glob
bin/grep_view_usage keyword
```

---

### Association / Data Integrity

- **soldier_check** → finds non-Soldiers with soldier-only categories (and vice versa)  
- **scripts/verify_associations.rb** → checks soldiers, categories, citations, battles, wars, medals for missing slugs and traversals

Run with:

```bash
bin/rails runner scripts/verify_associations.rb
```

---

## Misc

- **bin/rails zeitwerk:check** → always safe to run for autoload sanity  
- Category examples (DNA, CategoryTextAttachable) can be adapted later for admin setup
