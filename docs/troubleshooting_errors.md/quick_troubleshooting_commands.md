Quick Rails CLI / Shell Commands
File syntax & “invisible char” checks
# Ruby syntax check a model
ruby -c app/models/soldier.rb

# Show file with control chars visible (helps catch weird unicode)
LC_ALL=C sed -n '1,200p' app/models/soldier.rb | cat -v
Model loads & associations (rails runner is safer than console for one-offs)
# Confirm model constant loads
bin/rails r "puts Soldier.name"

# Reflect on associations
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
bin/rails r "p Soldier.reflect_on_association(:awards)&.macro"
bin/rails r "p War.reflect_on_association(:involvements)&.macro"

# Basic instance touch
bin/rails r "s = Soldier.first; puts(s ? (s.cemetery&.name || 'no cemetery') : 'no soldiers')"
Grep for duplicate/missing bits (portable grep)
# Where are category pickers rendered without passing f: ?
grep -RIn 'render "shared/category_picker"' app/views | grep -v 'f:'

# Find any suspicious belongs_to (outside models)
grep -RIn "belongs_to" app/controllers app/helpers app/views app/models/concerns || true

# Find COALESCE(name) mistakes
grep -RIn "COALESCE(name" app/ db/ || true
Routes / Endpoints
# Inspect routes you care about
bin/rails routes -g soldiers
bin/rails routes -g sources
bin/rails routes -g autocomplete
bin/rails routes -g regenerate_slug
bin/rails routes -g involvements

# Quick curl for autocomplete JSON
curl -s "http://localhost:3000/sources/autocomplete?q=har" | jq '.[:5]'
Pagination sanity (your custom pager)
# Ensure controller gives you @has_next and total count
bin/rails r "q=''; per=30; page=1; scope=Soldier.order(:last_name,:first_name); scope=scope.search_name(q) if q.present?; \
total=scope.count; total_pages=(total.to_f/per).ceil; puts [total,total_pages].inspect"
Scopes: name searches (first/last + slug)
# Soldier
bin/rails r "puts Soldier.search_name('smith').limit(5).pluck(:first_name,:last_name).inspect"

# CensusEntry (handles firstname/lastname + birthlikeplacetext)
bin/rails r "puts CensusEntry.search_name('smith').limit(5).pluck(:firstname,:lastname).inspect"
Seed helpers (Categories, with slugs)
# Create soldier-type categories (assumes Sluggable on Category)
bin/rails r "['Infantry','Cavalry','Artillery'].each{|n| Category.find_or_create_by!(name:n, category_type:'soldier') }"

# If any categories are missing slugs, regenerate safely
bin/rails r "Category.where(slug:nil).find_each{|c| c.regenerate_slug! rescue nil }"
Slug health
# See who lacks a slug (by model)
bin/rails r "puts Category.where(slug:nil).count"
bin/rails r "puts Soldier.where(slug:nil).count"

# Force one slug regeneration example
bin/rails r "a=Award.first; a&.regenerate_slug!; puts a&.slug"
Involvements quick checks
# Check unique link index exists (name may vary)
bin/rails dbconsole <<'SQL'
\d+ involvements
SQL

# Count rows per involvable type
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"

# Create an involvement safely (Soldier ↔ War)
bin/rails r "s=Soldier.first; w=War.first; if s && w; Involvement.find_or_create_by!(participant_type:'Soldier',participant_id:s.id,involvable_type:'War',involvable_id:w.id){|i| i.role='Private'; i.year=1812 }; puts 'ok'; else; puts 'need data'; end"
Censuses search & image URL presence
# Index filter shape
bin/rails r "puts Census.where(year: params = 1850).limit(3).pluck(:district,:place).inspect"  # edit year as needed

# External image URL presence
bin/rails r "puts Census.where.not(external_image_url:[nil,'']).limit(3).pluck(:slug,:external_image_url).inspect"
Sources autocomplete smoke test
bin/rails r "puts Source.where('LOWER(title) LIKE ?', '%har%').order(:title).limit(10).pluck(:id,:title).inspect"
View partial locals sanity
# Find partials that expect `f` but renders without it
grep -RIn "f\." app/views/shared | cut -d: -f1 | sort -u
 
