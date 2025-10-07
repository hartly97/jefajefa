class ValidateInvolvementChecks < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_involvable_type"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_participant_type"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_role_length"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_year_range"
  end
end

  
