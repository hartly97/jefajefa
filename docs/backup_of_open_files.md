# app/models/category.rb
class Category < ApplicationRecord
  include Sluggable

  has_many :categorizations, dependent: :destroy
  
  has_many :articles,   through: :categorizations, source: :categorizable, source_type: "Article"
  
  has_many :soldiers,   through: :categorizations, source: :categorizable, source_type: "Soldier"
  
  has_many :cemeteries, through: :categorizations, source: :categorizable, source_type: "Cemetery"
  
  has_many :sources,  through: :categorizations, source: :categorizable, source_type: "Source"
  
  has_many :wars,  through: :categorizations, source: :categorizable, source_type: "War"
  
  has_many :battles, through: :categorizations, source: :categorizable, source_type: "Battle"
  
  has_many :medals,  through: :categorizations, source: :categorizable, source_type: "Medal"
  
  has_many :awards, through: :categorizations, source: :categorizable, source_type: "Award"
  
  has_many :censuses, through: :categorizations, source: :categorizable, source_type: "Census"

  # Optional typed scopes (for pickers)
  scope :soldiers,  -> { where(category_type: "soldier") }
  scope :wars,      -> { where(category_type: "war") }
  scope :battles,   -> { where(category_type: "battle") }
  scope :medals,    -> { where(category_type: "medal") }
  scope :awards,    -> { where(category_type: "award") }
  scope :articles,  -> { where(category_type: "article") }
  scope :cemeteries,-> { where(category_type: "cemetery") }
  scope :censuses,  -> { where(category_type: "census") }
  scope :sources,   -> { where(category_type: "source") }

  private

  # What Sluggable should slug
  def slug_source = name
end

<h1><%= @cemetery.name %></h1>

<%= render "shared/citations", citable: @cemetery, heading: "Cemetery Citations" %>

<p class="mt-3">
  <%= link_to "Edit", [:edit, @cemetery] %> |
  <%= link_to "Back", cemeteries_path %>
</p>

<hr class="my-3">

<h2>
  Soldiers buried here
  <small class="text-muted">(<%= @soldier_burials_count %>)</small>
</h2>

<%= form_with url: cemetery_path(@cemetery), method: :get, local: true,
              class: "row g-2 align-items-end mb-2" do %>
  <div class="col-md-6">
    <%= label_tag :q, "Search soldier burials" %>
    <%= text_field_tag :q, params[:q], class: "form-control",
                       placeholder: "Search by name…" %>
  </div>
  <div class="col-md-2">
    <%= submit_tag "Search", class: "btn btn-primary w-100" %>
  </div>
  <% if params[:q].present? %>
    <div class="col-md-2">
      <%= link_to "Clear", cemetery_path(@cemetery), class: "btn btn-link w-100" %>
    </div>
  <% end %>
<% end %>

<% if @soldier_burials.any? %>
  <%= render "soldiers/list", soldiers: @soldier_burials %>
<% else %>
  <p class="text-muted">No matching soldiers found in this cemetery.</p>
<% end %>

<hr class="my-4">

<h2 class="d-flex align-items-center justify-content-between">
  <span>Burials (detailed entries / non-soldiers)</span>
  <%= link_to "Add burial", [:new, @cemetery, :burial], class: "btn btn-sm btn-primary" %>
</h2>

<%= render "cemeteries/burials_table",
           cemetery: @cemetery,
           burials:  @burials %>

<%# Optional: keep the AJAX involvement panel if you want Soldier↔Cemetery links here %>
<%#= render "shared/involvements_panel", involvable: @cemetery %>


# <h1><%#= @cemetery.name %></h1>

# <%#= render "shared/citations", citable: @cemetery, heading: "Cemetery Citations" %>

# <p class="mt-3">
#   <%##= link_to "Edit", [:edit, @cemetery] %> |
#   <%#= link_to "Back", cemeteries_path %>
# </p>

# <h2 class="mt-4">Burials <small class="text-muted">(<%= @burials_count %>)</small></h2>

