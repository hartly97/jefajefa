class CategorizationsController < ApplicationController
  before_action :set_category
  before_action :set_categorizable

  def create
    @categorization = Categorization.find_or_initialize_by(category: @category, categorizable: @categorizable)
    if @categorization.new_record? && @categorization.save
      redirect_back fallback_location: @categorizable, notice: "Category attached."
    else
      redirect_back fallback_location: @categorizable, alert: "Already attached."
    end
  end

  def destroy
    @categorization = Categorization.find_by!(category: @category, categorizable: @categorizable)
    @categorization.destroy
    redirect_back fallback_location: @categorizable, notice: "Category removed."
  end

  private

  def set_category
    @category = Category.find(params[:category_id])
  end

  def set_categorizable
    klass = params[:categorizable_type].to_s.safe_constantize
    raise ActiveRecord::RecordNotFound, "Unknown type" unless klass
    @categorizable = klass.find(params[:categorizable_id])
  end
end
