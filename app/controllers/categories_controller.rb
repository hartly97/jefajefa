class CategoriesController < ApplicationController
  def index
    @category = Category.order(:name).page(params[:page])
  end

  def show
    @category = Category.find_by!(slug: params[:id])
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to @category, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @category = Category.find_by!(slug: params[:id])
  end

  def update
    @category = Category.find_by!(slug: params[:id])
    if @category.update(category_params)
      redirect_to @category, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category = Category.find_by!(slug: params[:id])
    @category.destroy
    redirect_to categories_path, notice: "Category deleted."
  end

  private
  
  def category_params
    params.require(:category).permit(:title, :name, :slug, :category_type, :description)
  end
end
