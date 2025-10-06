class Book < ApplicationRecord

 

  has_one_attached :image

  validates :name, presence: true

  validates_uniqueness_of :name

  #validates :description

  #validates :transcription

  scope :sorted, ->{ order(page_number: :asc) }
   # self.implicit_order_column = "name"

   def next
    Book.where("id > ?", id).order(id: :asc).limit(1).first
   end

   def prev
     Book.where("id < ?", id).order(id: :desc).limit(1).first
   end

  #validates :page_number, length: { maximum: 2 }, numericality: { only_integer: true } #, allow_nil: true

  # def self.get_previous_book(current_book)
  #   book.where("books.id < ? ", current_book.id).order('page_number').last
  # end
  #
  # def self.get_next_book(current_book)
  #   book.where("books.id > ? ", current_book.id).order('page_number').first
  # end

  # def get_next_page_position
  #   if books.none? { |book| book.persisted? }
  #     1
  #   else
  #     book.order(position: :asc).last.position + 1
  #   end
  # end

  # validate :acceptable_image
  #
  # def acceptable_image
  # return unless image.attached?

  # unless image.byte_size <= 1.megabyte
  #   errors.add(:image, "is too big")
  # end

  # acceptable_types = ["image/jpeg", "image/png"]
  # unless acceptable_types.include?(image.content_type)
  #   errors.add(:image, "must be a JPEG or PNG")
  # end
end
