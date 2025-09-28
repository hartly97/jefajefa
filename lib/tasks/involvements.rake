namespace :inv do
  desc "Audit & validate Involvement DB checks"
  task check: :environment do
    conn = ActiveRecord::Base.connection
    puts "Violations:"
    puts "  bad participant_type: #{Involvement.where.not(participant_type: 'Soldier').count}"
    puts "  bad involvable_type:  #{Involvement.where.not(involvable_type: %w[Battle War Cemetery Article]).count}"
    puts "  role > 100 chars:     #{Involvement.where.not(role: nil).where('length(role) > 100').count}"
    puts "  bad year:             #{Involvement.where.not('year IS NULL OR (year > 0 AND year < 3000)').count}"
    [:chk_inv_involvable_type, :chk_inv_participant_type, :chk_inv_role_length, :chk_inv_year_range].each do |n|
      print "Validating #{n} ... "
      begin
        conn.validate_check_constraint(:involvements, name: n)
        puts "ok"
      rescue => e
        puts "ERROR: #{e.class}: #{e.message}"
      end
    end
  end
end