# <%#= form_with url: cemetery_path(@cemetery), method: :get, local: true,
#               class: "row g-2 align-items-end mb-3" do %>
#   <div class="col-md-6">
#     <%= label_tag :q, "Search burials" %>
#     <%= text_field_tag :q, params[:q], class: "form-control",
#                        placeholder: "Search by name…" %>
#   </div>
#   <div class="col-md-2">
#     <%= submit_tag "Search", class: "btn btn-primary w-100" %>
#   </div>
#   <% if params[:q].present? %>
#     <div class="col-md-2">
#       <%= link_to "Clear", cemetery_path(@cemetery), class: "btn btn-link w-100" %>
#     </div>
#   <% end %>
# <% end %>

# <% if @burials.any? %>
#   <ul class="mb-4">
#     <% @burials.each do |s| %>
#       <li>
#         <%= link_to (s.respond_to?(:display_name) ? s.display_name : [s.first_name, s.last_name].compact.join(" ")), s %>
#       </li>
#     <% end %>
#   </ul>
# <% else %>
#   <p class="text-muted">No burials match.</p>
# <% end %>


# <!-- app/views/cemeteries/show.html.erb (burials panel) -->
# <h1><%= @cemetery.name %></h1>

# <h2>Burials <small class="text-muted">(<%= @burials_count %>)</small></h2>

# <%= render "cemeteries/burials_panel", cemetery: @cemetery %>

# <%# show list already (server-rendered) %>
# <% if @burials.any? %>
#   <ul class="mt-3">
#     <% @burials.each do |b| %>
#       <li>
#         <strong><%= b.display_name %></strong>
#         <% if b.birth_date || b.birth_place %> — born <%= [b.birth_date, b.birth_place].compact.join(" in ") %><% end %>
#         <% if b.death_date || b.death_place %> — died <%= [b.death_date, b.death_place].compact.join(" in ") %>
#         <% end %>
#         <% if b.inscription.present? %> — <em><%= b.inscription %></em><% end %>
#         <% if b.memorial_link.present? %>
#         <%= link_to "Find a Grave", b.memorial_link, target: "_blank", rel: "noopener" %>
# <% end %>
#       </li>
#     <% end %>
#   </ul>
# <% else %>
#   <p>No burials match.</p>
# <% end %>


// app/javascript/controllers/involvement_picker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formBox","typeSelect","warSelect","battleSelect","cemeterySelect"]

  // 👇 tolerate target being missing; find the nearest form wrapper
  get formBoxEl() {
    return this.hasFormBoxTarget
      ? this.formBoxTarget
      : this.element.closest('[data-involvement-form-target="form"]')
  }

  connect() {
    const t = this.typeSelectTarget.value || "War"
    this.setType(t)
    const sel = this.visibleSelect(t)
    if (sel && sel.value) this.formBoxEl.dataset.involvableId = sel.value
  }

  changeType(e) {
    this.setType(e.currentTarget.value)
    this.formBoxEl.dataset.involvableId = ""
  }

  pick(e) { this.formBoxEl.dataset.involvableId = e.currentTarget.value }

  setType(t) {
    this.formBoxEl.dataset.involvableType = t
    this.typeSelectTarget.value = t
    this.toggle(this.warSelectTarget,      t === "War")
    this.toggle(this.battleSelectTarget,   t === "Battle")
    this.toggle(this.cemeterySelectTarget, t === "Cemetery")
  }

  visibleSelect(t) {
    if (t === "War") return this.warSelectTarget
    if (t === "Battle") return this.battleSelectTarget
    if (t === "Cemetery") return this.cemeterySelectTarget
  }

  toggle(el, on) { el.classList.toggle("d-none", !on) }
}


-----------
# app/models/category.rb
class Category < ApplicationRecord
  include Sluggable
  # ...
  # Optional, but explicit:
  def slug_source = name
