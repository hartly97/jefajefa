import os, textwrap, zipfile

base = "/mnt/data/session_pack_v5"
paths = [
    "app/controllers",
    "app/views/soldiers",
    "app/views/shared",
    "app/views/wars",
    "app/javascript/controllers"
]
for p in paths:
    os.makedirs(os.path.join(base, p), exist_ok=True)

files = {}

# Controllers
files["app/controllers/sources_controller.rb"] = textwrap.dedent("""\
class SourcesController < ApplicationController
  before_action :set_source,    only: [:show, :edit, :update, :destroy, :regenerate_slug, :create_citation]
  before_action :require_admin, only: [:regenerate_slug]

  def index
    @sources = Source.order(:title)
  end

  def show; end

  def new
    @source = Source.new
  end

  def edit; end

  def create
    @source = Source.new(source_params)
    if @source.save
      redirect_to @source, notice: "Source created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: "Source updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_path, notice: "Source deleted."
  end

  def regenerate_slug
    @source.regenerate_slug! if @source.respond_to?(:regenerate_slug!)
    redirect_to @source, notice: "Slug regenerated."
  end

  # GET /sources/autocomplete?q=ha
  def autocomplete
    q = params[:q].to_s.strip
    return render json: [] if q.length < 2

    results = Source
      .where("title ILIKE ?", "%#{q}%")
      .order(:title)
      .limit(20)
      .pluck(:id, :title)
      .map { |id, title| { id: id, title: title } }

    render json: results
  end

  # POST /sources/:id/create_citation
  # params: citable_type, citable_id, citation: {...}
  def create_citation
    citable = find_citable!
    citation = citable.citations.find_or_initialize_by(source: @source)
    citation.assign_attributes(citation_params)

    if citation.save
      redirect_to citable, notice: "Citation added."
    else
      redirect_to citable, alert: citation.errors.full_messages.to_sentence
    end
  end

  private

  ALLOWED_CITABLES = %w[Article Soldier War Battle Cemetery Medal Award Census CensusEntry Source].freeze

  def find_citable!
    type = params[:citable_type].to_s
    id   = params[:citable_id].presence
    raise ActiveRecord::RecordNotFound, "Bad citable" unless ALLOWED_CITABLES.include?(type) && id
    type.constantize.find(id)
  end

  def set_source
    @source = Source.find_by(slug: params[:id]) || Source.find(params[:id])
  end

  def source_params
    base = [:title, :author, :publisher, :year, :url, :details, :pages, :common, :repository, :link_url]
    base << { category_ids: [] } if respond_to?(:current_user) && current_user&.admin?
    params.require(:source).permit(*base)
  end

  def citation_params
    params.fetch(:citation, {}).permit(
      :pages, :folio, :page, :column, :line_number, :record_number,
      :image_url, :image_frame, :roll, :enumeration_district, :locator,
      :quote, :note
    )
  end

  def require_admin
    redirect_back fallback_location: root_path, alert: "Admins only." unless current_user&.admin?
  end
end
""")

files["app/controllers/soldiers_controller.rb"] = textwrap.dedent("""\
class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit]

  def index
    @q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = scope.search_name(@q) if @q.present?

    @total_count = scope.count
    @total_pages = (@total_count.to_f / page_size).ceil

    offset = (current_page - 1) * page_size
    @soldiers = scope.limit(page_size).offset(offset)
    @has_next  = current_page < @total_pages

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

  def show
    @soldier = Soldier
      .includes(:cemetery, :awards, { citations: :source }, :categories, :involvements)
      .find(@soldier.id)
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
    @soldier.category_names ||= @soldier.categories.order(:name).pluck(:name).join(", ") if @soldier.respond_to?(:category_names)
  end

  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
      redirect_to @soldier, notice: "Soldier created."
    else
      load_sources
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @soldier.update(soldier_params)
      redirect_to @soldier, notice: "Soldier updated."
    else
      load_sources
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

  def page_size
    (params[:per_page].presence || 30).to_i.clamp(1, 200)
  end

  def current_page
    (params[:page].presence || 1).to_i.clamp(1, 10_000)
  end

  def load_sources
    @sources = Source.order(:title)
  end

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birthcity, :birthstate, :birthcountry,
      :death_date, :deathcity, :deathstate, :deathcountry, :deathplace,
      :cemetery_id,
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
""")

