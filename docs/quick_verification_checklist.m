Quick Verification Checklist

A fast, copy-paste friendly checklist to confirm your app state after the recent cleanup (Soldiers, Sources, Censuses, Involvements, pagination, and search scopes).

Tip: Run shell commands from your project root. For console snippets, use bin/rails c.

1) Routes sanity
bin/rails routes -g "^soldiers#"
bin/rails routes -g "^sources#"
bin/rails routes -g "^involvements#"
bin/rails routes -g "^censuses#"
bin/rails routes -g autocomplete
bin/rails routes -g regenerate_slug

Expect:

Exactly one block for Soldiers, with search (collection) and regenerate_slug (member).

sources#autocomplete present.

Only one involvements#create/destroy pair.

censuses#show/index and censuses#regenerate_slug present.
2) Soldiers model scopes
reload!
# ensure Option B scope is loaded (ILIKE + unit/branch_of_service)
Soldier.search_name("smith").limit(3).pluck(:first_name, :last_name, :unit)
Soldier.search_name("").limit(1).count  # returns total count (no error)

3) Soldier fields (form + strong params)

In app/views/soldiers/_form.html.erb ensure text fields for:

unit

branch_of_service

In app/controllers/soldiers_controller.rb strong params include:

:unit, :branch_of_service

Quick console check:
s = Soldier.first || Soldier.create!(first_name: "Test", last_name: "User")
s.update!(unit: "Infantry", branch_of_service: "Army")
s.slice(:unit, :branch_of_service)

4) Soldier show view

Ensure you render plain text (no Units model links):
<% if @soldier.unit.present? %>
  <p><strong>Unit:</strong> <%= @soldier.unit %></p>
<% end %>

<% if @soldier.branch_of_service.present? %>
  <p><strong>Branch:</strong> <%= @soldier.branch_of_service %></p>
<% end %>

5) Sources autocomplete endpoint
bin/rails routes -g sources#autocomplete
curl -s "http://localhost:3000/sources/autocomplete?q=ha"

6) Citations partial wiring

app/views/citations/_sections.html.erb uses the parent form builder variable (e.g., f):
<div data-controller="citations" data-citations-index-value="<%= (f.object.citations || []).size %>">
  <div data-citations-target="list">
    <% f.fields_for :citations do |cf| %>
      <div data-citations-wrapper>
        <%= render "citations/fields", f: cf, sources: (@sources || Source.order(:title)) %>
      </div>
    <% end %>
  </div>
  <template data-citations-target="template">
    <div data-citations-wrapper>
      <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
        <%= render "citations/fields", f: cf, sources: (@sources || Source.order(:title)) %>
      <% end %>
    </div>
  </template>
</div>
app/views/citations/_fields.html.erb expects f: (the citation builder) and renders the nested Source fields with f.fields_for :source do |sf|.

Stimulus controllers:

app/javascript/controllers/citations_controller.js (targets: list, template) and remove action:
data-action="click->citations#remove".

app/javascript/controllers/source_picker_controller.js wired to the autocomplete UI in _fields.

7) Involvements (AJAX add/remove)

Routes:
bin/rails routes -g "^involvements#"

Controller: app/controllers/involvements_controller.rb

create returns JSON with { id, participant_id, participant_type, participant_label, role, year, note }.

destroy responds with 204 No Content.

Stimulus:

app/javascript/controllers/involvement_form_controller.js

data-action="involvement-form#add" on the Add button.

data-action="involvement-form#remove" on Remove buttons.

Quick smoke test (console):
w = War.first || War.create!(name: "Test War", slug: "test-war")
s = Soldier.first || Soldier.create!(first_name: "Test", last_name: "User")
Involvement.create!(participant: s, involvable: w, role: "Scout", year: 1776)
w.involvements.includes(:participant).order(:year).map { |i| [i.participant&.try(:first_name), i.role, i.year] }

8) Censuses

Controller index filter: should accept year, district, piece, folio, page, and free-text q.

Search scope (adaptive) on CensusEntry via NameSearchable or hard-coded firstname/lastname variant.

8) Censuses

Controller index filter: should accept year, district, piece, folio, page, and free-text q.

Search scope (adaptive) on CensusEntry via NameSearchable or hard-coded firstname/lastname variant.


8) Censuses

8) Censuses

Controller index filter: should accept year, district, piece, folio, page, and free-text q.

Controller index filter: should accept year, district, piece, folio, page, and free-text q.

Search scope (adaptive) on CensusEntry via NameSearchable or hard-coded firstname/lastname variant.
Console checks:

CensusEntry.search_name("smith").limit(3).pluck(:firstname, :lastname)
CensusEntry.search_name("").count

9) Pagination (custom pager)

If using custom pager partial app/views/soldiers/_pager.html.erb, render once above and once below the list
<%= render "pager" %>
<%= render "list", soldiers: @soldiers %>
<%= render "pager" %>

@has_next = @soldiers.length > page_size
@soldiers = @soldiers.first(page_size)

10) Slugs

Test slug regeneration endpoints for a couple of models

# replace IDs with actual ones you have
curl -i -X PATCH http://localhost:3000/soldiers/1/regenerate_slug
curl -i -X PATCH http://localhost:3000/wars/1/regenerate_slug

xpect: 302 redirect back to the record, flash message like “Slug regenerated.”

11) DB constraints sanity (Involvements)
ActiveRecord::Base.connection.execute("SELECT conname FROM pg_constraint WHERE conname LIKE 'chk_inv_%'").values
ActiveRecord::Base.connection.indexes(:involvements).map(&:name)

Expect: Checks for involvable_type in ('War','Battle','Cemetery'), participant_type = 'Soldier', and year range; unique link index present.

12) Asset sanity (Stimulus)
bin/rails tmp:clear && bin/spring stop
bin/dev  # or your foreman/procfile dev

Open the browser devtools Console:

No 404s on involvement_form_controller.js, citations_controller.js, source_picker_controller.js.

When typing in Source search, network request hits /sources/autocomplete and returns JSON.

13) Grep for leftovers (optional)
# No Unit model usage
grep -RIn "units_path\|unit_path\|\bUnit\b" app/

# No COALESCE(name, '') in SQL
grep -RIn "COALESCE(name" app/ db/

14) Nice-to-haves (later)

Add partial indexes or trigrams for faster ILIKE search (Postgres): we can add when data volume grows.

Consider a read-only Article involvement listing if you want to relate Soldiers to Articles via Involvements again (currently disabled).

Want me to tailor a secon