If you want these in a file you can keep in the repo:
1.	Create dev/cli_quick_commands.md and paste this whole message.
2.	(Optional) Add a tiny helper script so you can run a curated set quickly:
# dev/quick_checks.sh
#!/usr/bin/env bash
set -e
echo "== Syntax =="
ruby -c app/models/soldier.rb
echo "== Routes (autocomplete) =="
bin/rails routes -g autocomplete
echo "== Soldier assoc =="
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
echo "== Category slugs missing =="
bin/rails r "puts Category.where(slug:nil).count"
Then:
chmod +x dev/quick_checks.sh
./dev/quick_checks.sh
No file overwrites here—just tools you can reuse anytime. If you want, tell me a few checks you run the most and I’ll condense them into a single bin/dev:check script that prints exactly what you need.
You said:
Like I can only copy File syntax & “invisible char” checks then paste it. then copy the code and paste it. One at a time. 
ChatGPT said:
Always show details
# Create a reusable commands cheat sheet and a helper script, and zip them for download.
import os, textwrap, zipfile, json, pathlib

base_dir = "/mnt/data/dev"
os.makedirs(base_dir, exist_ok=True)

commands_md = textwrap.dedent("""
# Rails CLI Quick Commands (Copy/Paste Friendly)

## 1) File syntax & “invisible char” checks
```bash
ruby -c app/models/soldier.rb
LC_ALL=C sed -n '1,200p' app/models/soldier.rb | cat -v
2) Model loads & associations
Always show details
bin/rails r "puts Soldier.name"
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
bin/rails r "s = Soldier.first; puts(s ? (s.cemetery&.name || 'no cemetery') : 'no soldiers')"
3) Grep for common gotchas
Always show details
grep -RIn 'render \"shared/category_picker\"' app/views | grep -v 'f:' || true
grep -RIn \"belongs_to\" app/controllers app/helpers app/views app/models/concerns || true
grep -RIn \"COALESCE(name\" app/ db/ || true
4) Routes / endpoints
Always show details
bin/rails routes -g soldiers
bin/rails routes -g sources
bin/rails routes -g autocomplete
bin/rails routes -g regenerate_slug
bin/rails routes -g involvements
curl -s \"http://localhost:3000/sources/autocomplete?q=har\" | jq '.[:5]'
5) Pagination sanity
Always show details
bin/rails r "q=''; per=30; page=1; scope=Soldier.order(:last_name,:first_name); scope=scope.search_name(q) if q.present?; total=scope.count; total_pages=(total.to_f/per).ceil; puts [total,total_pages].inspect"
6) Scopes: name searches
Always show details
bin/rails r "puts Soldier.search_name('smith').limit(5).pluck(:first_name,:last_name).inspect"
bin/rails r "puts CensusEntry.search_name('smith').limit(5).pluck(:firstname,:lastname).inspect"
7) Seed helpers (Categories)
Always show details
bin/rails r "['Infantry','Cavalry','Artillery'].each{|n| Category.find_or_create_by!(name:n, category_type:'soldier') }"
bin/rails r "Category.where(slug:nil).find_each{|c| c.regenerate_slug! rescue nil }"
8) Slug health
Always show details
bin/rails r "puts Category.where(slug:nil).count"
bin/rails r "puts Soldier.where(slug:nil).count"
bin/rails r "a=Award.first; a&.regenerate_slug!; puts a&.slug"
9) Involvements quick checks
Always show details
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
bin/rails r "s=Soldier.first; w=War.first; if s && w; Involvement.find_or_create_by!(participant_type:'Soldier',participant_id:s.id,involvable_type:'War',involvable_id:w.id){|i| i.role='Private'; i.year=1812 }; puts 'ok'; else; puts 'need data'; end"
10) Sources autocomplete smoke test
Always show details
bin/rails r "puts Source.where('LOWER(title) LIKE ?', '%har%').order(:title).limit(10).pluck(:id,:title).inspect"
11) View partial locals sanity
Always show details
grep -RIn \"f\\.\" app/views/shared | cut -d: -f1 | sort -u
""").strip()
quick_checks_sh = textwrap.dedent("""
#!/usr/bin/env bash
set -e
echo "== Ruby syntax (Soldier) =="
ruby -c app/models/soldier.rb
echo "== Routes (autocomplete) =="
bin/rails routes -g autocomplete
echo "== Soldier.assoc(:cemetery) =="
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
echo "== Category slugs missing =="
bin/rails r "puts Category.where(slug:nil).count"
echo "== Involvements by type =="
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
""").strip() + "\n"
Write files
md_path = os.path.join(base_dir, "rails_cli_quick_commands.md")
sh_path = os.path.join(base_dir, "quick_checks.sh")
with open(md_path, "w") as f:
f.write(commands_md + "\n")
with open(sh_path, "w") as f:
f.write(quick_checks_sh)
os.chmod(sh_path, 0o755)
Zip them up
zip_path = "/mnt/data/rails_cli_commands_bundle.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
z.write(md_path, arcname="dev/rails_cli_quick_commands.md")
z.write(sh_path, arcname="dev/quick_checks.sh")
{"md_path": md_path, "sh_path": sh_path, "zip_path": zip_path, "exists": [os.path.exists(md_path), os.path.exists(sh_path), os.path.exists(zip_path)]}
Always show details
Always show details
# Re-run creation of the cheat sheet and helper script, then zip.
import os, textwrap, zipfile, pathlib

