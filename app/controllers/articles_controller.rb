# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  include AdminGuard
  before_action :set_article,   only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :set_sources,   only: [:new, :edit]
  before_action :require_admin, only: [:regenerate_slug]

  def index
    @records = Article.order(created_at: :desc)
  end

  def show
    @record.citations.includes(:source).load
  end

  def new
    @record = Article.new
    @record.citations.build
    ensure_nested_source_builds
  end

  def edit
    @record.citations.build if @record.citations.empty?
    ensure_nested_source_builds
  end

  def create
    @record = Article.new(article_params)
    if @record.save
      redirect_to @record, notice: "Article created."
    else
      set_sources
      ensure_nested_source_builds
      render :new, status: :unprocessable_entity
    end
  end

  def update

    if @record.update(article_params)
      redirect_to @record, notice: "Article updated."
    else
      set_sources
      ensure_nested_source_builds
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy
    redirect_to articles_path, notice: "Article deleted."
  end

  def regenerate_slug
    @record.regenerate_slug!
    redirect_to @record, notice: "Slug regenerated."
  end

  private

  # Try slug first, fall back to id
  def set_article
    @record = Article.find_by(slug: params[:id]) || Article.find(params[:id])
  end

  def set_sources
    @sources = Source.common.order(:title)
  end

  # Ensure each citation has a nested source so inline fields render
  def ensure_nested_source_builds
    @record.citations.each { |c| c.build_source if c.source.nil? }
  end

  def article_params
  base = [
    :title, :body, :date, :author,
    citations_attributes: [
      :id, :_destroy, :source_id,
      :quote, :note,
      :page, :folio, :column, :line_number, :record_number,
      :image_url, :image_frame, :roll, :enumeration_district, :locator,
      { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url, :pages] }
    ]
  ]
  base << { category_ids: [] } if current_user&.admin?
  params.require(:article).permit(*base)
en
#   def article_params
#   base = [
#     :title, :body, :date, :author,
#     citations_attributes: [
#       :id, :_destroy, :source_id,
#       :quote, :note,
#       :page, :folio, :column, :line_number, :record_number,
#       :image_url, :image_frame, :roll, :enumeration_district, :locator,
#       { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url, :pages] }
#     ]
#   ]
#   base << { category_ids: [] } if current_user&.admin?
#   params.require(:article).permit(*base)
# end

#     base << { category_ids: [] } if current_user&.admin?
#     params.require(:article).permit(*base)
#   end
# end

  # def article_params
  #   base = [
  #     :title, :body, :date, :author,
  #     citations_attributes: [
  #       :id, :source_id, :pages, :quote, :note, :_destroy,
  #       { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
  #     ]
  #   ]