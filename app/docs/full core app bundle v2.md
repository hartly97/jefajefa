today = datetime.date.today().isoformat()

# --- Build a fresh, explicit CORE bundle ---
core_path = "/mnt/data/FULL_CORE_APP_BUNDLE_v2.zip"
files = {}

# Concerns
files["app/models/concerns/sluggable.rb"] = textwrap.dedent("""\
  require "securerandom"

  module Sluggable
    extend ActiveSupport::Concern

    included do
      before_validation :generate_slug, if: :needs_slug?
      validates :slug, presence: true, uniqueness: true
    end

    def to_param = slug

    def regenerate_slug!
      base = slug_source.to_s.parameterize if respond_to?(:slug_source)
      base = base.presence || SecureRandom.hex(4)

      candidate = base
      i = 1
      while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
        i += 1
        candidate = "#{base}-#{i}"
      end
      update(slug: candidate)
    end

    private

    def needs_slug?
      slug.blank? && respond_to?(:slug_source)
    end

    def generate_slug
      base = slug_source.to_s.parameterize if respond_to?(:slug_source)
      base = base.presence || SecureRandom.hex(4)

      candidate = base
      i = 1
      while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
        i += 1
        candidate = "#{base}-#{i}"
      end
      self.slug = candidate
    end
  end
""")

files["app/models/concerns/citable.rb"] = textwrap.dedent("""\
  module Citable
    extend ActiveSupport::Concern

    included do
      has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
      has_many :sources, through: :citations
      accepts_nested_attributes_for :citations, allow_destroy: true
    end
  end
""")

files["app/models/concerns/categorizable.rb"] = textwrap.dedent("""\
  module Categorizable
    extend ActiveSupport::Concern

    included do
      has_many :categorizations, as: :categorizable, dependent: :destroy
      has_many :categories, through: :categorizations
    end
  end
""")

files["app/models/concerns/relatable.rb"] = textwrap.dedent("""\
  module Relatable
    extend ActiveSupport::Concern

    included do
      has_many :outgoing_relations, class_name: "Relation", as: :from, dependent: :destroy
      has_many :incoming_relations, class_name: "Relation", as: :to, dependent: :destroy
    end

    def related_records
      (outgoing_relations.includes(:to).map(&:to) + incoming_relations.includes(:from).map(&:from)).uniq
    end

    def relate_to!(other, type: "related")
      Relation.create!(from: self, to: other, relation_type: type)
    end
  end
""")

# Models (explicit)
files["app/models/article.rb"] = textwrap.dedent("""\
  class Article < ApplicationRecord
    include Sluggable
    include Citable
    include Categorizable
    include Relatable

    validates :title, presence: true
    def slug_source = title
  end
""")

files["app/models/source.rb"] = textwrap.dedent("""\
  class Source < ApplicationRecord
    include Sluggable
    include Categorizable
    include Relatable

    has_many :citations, dependent: :restrict_with_error, inverse_of: :source
    has_many :cited_articles, through: :citations, source: :citable, source_type: "Article"
    has_many :cited_soldiers, through: :citations, source: :citable, source_type: "Soldier"

    validates :title, presence: true
    def slug_source = title
  end
""")

files["app/models/citation.rb"] = textwrap.dedent("""\
  class Citation < ApplicationRecord
    belongs_to :source, inverse_of: :citations
    belongs_to :citable, polymorphic: true
    validates :source, presence: true
  end
""")

files["app/models/category.rb"] = textwrap.dedent("""\
  class Category < ApplicationRecord
    include Sluggable
    has_many :categorizations, dependent: :destroy
    validates :name, presence: true
    def slug_source = name
  end
""")

files["app/models/categorization.rb"] = textwrap.dedent("""\
  class Categorization < ApplicationRecord
    belongs_to :category
    belongs_to :categorizable, polymorphic: true
    validates :category_id, uniqueness: { scope: [:categorizable_type, :categorizable_id] }
  end
""")

files["app/models/relation.rb"] = textwrap.dedent("""\
  class Relation < ApplicationRecord
    belongs_to :from, polymorphic: true
    belongs_to :to, polymorphic: true
    validates :relation_type, presence: true
    validates :from_type, uniqueness: { scope: [:from_id, :to_type, :to_id, :relation_type], message: "relationship already exists" }
  end
""")

files["app/models/soldier.rb"] = textwrap.dedent("""\
  class Soldier < ApplicationRecord
    include Sluggable
    include Citable
    include Categorizable
    include Relatable

    belongs_to :cemetery, optional: true

    def slug_source
      [first_name, middle_name, last_name].compact.join(" ").presence || "soldier"
    end
  end
""")