end

  has_many :categorizations, dependent: :destroy
  
  has_many :articles,   through: :categorizations, source: :categorizable, source_type: "Article"
  
  has_many :soldiers,   through: :categorizations, source: :categorizable, source_type: "Soldier"
  
  has_many :cemeteries, through: :categorizations, source: :categorizable, source_type: "Cemetery"
 
  has_many :sources,    through: :categorizations, source: :categorizable, source_type: "Source"
 
  has_many :wars,       through: :categorizations, source: :categorizable, source_type: "War"
 
  has_many :battles,    through: :categorizations, source: :categorizable, source_type: "Battle"
  
  has_many :medals,     through: :categorizations, source: :categorizable, source_type: "Medal"

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :topics,     -> { where(category_type: "topic") }
  scope :sources,    -> { where(category_type: "source") }
  scope :locations,  -> { where(category_type: "location") }
  scope :wars,       -> { where(category_type: "war") }
  scope :battles,    -> { where(category_type: "battle") }
  scope :medals,     -> { where(category_type: "medal") }
  scope :by_name_ci, ->(name) { where("lower(name) = ?", name.to_s.downcase) }
  scope :soldiers, -> { where(category_type: "soldier") }


  # ---- medal category helpers ----
  def self.medals_parent_name = "Medals"

  def self.ensure_medals_parent!
    by_name_ci(medals_parent_name).first_or_create!
  end

  def self.medal_children(fallback: true)
    if column_names.include?("parent_id")
      if (parent = by_name_ci(medals_parent_name).first)
        where(parent_id: parent.id).order(:name)
      else
        fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
      end
    elsif reflect_on_association(:children)
      if (parent = by_name_ci(medals_parent_name).first)
        parent.children.order(:name)
      else
        fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
      end
    else
      fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
    end
  end

-----
def set_cemetery preload = { burials: :participant, involvements: :participant } @cemetery = Cemetery.includes(preload).find_by(slug: params[:id]) || Cemetery.includes(preload).find_by(id: params[:id]) raise ActiveRecord::RecordNotFound, "Cemetery not found" unless @cemetery end end
-------------

# app/controllers/soldiers_controller.rb
class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit create update]
  before_action :build_nested_rows, only: %i[new edit]
  
  # GET /soldiers
  def index
    @q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = scope.search_name(@q) if @q.present?

    @total_count = scope.count
    @total_pages = (@total_count.to_f / page_size).ceil

    offset     = (current_page - 1) * page_size
    @soldiers  = scope.limit(page_size).offset(offset)
    @has_next  = current_page < @total_pages

    # Optional: medals category list (best-effort)
    @medal_categories = begin
      parent = Category.where("lower(name) = ?", "medals").first
      if parent && Category.column_names.include?("parent_id")
        Category.where(parent_id: parent.id).order(:name)
      elsif parent && parent.respond_to?(:children)
        parent.children.order(:name)
      else
        Category.where("name ILIKE ?", "%medal%").order(:name)
      end
    rescue
      []
    end
  end

  # GET /soldiers/:id
  def show
    # We already loaded @soldier in set_soldier; just preload for view
    ActiveRecord::Associations::Preloader.new.preload(
      @soldier,
      [:cemetery, :awards, { citations: :source }, :categories]
    )
  end

  # GET /soldiers/new
  def new
    @soldier = Soldier.new
    build_nested_rows
  end

  # GET /soldiers/:id/edit
  def edit
    build_nested_rows
  end

  # POST /soldiers
  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
      redirect_to @soldier, notice: "Soldier created."
    else
      build_nested_rows
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /soldiers/:id
  def update
    if @soldier.update(soldier_params)
      redirect_to @soldier, notice: "Soldier updated."
    else
      build_nested_rows
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /soldiers/:id
  def destroy
    @soldier.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end

  # PATCH /soldiers/:id/regenerate_slug
  def regenerate_slug
    @soldier.regenerate_slug!
    redirect_to @soldier, notice: "Slug regenerated."
  end

  # GET /soldiers/search.json?q=...
  def search
    q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = Soldier.search_name(q).order(:last_name, :first_name) if q.present? && Soldier.respond_to?(:search_name)
    render json: scope.limit(10).map { |s|
      base = (s.respond_to?(:soldier_name) && s.soldier_name.presence) ||
             [s.try(:first_name), s.try(:last_name)].compact.join(" ").presence ||
             s.try(:name) || s.try(:title) || s.try(:slug) || "Soldier ##{s.id}"
      { id: s.id, label: "#{base} (##{s.id})" }
    }
  end

  private

  def set_soldier
    @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
  end

  def load_sources
    @sources = Source.order(:title)
  end

  # Ensure at least one nested row so fields_for renders on empty sets
  def build_nested_rows
    @soldier.awards.build           if @soldier.awards.empty?
    @soldier.soldier_medals.build   if @soldier.soldier_medals.empty?
    @soldier.involvements.build     if @soldier.involvements.empty?
    @soldier.citations.build        if @soldier.citations.empty?
  end

  def page_size     = (params[:per_page].presence || 30).to_i.clamp(1, 200)
  def current_page  = (params[:page].presence || 1).to_i.clamp(1, 10_000)

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birthcity, :birthstate, :birthcountry,
      :death_date, :deathcity, :deathstate, :deathcountry,
      :cemetery_id, :unit, :branch_of_service,
      { category_ids: [] },

      awards_attributes: [:id, :name, :country, :year, :note, :_destroy],
      soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],
      involvements_attributes: [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy],

      citations_attributes: [
        :id, :source_id, :_destroy,
        :page, :pages, :folio, :column, :line_number, :record_number, :locator,
        :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
    )
  end
