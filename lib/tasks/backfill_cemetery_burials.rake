# lib/tasks/backfill_cemetery_burials.rake
namespace :data do
  desc "Backfill Burial records from Cemetery involvements and Soldier.cemetery_id
        Usage:
          rake data:backfill_burials
          DRY_RUN=1 rake data:backfill_burials"
  task backfill_burials: :environment do
    dry = ENV["DRY_RUN"].present?
    created = 0
    updated = 0
    skipped = 0
    errors  = 0

    say = ->(msg) { puts msg }

    def build_attrs_from_participant(p)
      return {} unless p
      {
        first_name:  p.try(:first_name),
        middle_name: p.try(:middle_name),
        last_name:   p.try(:last_name),
        birth_date:  p.try(:birth_date),
        birth_place: [p.try(:birthcity), p.try(:birthstate), p.try(:birthcountry)]
                       .compact.reject(&:blank?).join(", ").presence,
        death_date:  p.try(:death_date),
        death_place: [p.try(:deathcity), p.try(:deathstate), p.try(:deathcountry)]
                       .compact.reject(&:blank?).join(", ").presence
      }
    end

    # 1) From Cemetery involvements -> Burials
    say.call "Phase 1: Converting Cemetery involvements to burials…"
    Involvement.where(involvable_type: "Cemetery").includes(:participant).find_each do |inv|
      cemetery = Cemetery.find_by(id: inv.involvable_id)
      participant = inv.participant
      unless cemetery && participant
        skipped += 1
        next
      end

      b = Burial.where(
        cemetery_id:     cemetery.id,
        participant_type: inv.participant_type,
        participant_id:   inv.participant_id
      ).first_or_initialize

      attrs = build_attrs_from_participant(participant)
      # Keep any existing note, append involvement note/role if present
      note_bits = []
      note_bits << b.note if b.persisted? && b.note.present?
      note_bits << inv.note if inv.note.present?
      note_bits << inv.role if inv.role.present?
      attrs[:note] = note_bits.compact.uniq.join("\n").presence

      if b.new_record?
        if dry
          created += 1
        else
          b.assign_attributes(attrs)
          if b.save
            created += 1
          else
            errors += 1
            say.call "  ! Failed to create burial for #{participant.class}(##{participant.id}) @ cemetery ##{cemetery.id}: #{b.errors.full_messages.join(", ")}"
          end
        end
      else
        # Only fill blanks so we don't stomp existing edits
        changed = {}
        attrs.each { |k,v| changed[k] = v if b.send(k).blank? && v.present? }
        if changed.any?
          if dry
            updated += 1
          else
            if b.update(changed)
              updated += 1
            else
              errors += 1
              say.call "  ! Failed to update burial ##{b.id}: #{b.errors.full_messages.join(", ")}"
            end
          end
        else
          skipped += 1
        end
      end
    end

    # 2) From Soldier.cemetery_id -> Burials
    say.call "Phase 2: Backfilling soldiers with cemetery_id into burials…"
    Soldier.where.not(cemetery_id: nil).find_each do |s|
      cemetery = Cemetery.find_by(id: s.cemetery_id)
      unless cemetery
        skipped += 1
        next
      end

      b = Burial.where(
        cemetery_id:     cemetery.id,
        participant_type: "Soldier",
        participant_id:   s.id
      ).first_or_initialize

      attrs = build_attrs_from_participant(s)

      if b.new_record?
        if dry
          created += 1
        else
          b.assign_attributes(attrs)
          if b.save
            created += 1
          else
            errors += 1
            say.call "  ! Failed to create burial for Soldier ##{s.id} @ cemetery ##{cemetery.id}: #{b.errors.full_messages.join(", ")}"
          end
        end
      else
        changed = {}
        attrs.each { |k,v| changed[k] = v if b.send(k).blank? && v.present? }
        if changed.any?
          if dry
            updated += 1
          else
            if b.update(changed)
              updated += 1
            else
              errors += 1
              say.call "  ! Failed to update burial ##{b.id}: #{b.errors.full_messages.join(", ")}"
            end
          end
        else
          skipped += 1
        end
      end
    end

    say.call "Done. created=#{created}, updated=#{updated}, skipped=#{skipped}, errors=#{errors}#{dry ? ' (dry-run)' : ''}"
  end
end