# Controllers (explicit minimal + index/show/new/edit/create/update/destroy stubs if needed)
files["app/controllers/concerns/admin_guard.rb"] = textwrap.dedent("""\
  module AdminGuard
    extend ActiveSupport::Concern
    private
    def require_admin!
      unless current_user&.admin?
        redirect_back fallback_location: root_path, alert: "Admins only."
      end
    end
  end
""")

files["app/controllers/articles_controller.rb"] = textwrap.dedent("""\
  class ArticlesController < ApplicationController
    include AdminGuard
    before_action :set_article, only: [:show, :edit, :update, :destroy, :regenerate_slug]

    def index
      @articles = Article.order(:title)
    end

    def show; end

    def new
      @record = Article.new
      @record.citations.build
    end

    def edit
      @record.citations.build if @record.citations.empty?
    end

    def create
      @record = Article.new(article_params)
      if @record.save
        redirect_to @record, notice: "Article created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @record.update(article_params)
        redirect_to @record, notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy
      redirect_to articles_path, notice: "Article deleted."
    end

    def regenerate_slug
      require_admin!
      if @record.regenerate_slug!
        redirect_to @record, notice: "Slug regenerated."
      else
        redirect_to @record, alert: "Couldn’t regenerate slug."
      end
    end

    private

    def set_article
      @record = Article.find_by(slug: params[:id]) || Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :body,
        { category_ids: [] },
        citations_attributes: [
          :id, :source_id, :pages, :quote, :note, :_destroy,
          { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
        ]
      )
    end
  end
""")

files["app/controllers/sources_controller.rb"] = textwrap.dedent("""\
  class SourcesController < ApplicationController
    include AdminGuard
    before_action :set_source, only: [:show, :edit, :update, :destroy, :regenerate_slug]

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
      require_admin!
      if @source.regenerate_slug!
        redirect_to @source, notice: "Slug regenerated."
      else
        redirect_to @source, alert: "Couldn’t regenerate slug."
      end
    end

    private

    def set_source
      @source = Source.find_by(slug: params[:id]) || Source.find(params[:id])
    end

    def source_params
      base = [:title, :author, :publisher, :year, :url, :details, :repository, :link_url]
      base << { category_ids: [] } if respond_to?(:current_user) && current_user&.admin?
      params.require(:source).permit(*base)
    end
  end
""")

files["app/controllers/soldiers_controller.rb"] = textwrap.dedent("""\
  class SoldiersController < ApplicationController
    include AdminGuard
    before_action :set_soldier, only: [:show, :edit, :update, :destroy, :regenerate_slug]

    def index
      @soldiers = Soldier.order(:last_name, :first_name)
    end

    def show; end

    def new
      @soldier = Soldier.new
      @soldier.citations.build
    end

    def edit
      @soldier.citations.build if @soldier.citations.empty?
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
      require_admin!
      if @soldier.regenerate_slug!
        redirect_to @soldier, notice: "Slug regenerated."
      else
        redirect_to @soldier, alert: "Couldn’t regenerate slug."
      end
    end

    private

    def set_soldier
      @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
    end

    def soldier_params
      params.require(:soldier).permit(
        :first_name, :middle_name, :last_name,
        :birthcity, :birthstate, :birthcountry,
        :deathcity, :deathstate, :deathcountry,
        :cemetery_id,
        { category_ids: [] },
        citations_attributes: [
          :id, :source_id, :pages, :quote, :note, :_destroy,
          { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
        ]
      )
    end
  end
""")

# Views (minimal working)
files["app/views/articles/new.html.erb"] = "<%= render 'form', record: @record %>\n"
files["app/views/articles/edit.html.erb"] = "<%= render 'form', record: @record %>\n"
files["app/views/articles/_form.html.erb"] = textwrap.dedent("""\
  <h1><%= @record.new_record? ? "New Article" : "Edit Article" %></h1>
  <%= form_with(model: @record, data: { turbo: false }) do |f| %>
    <div class="field"><%= f.label :title %><%= f.text_field :title %></div>
    <div class="field"><%= f.label :body %><%= f.text_area :body %></div>

    <% if defined?(current_user) && current_user&.admin? %>
      <div class="field">
        <%= f.label :category_ids, "Categories" %>
        <%= f.collection_select :category_ids, Category.order(:name), :id, :name, {}, multiple: true %>
      </div>
    <% end %>

    <h3>Citations</h3>
    <%= f.fields_for :citations do |cf| %>
      <%= render "citations/fields", f: cf, sources: Source.order(:title) %>
    <% end %>

    <div class="actions"><%= f.submit %></div>
  <% end %>
""")