files["app/controllers/involvements_controller.rb"] = textwrap.dedent("""\
class InvolvementsController < ApplicationController
  protect_from_forgery with: :exception

  def create
    attrs = involvement_params.merge(participant_type: "Soldier")
    inv = Involvement.find_or_initialize_by(
      participant_type: attrs[:participant_type],
      participant_id:   attrs[:participant_id],
      involvable_type:  attrs[:involvable_type],
      involvable_id:    attrs[:involvable_id]
    )
    inv.assign_attributes(role: attrs[:role], year: attrs[:year], note: attrs[:note])

    if inv.save
      render json: involvement_json(inv), status: :created
    else
      render json: { errors: inv.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    inv = Involvement.find_by!(
      participant_type: attrs[:participant_type],
      participant_id:   attrs[:participant_id],
      involvable_type:  attrs[:involvable_type],
      involvable_id:    attrs[:involvable_id]
    )
    inv.update(role: attrs[:role], year: attrs[:year], note: attrs[:note])
    render json: involvement_json(inv), status: :ok
  end

  def destroy
    inv = Involvement.find(params[:id])
    inv.destroy
    head :no_content
  end

  private

  def involvement_params
    params.require(:involvement).permit(:involvable_type, :involvable_id, :participant_id, :role, :year, :note)
  end

  def involvement_json(inv)
    participant = inv.participant
    label = participant.try(:display_name) ||
            [participant.try(:first_name), participant.try(:last_name)].compact.join(" ").presence ||
            "Soldier ##{inv.participant_id}"

    {
      id: inv.id,
      participant_id:   inv.participant_id,
      participant_type: inv.participant_type,
      participant_label: label,
      participant_path:  (participant && polymorphic_path(participant)),
      role: inv.role,
      year: inv.year,
      note: inv.note
    }
  end
end
""")

# Views
files["app/views/soldiers/_form.html.erb"] = textwrap.dedent("""\
<%= form_with model: @soldier, local: true do |f| %>
  <% if f.object.errors.any? %>
    <div class="alert alert-danger">
      <strong><%= pluralize(f.object.errors.count, "error") %></strong>
      <ul class="mb-0"><% f.object.errors.full_messages.each { |m| %><li><%= m %></li><% } %></ul>
    </div>
  <% end %>

  <fieldset class="mb-3">
    <legend>Soldier</legend>
    <div class="mb-2">
      <%= f.label :first_name %>
      <%= f.text_field :first_name, class: "form-control" %>
    </div>
    <div class="mb-2">
      <%= f.label :last_name %>
      <%= f.text_field :last_name, class: "form-control" %>
    </div>
  </fieldset>

  <fieldset class="mb-3">
    <legend>Cemetery</legend>
    <%= f.collection_select :cemetery_id, Cemetery.order(:name), :id, :name,
          { include_blank: true }, class: "form-select" %>
  </fieldset>

  <fieldset class="mb-3">
    <legend>Awards (not medals)</legend>
    <%= f.fields_for :awards do |af| %>
      <div class="border p-2 mb-3 rounded">
        <div class="row g-2">
          <div class="col-md-5"><%= af.label :name %><%= af.text_field :name, class: "form-control", placeholder: "e.g., Community Service Award" %></div>
          <div class="col-md-3"><%= af.label :country %><%= af.text_field :country, class: "form-control" %></div>
          <div class="col-md-2"><%= af.label :year %><%= af.number_field :year, in: 1000..3000, step: 1, class: "form-control" %></div>
          <div class="col-12"><%= af.label :note %><%= af.text_area :note, rows: 2, class: "form-control" %></div>
          <div class="col-12 form-check mt-1"><label class="form-check-label"><%= af.check_box :_destroy, class: "form-check-input" %> Remove</label></div>
        </div>
      </div>
    <% end %>
  </fieldset>

  <fieldset class="mb-3">
    <legend>Citations</legend>
    <div data-controller="citations" data-citations-index-value="<%= @soldier.citations.size %>">
      <div data-citations-target="list">
        <% f.fields_for :citations do |cf| %>
          <div data-citations-wrapper>
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

      <p class="mt-2">
        <button type="button" class="btn btn-sm btn-outline-primary" data-action="citations#add">
          Add citation
        </button>
      </p>
    </div>
  </fieldset>

  <fieldset class="mb-3">
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
          <div class="col-12 form-check mt-1"><label class="form-check-label"><%= mf.check_box :_destroy, class: "form-check-input" %> Remove</label></div>
        </div>
      </div>
    <% end %>
  </fieldset>

  <fieldset class="mb-3">
    <legend>Involvements</legend>
    <div data-controller="involvements" data-involvements-index-value="<%= @soldier.involvements.size %>">
      <div data-involvements-target="list">
        <% f.fields_for :involvements do |ivf| %>
          <div data-involvements-wrapper>
            <%= render "soldiers/involvement_fields", ivf: ivf %>
          </div>
        <% end %>
      </div>
      <template data-involvements-target="template">
        <div data-involvements-wrapper>
          <%= f.fields_for :involvements, Involvement.new, child_index: "NEW_RECORD" do |ivf| %>
            <%= render "soldiers/involvement_fields", ivf: ivf %>
          <% end %>
        </div>
      </template>
      <p class="mt-2">
        <button type="button" class="btn btn-sm btn-outline-primary" data-action="involvements#add">Add involvement</button>
      </p>
    </div>
  </fieldset>

  <fieldset class="mb-3">
    <legend>Wars</legend>
    <%= f.collection_select :category_ids,
          Category.wars.order(:name), :id, :name,
          { include_hidden: false },
          { multiple: true, size: 6, class: "form-select" } %>
  </fieldset>

  <fieldset class="mb-4">
    <legend>Battles</legend>
    <%= f.collection_select :category_ids,
          Category.battles.order(:name), :id, :name,
          { include_hidden: false },
          { multiple: true, size: 8, class: "form-select" } %>
  </fieldset>

  <%= f.submit "Save", class: "btn btn-primary" %>
<% end %>
""")

