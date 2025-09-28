class RecreateAndValidateInvolvementChecks < ActiveRecord::Migration[7.1]
  def up
    # Drop (ignore if already gone)
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_involvable_type"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_participant_type"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_role_length"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_year_range"

    # Re-add NOT VALID (no full-table scan)
    execute "ALTER TABLE public.involvements ADD CONSTRAINT chk_inv_involvable_type CHECK (involvable_type IN ('Battle','War','Cemetery','Article')) NOT VALID"
    execute "ALTER TABLE public.involvements ADD CONSTRAINT chk_inv_participant_type CHECK (participant_type = 'Soldier') NOT VALID"
    execute "ALTER TABLE public.involvements ADD CONSTRAINT chk_inv_role_length CHECK (char_length(coalesce(role,'')) <= 100) NOT VALID"
    execute "ALTER TABLE public.involvements ADD CONSTRAINT chk_inv_year_range CHECK (year IS NULL OR (year > 0 AND year < 3000)) NOT VALID"

    # Now validate (flips convalidated -> true)
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_involvable_type"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_participant_type"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_role_length"
    execute "ALTER TABLE ONLY public.involvements VALIDATE CONSTRAINT chk_inv_year_range"
  end

  def down
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_involvable_type"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_participant_type"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_role_length"
    execute "ALTER TABLE public.involvements DROP CONSTRAINT IF EXISTS chk_inv_year_range"
  end
end


