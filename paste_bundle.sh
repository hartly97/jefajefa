#!/usr/bin/env bash
set -euo pipefail

mkdir -p app/models/concerns app/models app/controllers app/views/soldiers app/views/citations app/javascript/controllers

########## app/models/concerns/sluggable.rb
cat > app/models/concerns/sluggable.rb <<'RUBY'
require "securerandom"

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: :needs_slug?
    validates :slug, presence: true, uniqueness: { case_sensitive: false }
  end

  def regenerate_slug!
    self.slug = build_unique_slug
    save!
    slug
  end

  private

  def needs_slug?
    slug.blank? && respond_to?(:slug_source, true)
  end

  def generate_slug
    return unless needs_slug?
    self.slug = build_unique_slug
  end

  def build_unique_slug
    base = (respond_to?(:slug_source, true) ? send(:slug_source) : nil).to_s.parameterize
    base = base.presence || SecureRandom.hex(4)
    candidate = base
    i = 1
    while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end
    candidate
  end
end
RUBY

########## app/models/concerns/citable.rb
cat > app/models/concerns/citable.rb <<'RUBY'
module Citable
  extend ActiveSupport::Concern

  included do
    has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
    has_many :sources,   through: :citations
    accepts_nested_attributes_for :citations, allow_destroy: true
  end
end
RUBY

########## app/models/concerns/categorizable.rb
cat > app/models/concerns/categorizable.rb <<'RUBY'
module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable, dependent: :destroy, inverse_of: :categorizable
    has_many :categories, through: :categorizations
  end

  def categories_of(type) = categories.where(category_type: type.to_s)
  def categories_of_types(*types) = categories.where(category_type: types.flatten.map(&:to_s))

  %w[battle war medal census cemetery article award soldier].each do |t|
    define_method("#{t}_categories") { categories_of(t) }
  end
end
RUBY

########## app/models/soldier.rb
cat > app/models/soldier.rb <<'RUBY'
# app/models/soldier.rb
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable

  belongs_to :cemetery, optional: true

  has_many :awards, dependent: :destroy

  has_many :soldier_medals, dependent: :destroy
  has_many :medals, through: :soldier_medals

  has_many :involvements, as: :participant, dependent: :destroy
  has_many :battles, through: :involvements, source: :involvable, source_type: "Battle"
  has_many :wars,    through: :involvements, source: :involvable, source_type: "War"

  scope :by_last_first, -> { order(:last_name, :first_name) }
  scope :search_name, ->(q) {
    q = q.to_s.strip
    next all if q.blank?
    like = "%#{q.downcase}%"
    where(
      "LOWER(COALESCE(first_name,'')) LIKE :q OR
       LOWER(COALESCE(last_name ,'')) LIKE :q OR
       LOWER(COALESCE(first_name,'') || ' ' || COALESCE(last_name,'')) LIKE :q OR
       LOWER(COALESCE(slug,'')) LIKE :q",
      q: like
    )
  }
end
RUBY

########## app/controllers/soldiers_controller.rb
cat > app/controllers/soldiers_controller.rb <<'RUBY'
class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit]

  def index
    @q = params[:q].to_s.strip
    scope = Soldier.by_last_first
    scope = scope.search_name(@q) if @q.present?

    @total_count = scope.count
    page_size = (params[:per_page].presence || 30).to_i.clamp(1, 200)
    current_page = (params[:page].presence || 1).to_i.clamp(1, 10_000)
    @total_pages = (@total_count.to_f / page_size).ceil
    offset = (current_page - 1) * page_size

    @soldiers = scope.limit(page_size).offset(offset)
    @has_next  = current_page < @total_pages
  end

  def show
  end

  def new
    @soldier = Soldier.new
    build_nested(@soldier)
  end

  def edit
    build_nested(@soldier)
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
    scope = Soldier.by_last_first
    scope = Soldier.search_name(q).by_last_first if q.present? && Soldier.respond_to?(:search_name)
    render json: scope.limit(10).map { |s|
      base = [s.try(:first_name), s.try(:last_name)].compact.join(" ").presence ||
             s.try(:slug) || "Soldier ##{s.id}"
      { id: s.id, label: "#{base} (##{s.id})" }
    }
  end

  private

  def set_soldier
    base = Soldier.includes(:cemetery, :awards, { citations: :source }, :categories, { involvements: :involvable })
    @soldier = base.find_by(slug: params[:id]) || base.find(params[:id])
  end

  def load_sources
    @sources = Source.order(:title)
  end

  def build_nested(s)
    s.awards.build if s.awards.empty?
    s.soldier_medals.build if s.soldier_medals.empty?
    s.citations.build if s.citations.empty?
  end

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birthcity, :birthstate, :birthcountry,
      :death_date, :deathcity, :deathstate, :deathcountry, :deathplace,
      :cemetery_id, :unit, :branch_of_service,
      :first_enlisted_start_date, :first_enlisted_end_date, :first_enlisted_place, :slug,
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
RUBY

