# lib/tasks/books_report.rake
namespace :books do
  task report: :environment do
    total = Book.count
    with_img = Book.joins(image_attachment: :blob).distinct.count
    puts "Books total=#{total}, with image=#{with_img}, missing=#{total - with_img}"
    missing = Book.left_joins(:image_attachment).where(active_storage_attachments: { id: nil })
    puts "Missing IDs: #{missing.limit(50).pluck(:id).join(", ")}"
  end
end
