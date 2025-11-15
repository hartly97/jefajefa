# Command Reference (Polymorphic ERD Project)

This document lists all key commands used to debug, seed, lint, and visualize your Rails app.

---

## Rails / DB Setup

```bash
# Stop Spring (avoids caching issues)
bin/spring stop 2>/dev/null || true

# Clear tmp cache (sessions, compiled files, etc.)
rails tmp:clear

# Check model/controller syntax
ruby -c app/models/soldier.rb
ruby -c app/controllers/soldiers_controller.rb

# Check Zeitwerk autoloading
bin/rails zeitwerk:check

# Generate migration to add cemetery_id to soldiers (make nullable!)
bin/rails g migration AddCemeteryRefToSoldiers cemetery:references

# Run migrations
bin/rails db:migrate

# Seed database
bin/rails db:seed
```

---

## Grep / Diagnostics

```bash
# Show all defs / class / module / end lines to debug extra end
grep -nE '^\s*(class|module|def|do|if|case|begin|included|class_methods|private|protected|end)\b' app/models/soldier.rb

# Print tail of file with line numbers
nl -ba app/models/soldier.rb | sed -n '80,140p'

# Search for .name calls in views/helpers
grep -Rn '\.name' app/views app/helpers

# Search for stray cf. in soldier forms
grep -RIn 'cf\.' app/views/soldiers
```

---

## ERB Lint & RuboCop

```bash
# Add erb_lint
bundle add erb_lint --group=development

# Run ERB lint for all views
bundle exec erblint --lint-all

# Run ERB lint just for soldiers views
bundle exec erblint app/views/soldiers
```

---

## Seeds

```bash
# Run seed file
bin/rails db:seed

# Open console to test seeding manually
bin/rails c
```

---

## Graphviz / ERD

```bash
# Render Graphviz ERD (DOT → PNG)
dot -Tpng docs/ERD.dot -o docs/ERD.png

# Render Graphviz ERD (DOT → SVG)
dot -Tsvg docs/ERD.dot -o docs/ERD.svg
```

---

## PDF / Docs Generation (Notebook-only)

These were generated for you using Python libraries inside the notebook:

- **Graphviz**: to build `ERD.png` and `ERD.pdf`
- **ReportLab**: to create `ERD_Cheat_Sheet.pdf` and `ERD_Seed_Checklist.pdf`
- **Pandoc/Markdown**: to produce `seeds_guide.md`

You don’t need these locally unless you want to regenerate from scratch.

---

## ✅ Summary

- **Rails commands**: migrations, seeds, syntax checks  
- **Grep helpers**: locate stray `end`s, `cf.` calls, and `.name` references  
- **Lint tools**: `erb_lint` and RuboCop to catch missing blocks and indentation  
- **Graphviz**: render ERDs to PNG/PDF  
- **ReportLab/Pandoc**: generated printable cheat sheets & guides  
