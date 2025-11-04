class ApplicationController < ActionController::Base
   helper_method :current_user
   helper :application
  
 private
  def current_user
    return nil unless ActiveModel::Type::Boolean.new.cast(ENV["DEV_ADMIN"])
     # Everyone is treated as an admin for now
    require "ostruct"
    OpenStruct.new(admin?: true)
  end
  def items_per_page
    per = params[:per].presence&.to_i || 24  # default
    per = 1   if per < 1                     # sane lower bound
    per = 100 if per > 100                   # sane upper bound
    per
end
end






