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