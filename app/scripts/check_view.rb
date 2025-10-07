# script/check_view.rb
require_relative "../config/environment"
html = ApplicationController.render(partial: "articles/form", locals: { article: Article.new })
puts "OK — rendered #{html.bytesize} bytes"
