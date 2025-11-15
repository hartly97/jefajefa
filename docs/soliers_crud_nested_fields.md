Soldiers CRUD + Nested Fields — Quick Checklist
1) Routes
bin/rails routes -g "^soldiers#"
Expect:
•	soldiers#index/new/create/show/edit/update/destroy
•	soldiers#search (collection)
•	soldiers#regenerate_slug (member)
If you create/destroy nested rows via stand-alone endpoints, also:
bin/rails routes -g "^soldier_medals#"
bin/rails routes -g "^awards#"
(But if you handle them only via nested attributes on Soldier, these won’t be present—fine.)
 
2) Model wiring
Soldier
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable

  belongs_to :cemetery, optional: true

  has_many :awards, dependent: :destroy, inverse_of: :soldier
  accepts_nested_attributes_for :awards, allow_destroy: true

  has_many :soldier_medals, dependent: :destroy, inverse_of: :soldier
  has_many :medals, through: :soldier_medals
  accepts_nested_attributes_for :soldier_medals, allow_destroy: true

  has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
  accepts_nested_attributes_for :citations, allow_destroy: true

  # Optional, but handy for index ordering
  scope :by_last_first, -> {
    if column_names.include?("last_name")
      order(:last_name, :first_name)
    else
      order(:lastname, :firstname)
    end
  }
end
Award
class Award < ApplicationRecord
  include Citable
  include Categorizable
  include Sluggable

  belongs_to :soldier, inverse_of: :awards
  has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
end
SoldierMedal / Medal
class SoldierMedal < ApplicationRecord
  belongs_to :soldier, inverse_of: :soldier_medals
  belongs_to :medal,   inverse_of: :soldier_medals
end

class Medal < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable

  has_many :soldier_medals, dependent: :destroy
  has_many :soldiers, through: :soldier_medals
end
Citation / Source (for nested Source-in-citation)
class Citation < ApplicationRecord
  belongs_to :source, inverse_of: :citations, counter_cache: true
  belongs_to :citable, polymorphic: true, inverse_of: :citations

  validates :source, presence: true
  validates :source_id, uniqueness: { scope: %i[citable_type citable_id],
                                      message: "already cited for this record" }

  accepts_nested_attributes_for :source,
    reject_if: ->(attrs) { attrs['title'].blank? && attrs['id'].blank? }
end

class Source < ApplicationRecord
  include Sluggable
  include Categorizable

  has_many :citations, dependent: :restrict_with_error, inverse_of: :source
  scope :by_title, -> { order(:title) }
end
 
3) Strong params (SoldiersController)
def soldier_params
  params.require(:soldier).permit(
    :first_name, :middle_name, :last_name,
    :birthcity, :birthstate, :birthcountry,
    :birth_date, :death_date, :deathcity, :deathstate, :deathcountry,
    :deathplace, :cemetery_id, :unit, :branch_of_service,
    { category_ids: [] },

    awards_attributes: [:id, :name, :country, :year, :note, :_destroy],
    soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],

    citations_attributes: [
      :id, :source_id, :_destroy,
      :page, :pages, :folio, :column, :line_number, :record_number, :locator,
      :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
      { source_attributes: [:id, :title, :author, :publisher, :year, :url,
                            :details, :repository, :link_url] }
    ]
  )
end
 
4) Controller build-ups (new/edit)
def new
  @soldier = Soldier.new
  @soldier.awards.build
  @soldier.soldier_medals.build
  @soldier.citations.build
  load_sources
end

def edit
  @soldier.awards.build         if @soldier.awards.empty?
  @soldier.soldier_medals.build if @soldier.soldier_medals.empty?
  @soldier.citations.build      if @soldier.citations.empty?
  load_sources
end

def load_sources
  @sources = Source.by_title
end
 
