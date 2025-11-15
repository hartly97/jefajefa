class AddSoldierToBurials < ActiveRecord::Migration[7.1]
  def change
    add_reference :burials, :soldier, foreign_key: true, index: true, null: true
  end
  end