end

-------------

<div class="mb-2"><%= f.label :first_name %><%= f.text_field :first_name, class: "form-control" %></div>
<div class="mb-2"><%= f.label :first_name %><%= f.text_field :middle_name, class: "form-control" %></div>
<div class="mb-2"><%= f.label :last_name  %><%= f.text_field :last_name,  class: "form-control" %></div>
<div class="mb-2"><%= f.label :birth_date  %><%= f.text_field :birth_date,  class: "form-control" %></div>
<div class="mb-2"><%= f.label :death_date  %><%= f.text_field :death_date ,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :birthcity  %><%= f.text_field :birthcity,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :birthstate  %><%= f.text_field :birthstate,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :birthcountry  %><%= f.text_field :birthcountry,  class: "form-control" %></div>



<div class="mb-2"><%= f.label :deathcountry  %><%= f.text_field :deathcountry,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :first_enlisted_start_date %><%= f.date_field :first_enlisted_start_date,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :first_enlisted_end_date  %><%= f.date_field :first_enlisted_end_date,  class: "form-control" %></div>

<div class="mb-2"><%= f.label :first_enlisted_place  %><%= f.text_field :first_enlisted_place,  class: "form-control" %></div>


<div class="mb-2"><%= f.label :unit %><%= f.text_field :unit, class: "form-control" %></div>

<div class="mb-2"><%= f.label :branch_of_service, "Branch of Service" %><%= f.text_field :branch_of_service, class: "form-control" %></div>


<fieldset class="mb-3">
  <legend>Cemetery</legend>
  <%= f.collection_select :cemetery_id, Cemetery.order(:name), :id, :name, { include_blank: true }, class: "form-select" %>
</fieldset>

<fieldset class="mb-3">
  <legend>Awards (not medals)</legend>
  <%= f.fields_for :awards do |af| %>
    <div class="border p-2 mb-3 rounded">
      <div class="row g-2">
        <div class="col-md-5"><%= af.label :name %><%= af.text_field :name, class: "form-control" %></div>
        <div class="col-md-3"><%= af.label :country %><%= af.text_field :country, class: "form-control" %></div>
        <div class="col-md-2"><%= af.label :year %><%= af.number_field :year, in: 1000..3000, step: 1, class: "form-control" %></div>
        <div class="col-12"><%= af.label :note %><%= af.text_area :note, rows: 2, class: "form-control" %></div>
        <div class="col-12 form-check mt-1"><label class="form-check-label"><%= af.check_box :_destroy, class: "form-check-input" %> Remove</label></div>
      </div>
    </div>
  <% end %>