files["app/views/soldiers/_involvement_fields.html.erb"] = textwrap.dedent("""\
<div class="border p-2 mb-3 rounded" data-controller="involvement-picker">
  <%= ivf.hidden_field :involvable_type, data: { "involvement-picker-target": "typeField" } %>
  <%= ivf.hidden_field :involvable_id,   data: { "involvement-picker-target": "idField" } %>

  <div class="row g-2">
    <div class="col-md-3">
      <%= label_tag nil, "Type" %>
      <%= select_tag :_involvable_type,
            options_for_select([["War","War"],["Battle","Battle"],["Cemetery","Cemetery"]],
                               ivf.object.involvable_type.presence || "War"),
            class: "form-select",
            data: { action: "change->involvement-picker#changeType",
                    "involvement-picker-target": "typeSelect" } %>
    </div>

    <div class="col-md-5">
      <%= label_tag nil, "Choose War/Battle/Cemetery" %>
      <% wars    = War.order(:name) %>
      <% battles = Battle.order(:name) %>
      <% cemets  = Cemetery.order(:name) %>
      <%= select_tag :_war_select,
            options_from_collection_for_select(wars, :id, :name, ivf.object.involvable_type == "War" ? ivf.object.involvable_id : nil),
            include_blank: "— Pick a war —",
            class: "form-select",
            data: { action: "change->involvement-picker#pick",
                    "involvement-picker-target": "warSelect" } %>
      <%= select_tag :_battle_select,
            options_from_collection_for_select(battles, :id, :name, ivf.object.involvable_type == "Battle" ? ivf.object.involvable_id : nil),
            include_blank: "— Pick a battle —",
            class: "form-select mt-1",
            data: { action: "change->involvement-picker#pick",
                    "involvement-picker-target": "battleSelect" } %>
      <%= select_tag :_cemetery_select,
            options_from_collection_for_select(cemets, :id, :name, ivf.object.involvable_type == "Cemetery" ? ivf.object.involvable_id : nil),
            include_blank: "— Pick a cemetery —",
            class: "form-select mt-1",
            data: { action: "change->involvement-picker#pick",
                    "involvement-picker-target": "cemeterySelect" } %>
    </div>

    <div class="col-md-2">
      <%= ivf.label :year %>
      <%= ivf.number_field :year, in: 1000..3000, step: 1, class: "form-control" %>
    </div>
    <div class="col-md-2">
      <%= ivf.label :role %>
      <%= ivf.text_field :role, class: "form-control" %>
    </div>
    <div class="col-12">
      <%= ivf.label :note %>
      <%= ivf.text_area :note, rows: 2, class: "form-control" %>
    </div>
    <div class="col-12 mt-1">
      <label class="form-check-label">
        <%= ivf.check_box :_destroy, class: "form-check-input" %> Remove
      </label>
    </div>
  </div>
</div>
""")

