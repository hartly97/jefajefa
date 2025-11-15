# lib/tasks/cat_reset.rake
namespace :cat do
  desc "Delete ALL categories and categorizations (FK-safe)"
  task reset!: :environment do
    puts "Deleting #{Categorization.count} categorizations"
    Categorization.delete_all
    puts "Deleting #{Category.count} categories"
    Category.delete_all
    puts "Done."
  end
end