base_dir = "/mnt/data/dev"
os.makedirs(base_dir, exist_ok=True)

commands_md = """
# Rails CLI Quick Commands (Copy/Paste Friendly)

## 1) File syntax & “invisible char” checks
```bash
ruby -c app/models/soldier.rb
LC_ALL=C sed -n '1,200p' app/models/soldier.rb | cat -v
2) Model loads & associations
Always show details
bin/rails r "puts Soldier.name"
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
bin/rails r "s = Soldier.first; puts(s ? (s.cemetery&.name || 'no cemetery') : 'no soldiers')"
3) Grep for common gotchas
Always show details
grep -RIn 'render \"shared/category_picker\"' app/views | grep -v 'f:' || true
grep -RIn "belongs_to" app/controllers app/helpers app/views app/models/concerns || true
grep -RIn "COALESCE(name" app/ db/ || true
4) Routes / endpoints
Always show details
bin/rails routes -g soldiers
bin/rails routes -g sources
bin/rails routes -g autocomplete
bin/rails routes -g regenerate_slug
bin/rails routes -g involvements
curl -s "http://localhost:3000/sources/autocomplete?q=har" | jq '.[:5]'
5) Pagination sanity
Always show details
bin/rails r "q=''; per=30; page=1; scope=Soldier.order(:last_name,:first_name); scope=scope.search_name(q) if q.present?; total=scope.count; total_pages=(total.to_f/per).ceil; puts [total,total_pages].inspect"
6) Scopes: name searches
Always show details
bin/rails r "puts Soldier.search_name('smith').limit(5).pluck(:first_name,:last_name).inspect"
bin/rails r "puts CensusEntry.search_name('smith').limit(5).pluck(:firstname,:lastname).inspect"
7) Seed helpers (Categories)
Always show details
bin/rails r "['Infantry','Cavalry','Artillery'].each{|n| Category.find_or_create_by!(name:n, category_type:'soldier') }"
bin/rails r "Category.where(slug:nil).find_each{|c| c.regenerate_slug! rescue nil }"
8) Slug health
Always show details
bin/rails r "puts Category.where(slug:nil).count"
bin/rails r "puts Soldier.where(slug:nil).count"
bin/rails r "a=Award.first; a&.regenerate_slug!; puts a&.slug"
9) Involvements quick checks
Always show details
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
bin/rails r "s=Soldier.first; w=War.first; if s && w; Involvement.find_or_create_by!(participant_type:'Soldier',participant_id:s.id,involvable_type:'War',involvable_id:w.id){|i| i.role='Private'; i.year=1812 }; puts 'ok'; else; puts 'need data'; end"
10) Sources autocomplete smoke test
Always show details
bin/rails r "puts Source.where('LOWER(title) LIKE ?', '%har%').order(:title).limit(10).pluck(:id,:title).inspect"
11) View partial locals sanity
Always show details
grep -RIn "f\\." app/views/shared | cut -d: -f1 | sort -u
""".strip() + "\n"
quick_checks_sh = """#!/usr/bin/env bash
set -e
echo "== Ruby syntax (Soldier) =="
ruby -c app/models/soldier.rb
echo "== Routes (autocomplete) =="
bin/rails routes -g autocomplete
echo "== Soldier.assoc(:cemetery) =="
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
echo "== Category slugs missing =="
bin/rails r "puts Category.where(slug:nil).count"
echo "== Involvements by type =="
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
"""
md_path = os.path.join(base_dir, "rails_cli_quick_commands.md")
sh_path = os.path.join(base_dir, "quick_checks.sh")
with open(md_path, "w") as f:
f.write(commands_md)
with open(sh_path, "w") as f:
f.write(quick_checks_sh)
os.chmod(sh_path, 0o755)
zip_path = "/mnt/data/rails_cli_commands_bundle.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
z.write(md_path, arcname="dev/rails_cli_quick_commands.md")
z.write(sh_path, arcname="dev/quick_checks.sh")
(zip_path, md_path, sh_path, os.path.exists(zip_path))
Always show details
Got you. Since file generation keeps flaking, here’s everything in two big, copy-once chunks you can paste into files locally.
rails_cli_quick_commands.md
# Rails CLI Quick Commands (Copy/Paste Friendly)

## 1) File syntax & “invisible char” checks
```bash
ruby -c app/models/soldier.rb
LC_ALL=C sed -n '1,200p' app/models/soldier.rb | cat -v
2) Model loads & associations
bin/rails r "puts Soldier.name"
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"
bin/rails r "s = Soldier.first; puts(s ? (s.cemetery&.name || 'no cemetery') : 'no soldiers')"
3) Grep for common gotchas
grep -RIn 'render \"shared/category_picker\"' app/views | grep -v 'f:' || true
grep -RIn "belongs_to" app/controllers app/helpers app/views app/models/concerns || true
grep -RIn "COALESCE(name" app/ db/ || true
4) Routes / endpoints
bin/rails routes -g soldiers
bin/rails routes -g sources
bin/rails routes -g autocomplete
bin/rails routes -g regenerate_slug
bin/rails routes -g involvements
curl -s "http://localhost:3000/sources/autocomplete?q=har" | jq '.[:5]'
5) Pagination sanity
bin/rails r "q=''; per=30; page=1; scope=Soldier.order(:last_name,:first_name); scope=scope.search_name(q) if q.present?; total=scope.count; total_pages=(total.to_f/per).ceil; puts [total,total_pages].inspect"
6) Scopes: name searches (dual schemas)
bin/rails r "puts Soldier.search_name('smith').limit(5).pluck(:first_name,:last_name).inspect"
bin/rails r "puts CensusEntry.search_name('smith').limit(5).pluck(:firstname,:lastname).inspect"
7) Seed helpers (Categories)
bin/rails r "['Infantry','Cavalry','Artillery'].each{|n| Category.find_or_create_by!(name:n, category_type:'soldier') }"
bin/rails r "Category.where(slug:nil).find_each{|c| c.regenerate_slug! rescue nil }"
8) Slug health
bin/rails r "puts Category.where(slug:nil).count"
bin/rails r "puts Soldier.where(slug:nil).count"
bin/rails r "a=Award.first; a&.regenerate_slug!; puts a&.slug"
9) Involvements quick checks
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
bin/rails r "s=Soldier.first; w=War.first; if s && w; Involvement.find_or_create_by!(participant_type:'Soldier',participant_id:s.id,involvable_type:'War',involvable_id:w.id){|i| i.role='Private'; i.year=1812 }; puts 'ok'; else; puts 'need data'; end"
10) Sources autocomplete smoke test
bin/rails r "puts Source.where('LOWER(title) LIKE ?', '%har%').order(:title).limit(10).pluck(:id,:title).inspect"
11) View partial locals sanity
grep -RIn "f\\." app/views/shared | cut -d: -f1 | sort -u

# quick_checks.sh
```bash
#!/usr/bin/env bash
set -e

echo "== Ruby syntax (Soldier) =="
ruby -c app/models/soldier.rb

echo "== Routes (autocomplete) =="
bin/rails routes -g autocomplete

echo "== Soldier.assoc(:cemetery) =="
bin/rails r "p Soldier.reflect_on_association(:cemetery)&.macro"

echo "== Category slugs missing =="
bin/rails r "puts Category.where(slug:nil).count"

echo "== Involvements by type =="
bin/rails r "puts Involvement.group(:involvable_type).count.inspect"
How to save:
1.	Create a dir (optional): mkdir -p dev
2.	Save the first block to dev/rails_cli_quick_commands.md
3.	Save the second block to dev/quick_checks.sh and make it executable: chmod +x dev/quick_checks.sh
\
