class CategoriesController < ApplicationController
  def index
    @records = Category.order(:name).page(params[:page])
  end
  def show
    @record = Category.find_by!(slug: params[:id])
  end
  def new
    @record = Category.new
  end
  def create
    @record = Category.new(category_params)
    if @record.save
      redirect_to @record, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    @record = Category.find_by!(slug: params[:id])
  end
  def update
    @record = Category.find_by!(slug: params[:id])
    if @record.update(category_params)
      redirect_to @record, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @record = Category.find_by!(slug: params[:id])
    @record.destroy
    redirect_to categories_path, notice: "Category deleted."
  end
  private
  def category_params
    params.require(:category).permit(:name, :category_type, :description)
  end
end
