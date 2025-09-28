
class AddExternalImageToCensuses < ActiveRecord::Migration[6.1]
  def change
    add_column :censuses, :external_image_url, :string
    add_column :censuses, :external_image_caption, :string
    add_column :censuses, :external_image_credit, :string
  end
end