files["app/views/articles/show.html.erb"] = textwrap.dedent("""\
  <h1><%= @record.title %></h1>
  <div><%= simple_format(@record.body) %></div>

  <% if @record.sources.exists? %>
    <h3>Sources cited</h3>
    <ul>
      <% @record.sources.distinct.each do |s| %>
        <li><%= link_to s.title, s %></li>
      <% end %>
    </ul>
  <% end %>

  <% if defined?(current_user) && current_user&.admin? %>
    <%= button_to "Regenerate slug", regenerate_slug_article_path(@record), method: :patch, form: { data: { turbo: false } } %>
  <% end %>
""")

files["app/views/sources/new.html.erb"] = "<%= render 'form', source: @source %>\n"
files["app/views/sources/edit.html.erb"] = "<%= render 'form', source: @source %>\n"
files["app/views/sources/_form.html.erb"] = textwrap.dedent("""\
  <h1><%= @source.new_record? ? "New Source" : "Edit Source" %></h1>
  <%= form_with(model: @source, data: { turbo: false }) do |f| %>
    <div class="field"><%= f.label :title %><%= f.text_field :title %></div>
    <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 1rem;">
      <div class="field"><%= f.label :author %><%= f.text_field :author %></div>
      <div class="field"><%= f.label :publisher %><%= f.text_field :publisher %></div>
      <div class="field"><%= f.label :year %><%= f.text_field :year %></div>
      <div class="field"><%= f.label :url %><%= f.url_field :url %></div>
    </div>
    <div class="field"><%= f.label :details %><%= f.text_area :details, rows: 3 %></div>
    <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 1rem;">
      <div class="field"><%= f.label :repository %><%= f.text_field :repository %></div>
      <div class="field"><%= f.label :link_url, "Link URL (legacy)" %><%= f.url_field :link_url %></div>
    </div>

    <% if defined?(current_user) && current_user&.admin? %>
      <div class="field">
        <%= f.label :category_ids, "Categories" %>
        <%= f.collection_select :category_ids, Category.order(:name), :id, :name, {}, multiple: true %>
      </div>
    <% end %>

    <div class="actions"><%= f.submit %></div>
  <% end %>
""")

files["app/views/sources/show.html.erb"] = textwrap.dedent("""\
  <h1><%= @source.title %></h1>
  <p><strong>Author:</strong> <%= @source.author.presence || "-" %></p>
  <p><strong>Publisher:</strong> <%= @source.publisher.presence || "-" %></p>
  <p><strong>Year:</strong> <%= @source.year.presence || "-" %></p>
  <p><strong>URL:</strong> <%= @source.url.presence && link_to(@source.url, @source.url) %></p>
  <p><%= simple_format(@source.details) %></p>

  <% if @source.cited_articles.exists? %>
    <h3>Cited articles</h3>
    <ul>
      <% @source.cited_articles.distinct.each do |a| %>
        <li><%= link_to a.title, a %></li>
      <% end %>
    </ul>
  <% end %>

  <% if defined?(current_user) && current_user&.admin? %>
    <%= button_to "Regenerate slug", regenerate_slug_source_path(@source), method: :patch, form: { data: { turbo: false } } %>
  <% end %>
""")

files["app/views/soldiers/new.html.erb"] = "<%= render 'form', soldier: @soldier %>\n"
files["app/views/soldiers/edit.html.erb"] = "<%= render 'form', soldier: @soldier %>\n"
files["app/views/soldiers/_form.html.erb"] = textwrap.dedent("""\
  <h1><%= @soldier.new_record? ? "New Soldier" : "Edit Soldier" %></h1>
  <%= form_with(model: @soldier, data: { turbo: false }) do |f| %>
    <div class="grid" style="grid-template-columns: repeat(3, 1fr); gap: 1rem;">
      <div class="field"><%= f.label :first_name %><%= f.text_field :first_name %></div>
      <div class="field"><%= f.label :middle_name %><%= f.text_field :middle_name %></div>
      <div class="field"><%= f.label :last_name %><%= f.text_field :last_name %></div>
    </div>

    <div class="grid" style="grid-template-columns: repeat(3, 1fr); gap: 1rem;">
      <div class="field"><%= f.label :birthcity %><%= f.text_field :birthcity %></div>
      <div class="field"><%= f.label :birthstate %><%= f.text_field :birthstate %></div>
      <div class="field"><%= f.label :birthcountry %><%= f.text_field :birthcountry %></div>
    </div>

    <div class="grid" style="grid-template-columns: repeat(3, 1fr); gap: 1rem;">
      <div class="field"><%= f.label :deathcity %><%= f.text_field :deathcity %></div>
      <div class="field"><%= f.label :deathstate %><%= f.text_field :deathstate %></div>
      <div class="field"><%= f.label :deathcountry %><%= f.text_field :deathcountry %></div>
    </div>

    <div class="field">
      <%= f.label :cemetery_id, "Cemetery" %>
      <%= f.collection_select :cemetery_id, Cemetery.order(:name), :id, :name, include_blank: true %>
    </div>

    <% if defined?(current_user) && current_user&.admin? %>
      <div class="field">
        <%= f.label :category_ids, "Categories" %>
        <%= f.collection_select :category_ids, Category.order(:name), :id, :name, {}, multiple: true %>
      </div>
    <% end %>

    <h3>Citations</h3>
    <%= f.fields_for :citations do |cf| %>
      <%= render "citations/fields", f: cf, sources: Source.order(:title) %>
    <% end %>

    <div class="actions"><%= f.submit %></div>
  <% end %>
""")