files["app/views/soldiers/_list.html.erb"] = textwrap.dedent("""\
<table class="table table-sm">
  <thead>
    <tr>
      <th>Name</th>
      <th>Created</th>
      <th>Birth</th>
      <th>Death</th>
    </tr>
  </thead>
  <tbody>
    <% soldiers.each do |soldier| %>
      <tr>
        <td><%= link_to(([soldier.first_name, soldier.last_name].compact.join(" ").presence || soldier.slug), soldier) %></td>
        <td><%= (defined?(l) ? l(soldier.created_at, format: :short) : soldier.created_at) %></td>
        <td><%= [soldier.try(:birth_day),  soldier.try(:birth_month_name),  soldier.try(:birth_year)].compact.join(" ") %></td>
        <td><%= [soldier.try(:death_day),  soldier.try(:death_month_name),  soldier.try(:death_year)].compact.join(" ") %></td>
      </tr>
    <% end %>
  </tbody>
</table>
""")

files["app/views/soldiers/_pager.html.erb"] = textwrap.dedent("""\
<% prefix      = (local_assigns[:prefix] || "pg") %>
<% curr_page   = (params[:page].presence || 1).to_i %>
<% per         = (params[:per_page].presence || 30).to_i.clamp(1, 200) %>
<% total_pages = (defined?(@total_pages) && @total_pages.to_i > 0) ? @total_pages.to_i : nil %>
<% base_params = request.query_parameters.except(:page, :per_page) %>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mt-3">
  <div class="btn-group" role="group" aria-label="Pagination">
    <% if curr_page > 1 %>
      <%= link_to "« First", soldiers_path(base_params.merge(page: 1, per_page: per)), class: "btn btn-outline-secondary" %>
      <%= link_to "‹ Prev",  soldiers_path(base_params.merge(page: curr_page - 1, per_page: per)), class: "btn btn-outline-secondary" %>
    <% else %>
      <button class="btn btn-outline-secondary" disabled aria-disabled="true">« First</button>
      <button class="btn btn-outline-secondary" disabled aria-disabled="true">‹ Prev</button>
    <% end %>

    <% if total_pages && curr_page < total_pages %>
      <%= link_to "Next ›", soldiers_path(base_params.merge(page: curr_page + 1, per_page: per)), class: "btn btn-outline-secondary" %>
      <%= link_to "Last »", soldiers_path(base_params.merge(page: total_pages, per_page: per)), class: "btn btn-outline-secondary" %>
    <% else %>
      <button class="btn btn-outline-secondary" disabled aria-disabled="true">Next ›</button>
      <button class="btn btn-outline-secondary" disabled aria-disabled="true">Last »</button>
    <% end %>
  </div>

  <div>
    <%= form_with url: soldiers_path, method: :get, local: true, html: { class: "d-inline-flex align-items-center gap-2" } do %>
      <% base_params.each do |k,v| %>
        <% Array(v).each { |vv| %><%= hidden_field_tag k, vv %><% } %>
      <% end %>
      <label for="gotoPageInput_<%= prefix %>" class="form-label mb-0">Go to</label>
      <%= number_field_tag :page, curr_page,
            id: "gotoPageInput_#{prefix}",
            class: "form-control form-control-sm",
            min: 1, max: (total_pages || 1),
            style: "width: 5.5rem" %>
      <%= hidden_field_tag :per_page, per %>
      <%= submit_tag "Go", class: "btn btn-sm btn-outline-secondary" %>
    <% end %>
  </div>

  <div>
    <%= form_with url: soldiers_path, method: :get, local: true, html: { class: "d-inline-flex align-items-center gap-2" } do %>
      <% base_params.each do |k,v| %>
        <% Array(v).each { |vv| %><%= hidden_field_tag k, vv %><% } %>
      <% end %>
      <%= hidden_field_tag :page, 1 %>
      <label for="perPageSelect_<%= prefix %>" class="form-label mb-0 me-1">Per page</label>
      <%= select_tag :per_page,
            options_for_select([10,20,30,50,100], per),
            id: "perPageSelect_#{prefix}",
            class: "form-select form-select-sm",
            onchange: "this.form.submit();" %>
    <% end %>
  </div>

  <div class="text-muted ms-auto">
    <% if defined?(@total_count) && @total_count.to_i > 0 %>
      <% start_i = ((curr_page - 1) * per) + 1 %>
      <% end_i   = start_i + @soldiers.length - 1 %>
      Showing <%= start_i %>–<%= end_i %> of <%= @total_count %>
      <% if total_pages %> • Page <%= curr_page %> / <%= total_pages %><% end %>
    <% else %>
      No results
    <% end %>
  </div>
</div>
""")

