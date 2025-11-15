class NewslettersController < ApplicationController
  before_action :set_newsletter,                      only: [:show, :edit, :update, :destroy, :regenerate_slug]
 

  def index
    @newsletters = Newsletter.order(:title)
  end

  def new
    @newsletter = Newsletter.new
  end

  def edit
    @newsletter = Newsletter.find(params[:id])
  end

  def show
    # @newsletter is already set (and eager-loaded) by set_newsletter.
 
  end

  def create
    @newsletter = Newsletter.new(newsletter_params)
    if @newsletter.save
      redirect_to @newsletter, notice: "Newsletter created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @newsletter.update(war_params)
      redirect_to @newsletter, notice: "War updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @newsletter.destroy
    redirect_to newsletters_path, notice: "newsletter deleted."
  end
private
# Build a nice, stable slug from newsletter fields
  def slug_source
    parts = []
    parts << year
    parts << month
    parts << day if day.present?
    parts << "no-#{number}"   if number.present?
    parts << "v#{version}"    if version.present?
    parts << title            if title.present?

    parts.compact.join(" ").presence || "newsletter-#{id || SecureRandom.hex(2)}"
  end
  
  def display_name
    [title, month, day, year].compact.join(" ").presence || "Newsletter ##{id}"
  end

  def newsletter_params
    params.require(:newsletter).permit(:title, :volume, :slug, :number, :day, :month, :year, :file_name, :image, :content, :pdf),
    { category_ids: [] },
  end
  
def set_newsletter
  @newsletter = Newsletter.find_by(slug: params[:id]) || Newsletter.find(params[:id])
end

def regenerate_slug
  @newsletter.regenerate_slug!  
  # provided by your Sluggable concern
  redirect_to @newsletter, notice: "Slug regenerated."
end
end
