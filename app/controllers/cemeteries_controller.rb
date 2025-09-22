class CemeteriesController < ApplicationController
  include CategoryTextAttachable

  def index
    @cemetery = Cemetery.order(:name).page(params[:page])
  end
  def show
    @cemetery = Cemetery.find_by!(slug: params[:id])
  end
  def new
    @cemetery = Cemetery.new
  end
  def create
    @cemetery = Cemetery.new(cemetery_params)
    if @cemetery.save
     
      redirect_to @cemetery, notice: "Cemetery created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    @cemetery = Cemetery.find_by!(slug: params[:id])
  end

    @cemetery = Cemetery.find_by!(slug: params[:id])
    if @cemetery.update(cemetery_params)
    
      redirect_to @cemetery, notice: "Cemetery updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @cemetery = Cemetery.find_by!(slug: params[:id])
    @cemetery.destroy
    redirect_to cemeteries_path, notice: "Cemetery deleted."
  end

  private
  def cemetery_params
    params.require(:cemetery).permit(:name
    { category_ids: [] }, citations_attributes: [
      :id, :source_id, :_destroy,
      :page, :pages, :folio, :column, :line_number, :record_number, :locator,
      :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
      { 
      source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url]}
      ]
      )
  end