files["app/views/shared/_involvements_panel.html.erb"] = textwrap.dedent("""\
<%# locals: involvable:, inv_label: "Soldier" (optional) %>
<% type    = involvable.class.name %>
<% dom_key = dom_id(involvable, :soldier_suggest) %>

<section data-controller="involvement-form" class="my-3">
  <form
    data-involvement-form-target="form"
    data-involvable-type="<%= type %>"
    data-involvable-id="<%= involvable.id %>"
    class="row g-2 align-items-end mb-3">

    <div class="col-md-5">
      <label class="form-label"><%= local_assigns[:inv_label] || "Soldier" %></label>
      <input type="text"
             class="form-control"
             list="<%= dom_key %>"
             placeholder="Type to search soldiers…"
             data-involvement-form-target="search">
      <datalist id="<%= dom_key %>" data-involvement-form-target="suggest"></datalist>
      <input type="hidden" data-involvement-form-target="participantId">
    </div>

    <div class="col-md-2">
      <label class="form-label">Role</label>
      <input type="text" class="form-control" data-involvement-form-target="role">
    </div>

    <div class="col-md-2">
      <label class="form-label">Year</label>
      <input type="number" min="1" max="3000" step="1" class="form-control" data-involvement-form-target="year">
    </div>

    <div class="col-md-3">
      <label class="form-label">Note</label>
      <input type="text" class="form-control" data-involvement-form-target="note">
    </div>

    <div class="col-12 mt-2">
      <button type="button"
              class="btn btn-sm btn-outline-primary"
              data-action="click->involvement-form#add">
        Add
      </button>
    </div>
  </form>

  <ul class="list-unstyled" data-involvement-form-target="list">
    <% involvable.involvements.includes(:participant).order(:year, :id).each do |inv| %>
      <li class="mb-2" data-involvement-row="<%= inv.id %>">
        <%= link_to(
              (inv.participant.try(:display_name) ||
               [inv.participant.try(:first_name), inv.participant.try(:last_name)].compact.join(" ").presence ||
               "Soldier ##{inv.participant_id}"),
              inv.participant
            ) %>
        <%= " — " + content_tag(:strong, inv.role) if inv.role.present? %>
        <%= " (#{inv.year})" if inv.year.present? %>
        <%= " — " + content_tag(:em, inv.note) if inv.note.present? %>
        <button class="btn btn-sm btn-outline-danger ms-2"
                data-action="click->involvement-form#remove"
                data-involvement-form-id-param="<%= inv.id %>">
          Remove
        </button>
      </li>
    <% end %>
  </ul>
</section>
""")