########## app/views/soldiers/_pager.html.erb
cat > app/views/soldiers/_pager.html.erb <<'ERB'
<% curr_page  = params.fetch(:page, 1).to_i %>
<% per        = (params[:per_page].presence || 30).to_i %>
<% q          = params[:q].presence %>

<div class="d-flex justify-content-between align-items-center my-3">
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
ERB

########## app/views/citations/_sections.html.erb
cat > app/views/citations/_sections.html.erb <<'ERB'
<%# expects local: f (parent form builder), and optionally :sources %>
<div data-controller="citations"
     data-citations-index-value="<%= f.object.citations.size %>">

  <div data-citations-target="list">
    <% f.fields_for :citations do |cf| %>
      <div data-citations-wrapper>
        <%= render "citations/fields", f: cf, sources: (defined?(sources) ? sources : Source.order(:title)) %>
      </div>
    <% end %>
  </div>

  <template data-citations-target="template">
    <div data-citations-wrapper>
      <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
        <%= render "citations/fields", f: cf, sources: (defined?(sources) ? sources : Source.order(:title)) %>
      <% end %>
    </div>
  </template>

  <p>
    <button type="button" class="btn btn-sm btn-outline-primary" data-action="citations#add">Add citation</button>
  </p>
</div>
ERB

########## app/views/citations/_fields.html.erb
cat > app/views/citations/_fields.html.erb <<'ERB'
<div class="border p-3 mb-3 rounded citation-fields"
     data-controller="source-picker"
     data-citations-wrapper>

  <div class="d-flex justify-content-between align-items-center mb-2">
    <strong>Citation</strong>
    <button type="button" class="btn btn-sm btn-outline-danger" data-action="click->citations#remove">Remove</button>
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
    <button class="btn btn-sm btn-outline-secondary" type="button" data-action="click->source-picker#toggleNewForm">
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
ERB

########## app/javascript/controllers/involvement_form_controller.js
cat > app/javascript/controllers/involvement_form_controller.js <<'JS'
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form","list","participantId","role","year","note","search","suggest"]

  connect() {}

  async add(event) {
    event.preventDefault()
    const token = document.querySelector('meta[name="csrf-token"]').content
    const body = {
      involvement: {
        participant_id: this.participantIdTarget.value,
        involvable_type: this.formTarget.dataset.involvableType,
        involvable_id: this.formTarget.dataset.involvableId,
        role: this.roleTarget.value,
        year: this.yearTarget.value,
        note: this.noteTarget.value
      }
    }
    const res = await fetch("/involvements.json", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "application/json" },
      body: JSON.stringify(body)
    })
    if (res.ok) {
      const inv = await res.json()
      this.appendRow(inv)
      this.formTarget.reset()
      this.participantIdTarget.value = ""
      this.suggestTarget.innerHTML = ""
    } else {
      const err = await res.json().catch(() => ({}))
      alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
    }
  }

  async remove(event) {
    event.preventDefault()
    const id = event.params.id
    const token = document.querySelector('meta[name="csrf-token"]').content
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
    const bits = []
    bits.push(`<a href="/${inv.participant_type.toLowerCase()}s/${inv.participant_id}">${this.escape(inv.participant_label)}</a>`)
    if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
    if (inv.year) bits.push(` (${this.escape(inv.year)})`)
    if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
    bits.push(` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`)
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  escape(s) { return String(s ?? "").replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])) }
}
JS

########## app/controllers/involvements_controller.rb
cat > app/controllers/involvements_controller.rb <<'RUBY'
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
    inv.role = attrs[:role]
    inv.year = attrs[:year]
    inv.note = attrs[:note]

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
    params.require(:involvement).permit(
      :involvable_type, :involvable_id,
      :participant_id,
      :role, :year, :note
    )
  end

  def involvement_json(inv)
    {
      id: inv.id,
      participant_id:   inv.participant_id,
      participant_type: inv.participant_type,
      participant_label: (inv.participant.try(:display_name) ||
        [inv.participant.try(:first_name), inv.participant.try(:last_name)].compact.join(" ") ||
        "Soldier ##{inv.participant_id}"),
      role: inv.role,
      year: inv.year,
      note: inv.note
    }
  end
end
RUBY

echo "✅ Files written. Now run: spring stop 2>/dev/null || true && bin/rails zeitwerk:check && bin/rails s"
