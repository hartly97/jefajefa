# lib/tasks/books_attach.rake
# run bin/rails books:attach_by_key_csv CSV=books_blob_keys.csv

require "csv"

namespace :books do
  desc "Attach existing S3 blobs (by key) to Books.image without re-upload"
  task attach_by_key_csv: :environment do
    path = ENV["CSV"] || "books_blob_keys.csv"
    count_ok = count_skip = count_err = 0

    CSV.foreach(path, headers: true) do |row|
      book_id = row["new_book_id"].to_i
      key     = row["blob_key"].to_s.strip
      next if key.blank? || book_id.zero?

      book = Book.find_by(id: book_id)
      unless book
        warn "Skip: book #{book_id} not found"
        count_skip += 1 and next
      end

      blob = ActiveStorage::Blob.find_by(key: key)
      unless blob
        warn "Skip: blob key #{key} not found"
        count_skip += 1 and next
      end

      if book.image.attached?
        puts "Skip: book #{book.id} already has image"
        count_skip += 1 and next
      end

      ActiveStorage::Attachment.create!(name: "image", record: book, blob: blob)
      puts "OK: attached key=#{key} -> book #{book.id}"
      count_ok += 1
    rescue => e
      warn "ERR: book #{book_id}, key #{key} -> #{e.class}: #{e.message}"
      count_err += 1
    end

    puts "Done. ok=#{count_ok} skip=#{count_skip} err=#{count_err}"
  end
end
