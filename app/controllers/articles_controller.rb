# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  include PrimeCitations
  before_action :load_sources_for_citations, only: [:new, :edit]
  include AdminGuard
  before_action :set_article,   only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :set_sources,   only: [:new, :edit]
  before_action :require_admin, only: [:regenerate_slug]

  def index
    @articles = Article.order(created_at: :desc)
  end

  def show
  end

  def new
    @article = Article.new
    @article.citations.build
    prime_citations_for(@article)
  end

  def edit
    #  @article = Article.find_by!(slug: params[:id])
    @article.citations.build if @article.citations.empty?
    prime_citations_for(@article)
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to @article, notice: "Article created."
    else
      set_sources
      ensure_nested_source_builds
      render :new, status: :unprocessable_entity
    end
  end

  def update

    if @article.update(article_params)
      redirect_to @article, notice: "Article updated."
    else
      set_sources
      ensure_nested_source_builds
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: "Article deleted."
  end

  def regenerate_slug
    @article.regenerate_slug!
    redirect_to @article, notice: "Slug regenerated."
  end
  
  def load_sources_for_citations = @sources = Source.order(:title)
  end

  
  private
 def prime_citations_for(article)
    record.citations.build if article.citations.empty?
    article.citations.each { |c| c.build_source unless c.source || c.source_id.present? }
  end
  # Try slug first, fall back to id
  def set_article
    @article = Article.find_by(slug: params[:id]) || Article.find(params[:id])
  end

  def set_sources
    @articles = Source.common.order(:title)
  end

  # Ensure each citation has a nested source so inline fields render
  def ensure_nested_source_builds
    @article.citations.each { |c| c.build_source if c.source.nil? }
  end

  def article_params
  base = [
    :title, :body, :postdate, :author,
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
end