files["app/views/soldiers/show.html.erb"] = textwrap.dedent("""\
  <h1><%= [@soldier.first_name, @soldier.middle_name, @soldier.last_name].compact.join(" ") %></h1>

  <% if @soldier.cemetery %>
    <p><strong>Cemetery:</strong> <%= link_to @soldier.cemetery.name, @soldier.cemetery %></p>
  <% end %>

  <% if @soldier.sources.exists? %>
    <h3>Sources cited</h3>
    <ul>
      <% @soldier.sources.distinct.each do |s| %>
        <li><%= link_to s.title, s %></li>
      <% end %>
    </ul>
  <% end %>

  <% if defined?(current_user) && current_user&.admin? %>
    <%= button_to "Regenerate slug", regenerate_slug_soldier_path(@soldier), method: :patch, form: { data: { turbo: false } } %>
  <% end %>
""")

files["app/views/citations/_fields.html.erb"] = textwrap.dedent("""\
  <div class="border p-3 mb-3 rounded">
    <div class="field">
      <%= f.label :source_id, "Existing Source" %>
      <%= f.collection_select :source_id, sources, :id, :title, include_blank: "— Select a source —" %>
    </div>

    <details class="mt-2">
      <summary>Create a new source (optional)</summary>
      <div class="grid mt-2">
        <%= f.fields_for :source do |sf| %>
          <div class="field"><%= sf.label :title, "Source title" %><%= sf.text_field :title %></div>
          <div class="grid" style="grid-template-columns: repeat(2, 1fr); gap: 1rem;">
            <div class="field"><%= sf.label :author %><%= sf.text_field :author %></div>
            <div class="field"><%= sf.label :publisher %><%= sf.text_field :publisher %></div>
            <div class="field"><%= sf.label :year %><%= sf.text_field :year, placeholder: "e.g., 1917" %></div>
            <div class="field"><%= sf.label :url %><%= sf.url_field :url, placeholder: "https://…" %></div>
          </div>
          <div class="field"><%= sf.label :details %><%= sf.text_area :details, rows: 3 %></div>
          <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 1rem;">
            <div class="field"><%= sf.label :repository %><%= sf.text_field :repository %></div>
            <div class="field"><%= sf.label :link_url, "Link URL (legacy)" %><%= sf.url_field :link_url %></div>
          </div>
        <% end %>
      </div>
    </details>

    <div class="grid mt-3" style="grid-template-columns: 1fr 1fr; gap: 1rem;">
      <div class="field"><%= f.label :pages %><%= f.text_field :pages, placeholder: "e.g., 12–13" %></div>
      <div class="field"><%= f.label :quote %><%= f.text_area :quote, rows: 2 %></div>
    </div>
    <div class="field"><%= f.label :note %><%= f.text_area :note, rows: 2 %></div>

    <div class="mt-2"><label><%= f.check_box :_destroy %> Remove this citation</label></div>
  </div>
""")

# Routes sample + Notes
files["config/ROUTES_SAMPLE.rb"] = textwrap.dedent("""\
  Rails.application.routes.draw do
    root "articles#index"
    resources :articles do
      patch :regenerate_slug, on: :member
    end
    resources :sources do
      patch :regenerate_slug, on: :member
    end
    resources :soldiers do
      patch :regenerate_slug, on: :member
    end
  end
""")

files["INSTALL_NOTES.md"] = f"# Install Notes — Core Bundle (v2)\nGenerated: {today}\n\n1) Unzip into your Rails app root.\n2) Merge `config/ROUTES_SAMPLE.rb` into `config/routes.rb`.\n3) Restart server and visit /articles/new, /sources/new, /soldiers/new.\n"

with zipfile.ZipFile(core_path, "w", zipfile.ZIP_DEFLATED) as z:
    for rel, content in files.items():
        z.writestr(rel, content)

core_path
Result
'/mnt/data/FULL_CORE_APP_BUNDLE_v2.zip'