class AdjustAwardsForMadelAndOther < ActiveRecord::Migration[7.1]
  def change
     def up
    # 1) Add award_type with default "medal"
    add_column :awards, :award_type, :string, null: false, default: "medal"

    # 2) Allow non-medal awards
    change_column_null :awards, :medal_id, true

    # (Optional) Add simple FKs if you dont have them yet:
    # add_foreign_key :awards, :soldiers unless foreign_key_exists?(:awards, :soldiers)
    # add_foreign_key :awards, :medals   unless foreign_key_exists?(:awards, :medals)
    #
    # Existing rows now read as award_type="medal" and keep their medal_id.
  end

  def down
    # Rollback requires cleaning up any non-medal rows first:
    # execute "DELETE FROM awards WHERE award_type <> 'medal' AND medal_id IS NULL"
    change_column_null :awards, :medal_id, false
    remove_column :awards, :award_type
  end
end
  end