files["app/javascript/controllers/involvement_form_controller.js"] = textwrap.dedent("""\
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "list",
    "participantId", "role", "year", "note",
    "search", "suggest"
  ]

  connect() {
    if (this.hasSearchTarget && this.hasSuggestTarget) {
      this._onSearchInput = this.onSearchInput.bind(this)
      this._onSearchChange = this.onSearchChange.bind(this)
      this.searchTarget.addEventListener("input", this._onSearchInput)
      this.searchTarget.addEventListener("change", this._onSearchChange)
    }
  }

  disconnect() {
    if (this._onSearchInput)  this.searchTarget.removeEventListener("input", this._onSearchInput)
    if (this._onSearchChange) this.searchTarget.removeEventListener("change", this._onSearchChange)
  }

  async add(event) {
    event.preventDefault()
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      involvement: {
        participant_id: this.participantIdTarget.value,
        involvable_type: this.formTarget.dataset.involvableType,
        involvable_id:   this.formTarget.dataset.involvableId,
        role: this.roleTarget.value,
        year: this.yearTarget.value,
        note: this.noteTarget.value
      }
    }

    const res = await fetch("/involvements.json", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: JSON.stringify(body)
    })

    if (res.ok) {
      const inv = await res.json()
      this.appendRow(inv)
      this.formTarget.reset()
      if (this.hasParticipantIdTarget) this.participantIdTarget.value = ""
      if (this.hasSuggestTarget)      this.suggestTarget.innerHTML = ""
    } else {
      const err = await res.json().catch(() => ({}))
      alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
    }
  }

  async remove(event) {
    event.preventDefault()
    const id = event.params.id
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(`/involvements/${id}.json`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" }
    })
    if (res.status === 204) {
      this.element.querySelector(`[data-involvement-row="${id}"]`)?.remove()
    } else {
      alert("Could not remove involvement.")
    }
  }

  appendRow(inv) {
    const li = document.createElement("li")
    li.dataset.involvementRow = inv.id
    li.className = "mb-2"

    const participantLink = inv.participant_path
      ? `<a href="${this.escape(inv.participant_path)}">${this.escape(inv.participant_label)}</a>`
      : `<a href="/${this.escape(inv.participant_type.toLowerCase())}s/${this.escape(inv.participant_id)}">${this.escape(inv.participant_label)}</a>`

    const bits = [participantLink]
    if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
    if (inv.year) bits.push(` (${this.escape(inv.year)})`)
    if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
    bits.push(` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`)
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  async onSearchInput(e) {
    const q = e.target.value.trim()
    if (q.length < 2) { this.suggestTarget.innerHTML = ""; return }
    const res = await fetch(`/soldiers/search.json?q=${encodeURIComponent(q)}`)
    if (!res.ok) return
    const rows = await res.json()
    this.suggestTarget.innerHTML = rows.map(r =>
      `<option value="${this.escape(r.label)}" data-id="${r.id}"></option>`
    ).join("")
  }

  onSearchChange(e) {
    const val = e.target.value
    const option = Array.from(this.suggestTarget.children).find(o => o.value === val)
    if (option && this.hasParticipantIdTarget) {
      this.participantIdTarget.value = option.getAttribute("data-id") || ""
    }
  }

  escape(s) { return String(s ?? "").replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])) }
}
""")

files["app/views/wars/show.html.erb"] = textwrap.dedent("""\
<h1><%= @war.name %></h1>

<%= render "shared/citations", citable: @war, heading: "War Citations" %>

<h2>Involvements</h2>
<% invs = @involvements || @war.involvements.includes(:participant).order(:year, :id) %>
<% if invs.any? %>
  <ul>
    <% invs.each do |inv| %>
      <% s = inv.participant %>
      <li>
        <% if s %>
          <%= link_to(
                s.respond_to?(:display_name) ? s.display_name :
                  ([s.try(:first_name), s.try(:last_name)].compact.join(" ").presence || "Soldier ##{inv.participant_id}"),
                s
              ) %>
        <% else %>
          Soldier #<%= inv.participant_id %>
        <% end %>

        <%= " — " + content_tag(:strong, inv.role) if inv.role.present? %>
        <%= " (#{inv.year})" if inv.year.present? %>
        <%= " — " + content_tag(:em, inv.note)  if inv.note.present? %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p><em>No involvements recorded.</em></p>
<% end %>

<%= render "shared/involvements_panel", involvable: @war %>
""")

# Write files
for rel, content in files.items():
    full = os.path.join(base, rel)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)

zip_path = "/mnt/data/endicott_session_pack_v5.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for rel in files.keys():
        z.write(os.path.join(base, rel), arcname=rel)

zip_path
