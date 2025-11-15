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