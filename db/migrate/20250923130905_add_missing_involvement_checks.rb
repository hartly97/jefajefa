class AddMissingInvolvementChecks < ActiveRecord::Migration[7.1]
  def up
    # helper to check names even if adapter lacks check_constraint_exists?
    names = ActiveRecord::Base.connection.check_constraints('involvements').map(&:name)

    unless names.include?("chk_inv_participant_type")
      add_check_constraint :involvements,
        "participant_type = 'Soldier'",
        name: "chk_inv_participant_type",
        validate: false
    end

    unless names.include?("chk_inv_year_range")
      add_check_constraint :involvements,
        "year IS NULL OR (year > 0 AND year < 3000)",
        name: "chk_inv_year_range",
        validate: false
    end

    unless names.include?("chk_inv_role_length")
      add_check_constraint :involvements,
        "char_length(coalesce(role,'')) <= 100",
        name: "chk_inv_role_length",
        validate: false
    end

    # NOTE: we deliberately do NOT touch chk_inv_involvable_type here.
  end

  def down
    names = ActiveRecord::Base.connection.check_constraints('involvements').map(&:name)
    remove_check_constraint :involvements, name: "chk_inv_participant_type" if names.include?("chk_inv_participant_type")
    remove_check_constraint :involvements, name: "chk_inv_year_range"        if names.include?("chk_inv_year_range")
    remove_check_constraint :involvements, name: "chk_inv_role_length"       if names.include?("chk_inv_role_length")
  end
end

 