5) Form: nested fields (key bits)
Soldiers form (snips to check)
<%= form_with model: @soldier do |f| %>
  <!-- Basic identity -->
  <%= f.label :first_name %>
  <%= f.text_field :first_name %>

  <%= f.label :last_name %>
  <%= f.text_field :last_name %>

  <!-- Cemetery -->
  <%= f.collection_select :cemetery_id, Cemetery.order(:name), :id, :name, include_blank: true %>

  <!-- Awards -->
  <fieldset>
    <legend>Awards (not medals)</legend>
    <%= f.fields_for :awards do |af| %>
      <div class="border p-2 mb-3 rounded">
        <%= af.label :name %> <%= af.text_field :name %>
        <%= af.label :country %> <%= af.text_field :country %>
        <%= af.label :year %> <%= af.number_field :year, in: 1000..3000, step: 1 %>
        <%= af.label :note %> <%= af.text_area :note, rows: 2 %>
        <label><%= af.check_box :_destroy %> Remove</label>
      </div>
    <% end %>
  </fieldset>

  <!-- Medals -->
  <fieldset>
    <legend>Medals</legend>
    <%= f.fields_for :soldier_medals do |mf| %>
      <div class="border p-2 mb-3 rounded">
        <%= mf.label :medal_id, "Medal" %>
        <%= mf.collection_select :medal_id, Medal.order(:name), :id, :name, include_blank: true %>
        <%= mf.label :year %> <%= mf.number_field :year, in: 1000..3000, step: 1 %>
        <%= mf.label :note %> <%= mf.text_area :note, rows: 2 %>
        <label><%= mf.check_box :_destroy %> Remove</label>
      </div>
    <% end %>
  </fieldset>

  <!-- Citations -->
  <fieldset>
    <legend>Citations</legend>
    <div data-controller="citations"
         data-citations-index-value="<%= @soldier.citations.size %>">
      <div data-citations-target="list">
        <% f.fields_for :citations do |cf| %>
          <div data-citations-wrapper>
            <%= render "citations/fields", f: cf, sources: (@sources || Source.by_title) %>
          </div>
        <% end %>
      </div>
      <template data-citations-target="template">
        <div data-citations-wrapper>
          <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
            <%= render "citations/fields", f: cf, sources: (@sources || Source.by_title) %>
          <% end %>
        </div>
      </template>
      <button type="button" class="btn btn-sm btn-outline-primary" data-action="citations#add">
        Add citation
      </button>
    </div>
  </fieldset>

  <%= f.submit %>
