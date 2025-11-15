# Burials & Cemeteries Quickstart

This note captures the final shape we landed on for managing burials inside cemeteries, plus common troubleshooting steps.

## What you can do now
- Add a **Burial** directly from a cemetery via **New burial**.
- Store non‑soldier burials (no participant) *or* link to an existing Soldier via `participant_type/id`.
- Record birth/death dates & places, inscription, section/plot/marker, and an external `link_url` (e.g., Find‑a‑Grave).
- Keep your Soldier page logic intact (categories, citations, involvements, etc.).

## Files added/updated
- `app/views/burials/_form.html.erb` — full burial editor with optional Soldier lookup.
- `app/views/burials/new.html.erb` — new page.
- `app/views/burials/edit.html.erb` — edit page.
- `app/helpers/soldiers_helper.rb` — includes `:cemetery` in soldier badge categories.

## Cemetery#show layout (recap)
Keep two sections:
- **Soldiers buried here** — built from `Burial.where(cemetery_id: ..., participant_type: 'Soldier')`.
- **Other burials** — burials in the same cemetery with `participant_id` null.
Provide a search box that filters both via `q`.

Add an entry point button:
```erb
<%= link_to "Add burial", new_cemetery_burial_path(@cemetery), class: "btn btn-sm btn-outline-primary" %>
```

## Controller expectations
**CemeteriesController#show** should set:
```ruby
@soldier_burials = @cemetery.burials.where(participant_type: "Soldier")
@burials        = @cemetery.burials.where(participant_id: nil) # civilians/unknown
```
…and apply a simple `q` filter against `first_name`, `last_name`, and the space‑joined combo.

**BurialsController** should be nested for `new/create` under a cemetery, and flat for `edit/update/destroy`.

## Soldier search in the burial form
The form contains a tiny `fetch('/soldiers/search.json?q=...')` helper that calls your existing `SoldiersController#search`. It fills a `<datalist>` and writes the selected id into `burial[participant_id]`. Leave `participant_type` as `"Soldier"` unless you add more record types later.

### If search returns nothing
- Hit `/soldiers/search.json?q=John%20Endicott` directly to confirm the controller responds.
- Ensure `SoldiersController#search` uses `render json:` and is not behind auth.
- Open DevTools → Network and check the response/console for blocked fetches.

## Slugs & Categories sanity
Ensure models that appear on public pages still include your concerns:
```ruby
include Sluggable
include Citable
include Categorizable
```
…and each defines `slug_source` sensibly (`name`/`title` for lookups; `first + last` for people).

## Backfilling from old involvements
If you previously used `Involvement` for burials, you can migrate:
```ruby
# lib/tasks/backfill_cemetery_burials.rake
namespace :data do
  desc "Convert Cemetery involvements to Burial records"
  task backfill_burials: :environment do
    Involvement.where(involvable_type: "Cemetery").find_each do |inv|
      Burial.find_or_create_by!(
        cemetery_id: inv.involvable_id,
        participant_type: inv.participant_type, # "Soldier"
        participant_id:   inv.participant_id
      ) do |b|
        b.note = inv.note.presence || inv.role
      end
    end
    puts "Done."
  end
end
```

## Troubleshooting
- **Template not found** errors: filename, folder, and partial leading underscore must match the render call.
- **Search field shows no suggestions**: verify `/soldiers/search.json` returns 200 + JSON; check the browser console for blocked fetches.
- **Routing error for assets**: ensure `public/assets -> ../app/assets/builds` symlink exists and your dev server is serving `/assets` (Rack::Static).

---

*Drop any TODOs here as you iterate (e.g., add People model, enrich edit links in burials tables, etc.).*
