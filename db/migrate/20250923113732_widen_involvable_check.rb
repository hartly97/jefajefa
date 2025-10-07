class WidenInvolvableCheck < ActiveRecord::Migration[7.1]
  def change
    # drop the old check (name must match what you used before)
    remove_check_constraint :involvements, name: "chk_inv_involvable_type" rescue nil

    # add the widened check
    add_check_constraint :involvements,
      "involvable_type IN ('Battle','War','Cemetery','Article')",
      name: "chk_inv_involvable_type",
      validate: false
  end
end

 
