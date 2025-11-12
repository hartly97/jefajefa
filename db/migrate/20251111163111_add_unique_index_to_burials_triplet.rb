# db/migrate/20251111_add_unique_index_to_burials_triplet.rb
class AddUniqueIndexToBurialsTriplet < ActiveRecord::Migration[7.1]
  def change
    add_index :burials, [:cemetery_id, :participant_type, :participant_id],
      unique: true, name: :idx_burials_unique_triplet
  end
end