</fieldset>

<fieldset class="mb-3">
  <legend>Medals</legend>
  <%= f.fields_for :soldier_medals do |mf| %>
    <div class="border p-2 mb-3 rounded">
      <div class="row g-2">
        <div class="col-md-6"><%= mf.label :medal_id, "Medal" %><%= mf.collection_select :medal_id, Medal.order(:name), :id, :name, { include_blank: true }, class: "form-select" %></div>
        <div class="col-md-2"><%= mf.label :year %><%= mf.number_field :year, in: 1000..3000, step: 1, class: "form-control" %></div>
        <div class="col-12"><%= mf.label :note %><%= mf.text_area :note, rows: 2, class: "form-control" %>
        </div>
        <div class="col-12 form-check mt-1"><label class="form-check-label"><%= mf.check_box :_destroy, class: "form-check-input" %> Remove</label></div>
      </div>
    </div>
  <% end %>
</fieldset>

<%# wars & battles (both write to category_ids[]) %>
<fieldset class="mb-3">
  <legend>Wars</legend>
  <%= f.collection_select :category_ids, Category.wars.order(:name), :id, :name, { include_hidden: false }, { multiple: true, size: 6, class: "form-select" } %>
</fieldset>
<fieldset class="mb-3">
  <legend>Battles</legend>
  <%= f.collection_select :category_ids, Category.battles.order(:name), :id, :name, { include_hidden: false }, { multiple: true, size: 8, class: "form-select" } %>
</fieldset>

<%# involvements (edit form rows) %>
# <fieldset class="mb-3">
#   <legend>Involvements</legend>
#   <div data-controller="involvements" data-involvements-index-value="<%= @soldier.involvements.size %>">
#     <div data-involvements-target="list">
#       <% f.fields_for :involvements do |ivf| %>
#         <div data-involvements-wrapper>
#           <%#= render "soldiers/involvement_fields", ivf: ivf %>
#         </div>
#       <% end %>
#     </div>
#     <template data-involvements-target="template">
#       <div data-involvements-wrapper>
#         <%#= f.fields_for :involvements, Involvement.new, child_index: "NEW_RECORD" do |ivf| %>
#           <%#= render "soldiers/involvement_fields", ivf: ivf %>
#         <% end %>
#       </div>
#     </template>
#     <p class="mt-2"><button type="button" class="btn btn-sm btn-outline-primary" data-action="involvements#add">Add involvement</button></p>
#   </div>
# </fieldset>

<fieldset class="mb-3">
  <legend>Involvements (AJAX)</legend>

  <div data-controller="involvement-form">
    <!-- This is the “formTarget” container whose dataset carries the chosen type/id -->
    <div data-involvement-form-target="form"
         data-involvable-type="War"
         data-involvable-id="">

      <!-- Soldier (participant) -->
      <%= hidden_field_tag :participant_id, @soldier.id,
            data: { "involvement-form-target": "participantId" } %>

      <div class="row g-2 align-items-end">
        <div class="col-md-3">
          <label class="form-label">Type</label>
          <select class="form-select"
                  onchange="this.closest('[data-controller]').querySelector('[data-involvement-form-target=form]').dataset.involvableType = this.value">
            <option value="War">War</option>
            <option value="Battle">Battle</option>
            <option value="Cemetery">Cemetery</option>
          </select>
        </div>

        <div class="col-md-4">
          <label class="form-label">Choose record</label>
          <select class="form-select"
                  onchange="this.closest('[data-controller]').querySelector('[data-involvement-form-target=form]').dataset.involvableId = this.value">
            <option value="">— pick a war —</option>
            <% War.order(:name).each do |w| %>
              <option value="<%= w.id %>"><%= w.name %></option>
            <% end %>
          </select>

          <!-- (Optional) You can dynamically swap the list for Battle/Cemetery using a Stimulus picker later -->
        </div>

        <div class="col-md-2">
          <label class="form-label">Role</label>
          <input type="text" class="form-control" data-involvement-form-target="role">
        </div>

        <div class="col-md-2">
          <label class="form-label">Year</label>
          <input type="number" min="1" max="2999" step="1" class="form-control" data-involvement-form-target="year">
        </div>

        <div class="col-md-12 mt-2">
          <label class="form-label">Note</label>
          <textarea rows="2" class="form-control" data-involvement-form-target="note"></textarea>
        </div>

        <div class="col-md-12 mt-2">
          <button type="button" class="btn btn-sm btn-outline-primary"
                  data-action="involvement-form#add">
            Add involvement
          </button>
        </div>
      </div>
    </div>

    <hr class="my-3">

    <h6 class="mb-2">Current involvements</h6>
    <ul class="list-unstyled" data-involvement-form-target="list">
      <% @soldier.involvements.includes(:involvable).order(:year, :id).each do |inv| %>
        <li class="mb-2" data-involvement-row="<%= inv.id %>">
          <%= link_to inv.participant_label, @soldier %>
          <%= " — " + content_tag(:strong, inv.role) if inv.role.present? %>
          <%= " (#{inv.year})" if inv.year.present? %>
          <%= " — " + content_tag(:em, inv.note) if inv.note.present? %>
          <button type="button"
                  class="btn btn-sm btn-outline-danger ms-2"
                  data-action="involvement-form#remove"
                  data-involvement-form-id-param="<%= inv.id %>">Remove</button>
        </li>
      <% end %>
    </ul>
  </div>
</fieldset>


<fieldset class="mb-3">
  <legend>Citations</legend>
  <div data-controller="citations" data-citations-index-value="<%= @soldier.citations.size %>">
    <div data-citations-target="list">
      <% f.fields_for :citations do |cf| %>
        <div data-citations-wrapper">
          <%= render "citations/fields", cf: cf, sources: (@sources || Source.order(:title)) %>
        </div>
      <% end %>
    </div>
    <template data-citations-target="template">
      <div data-citations-wrapper>
        <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
          <%= render "citations/fields", cf: cf, sources: (@sources || Source.order(:title)) %>
        <% end %>
      </div>
    </template>
     <p class="mt-2"><button type="button" class="btn btn-sm btn-outline-primary" data-action="citations#add">Add citation</button></p>
  </div>
</fieldset>
<% end %>

-----

fieldset class="mb-3">
  <legend>Medals</legend>
  <%= f.fields_for :soldier_medals do |mf| %>
    <div class="border p-2 mb-3 rounded">
      <div class="row g-2">
        <div class="col-md-6">
          <%= mf.label :medal_id, "Medal" %>
          <%= mf.collection_select :medal_id, Medal.order(:name), :id, :name, { include_blank: true }, class: "form-select" %>
        </div>
        <div class="col-md-2"><%= mf.label :year %><%= mf.number_field :year, in: 1000..3000, step: 1, class: "form-control" %></div>
        <div class="col-12"><%= mf.label :note %><%= mf.text_area :note, rows: 2, class: "form-control" %></div>
        <div class="col-12 form-check mt-1">
          <label class="form-check-label"><%= mf.check_box :_destroy, class: "form-check-input" %> Remove</label>
        </div>
      </div>
    </div>
  <% end %>
</fieldset>

----

<h2>Soldiers buried here (<%= @soldier_burials_count %>)</h2>
<% if @soldier_burials.any? %>
  <% @soldier_burials.each do |b| %>
    <% s = b.respond_to?(:participant) ? b.participant : b %>
    <!-- render soldier row (name, birth, death) -->
  <% end %>
<% else %>
  <p>No burials recorded.</p>
<% end %>

<h2>Other burials (<%= @other_burials_count %>)</h2>
<% @other_burials.each do |b| %>
  <!-- render non-soldier burial row -->
<% end %>
