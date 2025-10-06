class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books do |t|
        t.string "name"
    t.string "page_number"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "transcription"
    t.string "transcriptiontwo"
    t.index ["name"], name: "index_books_on_name"

    end
  end
end