<% end %>
citations/_fields.html.erb (expects f: and sources:)
<div class="border p-3 mb-3 rounded citation-fields"
     data-controller="source-picker"
     data-citations-wrapper>

  <div class="field mb-2">
    <%= f.label :source_id, "Source" %>
    <%= f.collection_select :source_id,
          (defined?(sources) && sources.present?) ? sources : Source.by_title,
          :id, :title,
          { include_blank: "— Select a source —" },
          { class: "form-select", data: { "source-picker-target": "select" } } %>
  </div>

  <!-- Optional new Source inline -->
  <button type="button" class="btn btn-sm btn-outline-secondary"
          data-action="click->source-picker#toggleNewForm">+ Add a new source instead</button>

  <div class="mt-2" data-source-picker-target="newForm" style="display:none">
    <%= f.fields_for :source do |sf| %>
      <div class="row g-3">
        <div class="col-md-8"><%= sf.label :title %><%= sf.text_field :title, class: "form-control" %></div>
        <div class="col-md-4"><%= sf.label :author %><%= sf.text_field :author, class: "form-control" %></div>
        <div class="col-md-3"><%= sf.label :publisher %><%= sf.text_field :publisher, class: "form-control" %></div>
        <div class="col-md-2"><%= sf.label :year %><%= sf.text_field :year, class: "form-control" %></div>
        <div class="col-md-7"><%= sf.label :url %><%= sf.url_field :url, class: "form-control" %></div>
        <div class="col-md-6"><%= sf.label :repository %><%= sf.text_field :repository, class: "form-control" %></div>
        <div class="col-md-6"><%= sf.label :link_url, "Repository link" %><%= sf.url_field :link_url, class: "form-control" %></div>
        <div class="col-12"><%= sf.label :details %><%= sf.text_area :details, rows: 2, class: "form-control" %></div>
      </div>
    <% end %>
  </div>

  <!-- Per-citation fields -->
  <div class="row g-3 mt-3">
    <div class="col-md-6"><%= f.label :pages %><%= f.text_field :pages, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :folio %><%= f.text_field :folio, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :column %><%= f.text_field :column, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :line_number, "Line #" %><%= f.text_field :line_number, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :record_number %><%= f.text_field :record_number, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :locator, "Other locator" %><%= f.text_field :locator, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :image_url, "Image URL" %><%= f.url_field :image_url, class: "form-control" %></div>
    <div class="col-md-3"><%= f.label :image_frame, "Frame" %><%= f.text_field :image_frame, class: "form-control" %></div>
    <div class="col-md-3"><%= f.label :roll, "Roll / Piece" %><%= f.text_field :roll, class: "form-control" %></div>
    <div class="col-md-6"><%= f.label :enumeration_district, "ED" %><%= f.text_field :enumeration_district, class: "form-control" %></div>
  </div>

  <div class="mt-3"><%= f.label :quote %><%= f.text_area :quote, rows: 2, class: "form-control" %></div>
  <div class="mt-2"><%= f.label :note %><%= f.text_area :note, rows: 2, class: "form-control" %></div>

  <%= f.check_box :_destroy, style: "display:none" %>
</div>
 
6) Stimulus hooks
•	app/javascript/controllers/citations_controller.js (targets list, template; actions: add, remove)
•	app/javascript/controllers/source_picker_controller.js for autocomplete/toggle new form
•	Ensure controllers are registered in your Stimulus entrypoint.
Smoke test in devtools:
•	Click “Add citation” → a new block appears.
•	“Remove” hides/marks _destroy.
 
7) Autocomplete endpoint (for Source picker)
bin/rails routes -g sources#autocomplete
curl -s "http://localhost:3000/sources/autocomplete?q=ha"
Expect 200 and JSON array of { id, title }. Wire your fields JS to this endpoint.
 
8) Controller basics work
# List
open http://localhost:3000/soldiers

# New → Create a Soldier with 1 Award, 1 Medal, 1 Citation (+ inline new Source)
open http://localhost:3000/soldiers/new
On submit, expect redirect to Soldier show, nested rows persisted.
 
9) Console smoke tests
# Soldier with nested bits
s = Soldier.create!(
  first_name: "Test", last_name: "User",
  awards_attributes: [{ name: "Community Service", country: "USA", year: 1950 }],
  soldier_medals_attributes: [{ medal_id: (Medal.first&.id || Medal.create!(name: "Purple Heart", slug: "purple-heart").id), year: 1945 }],
  citations_attributes: [{
    source_attributes: { title: "Boston Gazette", year: "1750" },
    pages: "12–13", note: "Snippet"
  }]
)
s.reload
[s.awards.size, s.soldier_medals.size, s.citations.size, s.sources.size]
 
10) Common gotchas
•	Missing inverse_of on nested models → fields don’t bind errors properly.
•	Missing accepts_nested_attributes_for → nested params ignored.
•	Missing strong params for nested keys → nested rows not saved.
•	Forgetting to preload @sources → the Source dropdown is empty.
•	Two conflicting resources :soldiers blocks → duplicate/overlapping routes. Keep one soldiers block with all member/collection actions inside.
 
Want me to turn this into a ready-to-download .md + a minimal seed that builds a Soldier with an Award/Medal/Citation/Source so you can run one command and confirm UI + persistence?
You said:
please
ChatGPT said:
