You got it—here’s a clean, working Soldier CRUD bundle (controller + views + the citations partial + the two Stimulus controllers) pasted inline so you can drop them in. I wasn’t able to generate the zip in this chat, so copy the files below into your app in the indicated paths.
app/controllers/soldiers_controller.rb
class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit create update]

  def index
    @q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = scope.search_name(@q) if @q.present?

    per  = (params[:per_page].presence || 50).to_i.clamp(1, 200)
    page = (params[:page].presence    || 1).to_i.clamp(1, 10_000)

    @soldiers = scope.limit(per + 1).offset((page - 1) * per)
    @has_next = @soldiers.length > per
    @soldiers = @soldiers.first(per)
  end

  def show
    @soldier = Soldier.includes(:cemetery,
                                :awards,
                                { soldier_medals: :medal },
                                { citations: :source },
                                :categories).find(@soldier.id)
  end

  def new
    @soldier = Soldier.new
    @soldier.awards.build
    @soldier.soldier_medals.build
    @soldier.citations.build
  end

  def edit
    @soldier.awards.build         if @soldier.awards.empty?
    @soldier.soldier_medals.build if @soldier.soldier_medals.empty?
    @soldier.citations.build      if @soldier.citations.empty?
  end

  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
      redirect_to @soldier, notice: "Soldier created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @soldier.update(soldier_params)
      redirect_to @soldier, notice: "Soldier updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @soldier.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end

  def regenerate_slug
    @soldier.regenerate_slug!
    redirect_to @soldier, notice: "Slug regenerated."
  end

  # /soldiers/search.json?q=...
  def search
    q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = Soldier.search_name(q) if q.present? && Soldier.respond_to?(:search_name)
    render json: scope.limit(10).map { |s|
      base = ([s.try(:first_name), s.try(:last_name)].compact.join(" ").presence ||
              s.try(:slug) || "Soldier ##{s.id}")
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

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birthcity, :birthstate, :birthcountry, :birth_date,
      :deathcity, :deathstate, :deathcountry, :death_date,
      :unit, :branch_of_service,
      :cemetery_id,
      { category_ids: [] },
      awards_attributes: [:id, :name, :country, :year, :note, :_destroy],
      soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],
      citations_attributes: [
        :id, :source_id, :_destroy,
        :page, :pages, :folio, :column, :line_number, :record_number, :locator,
        :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
    )
  end
end
app/views/soldiers/index.html.erb
<h1>Soldiers</h1>

<%= form_with url: soldiers_path, method: :get, local: true, class: "row g-3 align-items-end" do %>
  <div class="col-md-4">
    <%= label_tag :q, "Search", class: "form-label" %>
    <%= text_field_tag :q, params[:q].to_s, class: "form-control", placeholder: "Name, slug…" %>
  </div>
  <div class="col-auto">
    <%= label_tag :per_page, "Per page", class: "form-label" %>
    <%= number_field_tag :per_page, (params[:per_page].presence || 50), class: "form-control", min: 1, max: 200, step: 1 %>
  </div>
  <div class="col-auto">
    <%= submit_tag "Filter", class: "btn btn-primary mt-4" %>
    <%= link_to "Reset", soldiers_path, class: "btn btn-link mt-4" %>
  </div>
<% end %>

<%= render "pager" %>
<%= render "list", soldiers: @soldiers %>
<%= render "pager" %>
app/views/soldiers/_pager.html.erb
<% curr_page  = params.fetch(:page, 1).to_i %>
<% per        = (params[:per_page].presence || 50).to_i %>
<% q          = params[:q].presence %>

<div class="d-flex justify-content-between align-items-center mt-3 mb-3">
  <% prev_params = { page: [curr_page - 1, 1].max, per_page: per, q: q }.compact %>
  <% next_params = { page: curr_page + 1, per_page: per, q: q }.compact %>

  <div>
    <% if curr_page > 1 %>
      <%= link_to "← Prev", soldiers_path(prev_params), class: "btn btn-outline-secondary" %>
    <% else %>
      <button class="btn btn-outline-secondary" disabled>← Prev</button>
    <% end %>
  </div>

  <div class="text-muted">Page <%= curr_page %></div>

  <div>
    <% if @has_next %>
      <%= link_to "Next →", soldiers_path(next_params), class: "btn btn-outline-secondary" %>
    <% else %>
      <button class="btn btn-outline-secondary" disabled>Next →</button>
    <% end %>
  </div>
</div>
app/views/soldiers/_list.html.erb
<table class="table table-sm">
  <thead>
    <tr>
      <th>Name</th>
      <th>Created</th>
    </tr>
  </thead>
  <tbody>
    <% soldiers.each do |soldier| %>
      <tr>
        <td><%= link_to(([soldier.first_name, soldier.last_name].compact.join(" ").presence || soldier.slug), soldier) %></td>
        <td><%= (defined?(l) ? l(soldier.created_at, format: :short) : soldier.created_at) rescue soldier.created_at %></td>
      </tr>
    <% end %>
  </tbody>
</table>
app/views/soldiers/_form.html.erb
<%= form_with model: @soldier do |f| %>
  <fieldset class="border rounded p-3 mb-3">
    <legend class="fw-bold small">Soldier</legend>
    <div class="row g-3">
      <div class="col-md-4">
        <%= f.label :first_name %>
        <%= f.text_field :first_name, class: "form-control" %>
      </div>
      <div class="col-md-4">
        <%= f.label :middle_name %>
        <%= f.text_field :middle_name, class: "form-control" %>
      </div>
      <div class="col-md-4">
        <%= f.label :last_name %>
        <%= f.text_field :last_name, class: "form-control" %>
      </div>
    </div>

    <div class="row g-3 mt-1">
      <div class="col-md-6">
        <%= f.label :unit %>
        <%= f.text_field :unit, class: "form-control" %>
      </div>
      <div class="col-md-6">
        <%= f.label :branch_of_service, "Branch of Service" %>
        <%= f.text_field :branch_of_service, class: "form-control" %>
      </div>
    </div>
  </fieldset>

  <fieldset class="border rounded p-3 mb-3">
    <legend class="fw-bold small">Cemetery</legend>
    <%= f.collection_select :cemetery_id, Cemetery.order(:name), :id, :name, include_blank: true, class: "form-select" %>
  </fieldset>

  <fieldset class="border rounded p-3 mb-3">
    <legend class="fw-bold small">Awards (not medals)</legend>
    <%= f.fields_for :awards do |af| %>
      <div class="border p-2 mb-3 rounded">
        <div class="row g-2">
          <div class="col-md-4">
            <%= af.label :name %>
            <%= af.text_field :name, class: "form-control", placeholder: "e.g., Community Service Award" %>
          </div>
          <div class="col-md-3">
            <%= af.label :country %>
            <%= af.text_field :country, class: "form-control" %>
          </div>
          <div class="col-md-2">
            <%= af.label :year %>
            <%= af.number_field :year, in: 1..3000, step: 1, class: "form-control" %>
          </div>
          <div class="col-md-3">
            <%= af.label :note %>
            <%= af.text_area :note, rows: 1, class: "form-control" %>
          </div>
        </div>
        <label class="mt-1"><%= af.check_box :_destroy %> Remove</label>
      </div>
    <% end %>
  </fieldset>

  <fieldset class="border rounded p-3 mb-3">
    <legend class="fw-bold small">Medals</legend>
    <%= f.fields_for :soldier_medals do |mf| %>
      <div class="border p-2 mb-3 rounded">
        <div class="row g-2">
          <div class="col-md-6">
            <%= mf.label :medal_id, "Medal" %>
            <%= mf.collection_select :medal_id, Medal.order(:name), :id, :name, include_blank: true, class: "form-select" %>
          </div>
          <div class="col-md-2">
            <%= mf.label :year %>
            <%= mf.number_field :year, in: 1..3000, step: 1, class: "form-control" %>
          </div>
          <div class="col-md-4">
            <%= mf.label :note %>
            <%= mf.text_area :note, rows: 1, class: "form-control" %>
          </div>
        </div>
        <label class="mt-1"><%= mf.check_box :_destroy %> Remove</label>
      </div>
    <% end %>
  </fieldset>

  <fieldset class="border rounded p-3 mb-3">
    <legend class="fw-bold small">Citations</legend>
    <div data-controller="citations"
         data-citations-index-value="<%= @soldier.citations.size %>">

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

      <p class="mt-2">
        <button type="button"
                class="btn btn-sm btn-outline-primary"
                data-action="citations#add">Add citation</button>
      </p>
    </div>
  </fieldset>

  <div class="mt-3">
    <%= f.submit class: "btn btn-primary" %>
    <%= link_to "Cancel", (@soldier.persisted? ? @soldier : soldiers_path), class: "btn btn-link" %>
  </div>
<% end %>
app/views/soldiers/new.html.erb
<h1>New Soldier</h1>
<%= render "form" %>
app/views/soldiers/edit.html.erb
<h1>Edit Soldier</h1>
<%= render "form" %>
app/views/soldiers/show.html.erb
<h1><%= @soldier.respond_to?(:display_name) ? @soldier.display_name : [@soldier.first_name, @soldier.last_name].compact.join(" ") %></h1>

<p>
  <strong>Unit:</strong> <%= @soldier.unit %><br>
  <strong>Branch:</strong> <%= @soldier.branch_of_service %><br>
  <strong>Cemetery:</strong>
  <%= @soldier.cemetery ? link_to(@soldier.cemetery.name, @soldier.cemetery) : content_tag(:em, "Not recorded") %>
</p>

<h3>Awards</h3>
<% if @soldier.awards.exists? %>
  <ul>
    <% @soldier.awards.order(:year, :id).each do |aw| %>
      <li>
        <strong><%= aw.name.presence || "(Unnamed award)" %></strong>
        <%= " (#{aw.year})" if aw.year.present? %>
        <%= " — #{aw.country}" if aw.country.present? %>
        <%= " — #{aw.note}"    if aw.note.present? %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p><em>No awards recorded.</em></p>
<% end %>

<h3>Medals</h3>
<% if @soldier.medals.exists? %>
  <ul>
    <% @soldier.medals.order(:name).each do |m| %>
      <li><%= link_to m.name, m %></li>
    <% end %>
  </ul>
<% else %>
  <p><em>No medals recorded.</em></p>
<% end %>

<h3>Citations</h3>
<%= render "shared/citations", citable: @soldier, heading: "Soldier Citations" rescue nil %>

<p class="mt-3">
  <%= link_to "Edit", edit_soldier_path(@soldier), class: "btn btn-outline-secondary" %>
  <%= link_to "Back", soldiers_path, class: "btn btn-secondary ms-2" %>
</p>
app/views/citations/_fields.html.erb
<div class="border p-3 mb-3 rounded citation-fields"
     data-controller="source-picker"
     data-citations-wrapper>

  <div class="d-flex justify-content-between align-items-center mb-2">
    <strong>Citation</strong>
    <button type="button" class="btn btn-sm btn-outline-danger" data-action="citations#remove">Remove</button>
  </div>

  <div class="field mb-2">
    <%= f.label :source_id, "Source" %>
    <%= f.collection_select :source_id,
          (defined?(sources) && sources.present?) ? sources : Source.order(:title),
          :id, :title,
          { include_blank: "— Select a source —" },
          { class: "form-select", data: { "source-picker-target": "select" } } %>
  </div>

  <div class="mb-2">
    <label>Search all sources</label>
    <input type="text"
           class="form-control"
           placeholder="Type 2+ letters…"
           data-action="input->source-picker#autocomplete"
           data-source-picker-target="query">
    <ul class="list-group mt-1" data-source-picker-target="results"></ul>
  </div>

  <% recent = Source.order(updated_at: :desc).limit(10) %>
  <% if recent.any? %>
    <div class="mb-2">
      <label>Recent</label>
      <%= select_tag :recent_source_id,
            options_for_select([["— Pick recent —",""]] + recent.map { |s| [s.title, s.id] }),
            class: "form-select",
            data: { action: "change->source-picker#pick" } %>
    </div>
  <% end %>

  <div class="mt-3">
    <button class="btn btn-sm btn-outline-secondary"
            type="button"
            data-action="click->source-picker#toggleNewForm">
      + Add a new source instead
    </button>

    <div class="mt-2" data-source-picker-target="newForm" style="display:none">
      <div class="alert alert-info py-2 px-3 mb-2">
        Leave “Source” above blank if you enter a new one here.
      </div>

      <%= f.fields_for :source do |sf| %>
        <div class="row g-3">
          <div class="col-md-8">
            <%= sf.label :title %>
            <%= sf.text_field :title, class: "form-control",
                  placeholder: "Book/Newspaper/Collection title",
                  data: { action: "input->source-picker#clearSelectIfTyped" } %>
          </div>
          <div class="col-md-4">
            <%= sf.label :author %>
            <%= sf.text_field :author, class: "form-control" %>
          </div>
          <div class="col-md-3">
            <%= sf.label :publisher %>
            <%= sf.text_field :publisher, class: "form-control" %>
          </div>
          <div class="col-md-2">
            <%= sf.label :year %>
            <%= sf.text_field :year, class: "form-control" %>
          </div>
          <div class="col-md-7">
            <%= sf.label :url, "URL" %>
            <%= sf.url_field :url, class: "form-control" %>
          </div>
          <div class="col-md-6">
            <%= sf.label :repository %>
            <%= sf.text_field :repository, class: "form-control" %>
          </div>
          <div class="col-md-6">
            <%= sf.label :link_url, "Repository link" %>
            <%= sf.url_field :link_url, class: "form-control" %>
          </div>
          <div class="col-12">
            <%= sf.label :details %>
            <%= sf.text_area :details, rows: 2, class: "form-control" %>
          </div>
        </div>
      <% end %>
    </div>
  </div>

  <div class="row g-3 mt-3">
    <div class="col-md-6">
      <%= f.label :pages, "Page(s)" %>
      <%= f.text_field :pages, class: "form-control", placeholder: "e.g., 12–13" %>
    </div>
    <div class="col-md-6">
      <%= f.label :folio %>
      <%= f.text_field :folio, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :column %>
      <%= f.text_field :column, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :line_number, "Line #" %>
      <%= f.text_field :line_number, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :record_number %>
      <%= f.text_field :record_number, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :locator, "Other locator" %>
      <%= f.text_field :locator, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :image_url, "Image URL" %>
      <%= f.url_field :image_url, class: "form-control" %>
    </div>
    <div class="col-md-3">
      <%= f.label :image_frame, "Frame" %>
      <%= f.text_field :image_frame, class: "form-control" %>
    </div>
    <div class="col-md-3">
      <%= f.label :roll, "Roll / Piece" %>
      <%= f.text_field :roll, class: "form-control" %>
    </div>
    <div class="col-md-6">
      <%= f.label :enumeration_district, "ED" %>
      <%= f.text_field :enumeration_district, class: "form-control" %>
    </div>
  </div>

  <div class="mt-3">
    <%= f.label :quote %>
    <%= f.text_area :quote, rows: 2, class: "form-control" %>
  </div>
  <div class="mt-2">
    <%= f.label :note %>
    <%= f.text_area :note, rows: 2, class: "form-control" %>
  </div>

  <%= f.check_box :_destroy, style: "display:none" %>
</div>
app/javascript/controllers/citations_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]
  static values = { index: Number }

  connect() {
    if (this.indexValue == null) this.indexValue = this._nextIndex()
  }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.indexValue)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.indexValue++
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.currentTarget.closest("[data-citations-wrapper]")
    const destroyField = wrapper?.querySelector("input[name*='[_destroy]']")
    if (destroyField) {
      destroyField.value = "1"
      wrapper.style.display = "none"
    } else {
      wrapper?.remove()
    }
  }

  _nextIndex() {
    return this.listTarget.querySelectorAll("[data-citations-wrapper]").length
  }
}
app/javascript/controllers/source_picker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "select", "newForm"]

  pick(event) {
    const id = event.target.value
    if (!id) return
    const title = event.target.options[event.target.selectedIndex]?.textContent || `Source #${id}`
    this._setSelected(id, title)
    event.target.selectedIndex = 0
  }

  autocomplete() {
    const q = this.hasQueryTarget ? this.queryTarget.value.trim() : ""
    clearTimeout(this._t)
    if (!q || q.length < 2) {
      if (this.hasResultsTarget) this.resultsTarget.innerHTML = ""
      return
    }
    this._t = setTimeout(async () => {
      try {
        const res = await fetch(`/sources/autocomplete?q=${encodeURIComponent(q)}`)
        if (!res.ok) return
        const items = await res.json()
        if (!this.hasResultsTarget) return
        this.resultsTarget.innerHTML = items.map(i =>
          `<li class="list-group-item" data-id="${i.id}" data-title="${this._escape(i.title)}">${this._escape(i.title)}</li>`
        ).join("")
        this.resultsTarget.querySelectorAll("li").forEach(li => {
          li.addEventListener("click", () => {
            this._setSelected(li.dataset.id, li.dataset.title)
            this.resultsTarget.innerHTML = ""
            if (this.hasQueryTarget) this.queryTarget.value = li.dataset.title
          })
        })
      } catch (_) {}
    }, 200)
  }

  toggleNewForm() {
    if (!this.hasNewFormTarget) return
    const el = this.newFormTarget
    el.style.display = (el.style.display === "none" || !el.style.display) ? "block" : "none"
  }

  clearSelectIfTyped() {
    if (this.hasSelectTarget) this.selectTarget.innerHTML = '<option value="" selected></option>'
  }

  _setSelected(id, title) {
    if (!this.hasSelectTarget) return
    this.selectTarget.innerHTML = `<option value="${id}" selected>${this._escape(title)}</option>`
  }

  _escape(s) {
    return (s || "").replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))
  }
}
Quick wiring checklist
•	Routes:
•	resources :soldiers do
•	  collection { get :search, defaults: { format: :json } }
•	  patch :regenerate_slug, on: :member
•	end
•	
•	resources :sources do
•	  get :autocomplete, on: :collection
•	end
•	
•	Models:
o	Soldier should have accepts_nested_attributes_for :awards, allow_destroy: true, :soldier_medals, and :citations.
o	Citation should have accepts_nested_attributes_for :source, reject_if: ->(a){ a['title'].blank? && a['id'].blank? }.
•	JS:
o	Ensure Stimulus is set up and your application.js imports controllers (e.g., via import "./controllers" with an index that registers both controllers).
If you want, I can try packaging this again next message—but the content above is everything you need.
You said:
ok, thank you
ChatGPT said:
You’re welcome! If you hit any bumps wiring these in (routes, nested attributes, or Stimulus targets), send me the exact error and the file/line — I’ll zero in fast. Want me to add the SoldiersController specs or a tiny system test next?
You said:
please
ChatGPT said:
