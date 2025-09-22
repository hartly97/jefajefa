# lib/tasks/census_import.rake
require "csv"


# Normalize staging - live tables
# lib/tasks/census_import.rake (append)
namespace :census do
  desc "Normalize census_imports into censuses + census_entries"
  task normalize: :environment do
    say = ->(m){ puts "[census] #{m}" }

    extract_year = ->(residencedate, booknumber) {
      residencedate.to_s[/\d{4}/]&.to_i || booknumber.to_s[/\d{4}/]&.to_i
    }

    split_piece_folio = ->(pf) {
      s = pf.to_s
      piece = s[/\d+/]
      folio = s[/[Ff]ol(?:io|\.)?\s*([\w\-]+)/, 1] || s.split(/[^\dA-Za-z]/).last
      [piece, folio]
    }

    find_or_make_census = lambda do |r|
      country = r.residenceplacecountry.presence || r.birthcountry.presence || "England"
      year    = extract_year.call(r.residencedate, r.booknumber) || 0
      piece, folio = split_piece_folio.call(r.piecefolio)
      district  = r.residenceplacetext.presence || r.location
      subdist   = r.residenceplacecounty
      place     = r.location

      slug_bits = [country, year, district, subdist, piece, folio, r.page].compact.map(&:to_s)
      slug = slug_bits.join("-").parameterize

      Census.where(
        country: country,
        year: year,
        district: district,
        subdistrict: subdist,
        place: place,
        piece: piece,
        folio: folio,
        page: r.page,
        booknumber: r.booknumber
      ).first_or_create!(slug:)
    end

    batch = 0
    CensusImport.find_in_batches(batch_size: 2000) do |rows|
      batch += 1
      say.call "Batch #{batch} (#{rows.size} rows)"
      ActiveRecord::Base.transaction do
        rows.each do |r|
          cen = find_or_make_census.call(r)
          CensusEntry.create!(
            census: cen,
            householdid: r.householdid,
            linenumber:  r.linenumber,
            household_position: r.linenumber.to_s[/\d+/]&.to_i,
            firstname: r.firstname,
            lastname:  r.lastname,
            sex:       r.sex,
            age:       r.age,
            relationshiptohead:  r.relationshiptohead,
            birthlikedate:       r.birthlikedate,
            birthlikeplacetext:  r.birthlikeplacetext,
            birthcounty:         r.birthcounty,
            birthcountry:        r.birthcountry,
            residencedate:         r.residencedate,
            residenceplacetext:    r.residenceplacetext,
            residenceplacecounty:  r.residenceplacecounty,
            residenceplacecountry: r.residenceplacecountry,
            location:              r.location,
            regnumber: r.regnumber,
            page_ref:  r.page,
            notes: [
              ("Father: #{r.fatherfullname}" if r.fatherfullname.present?),
              ("Mother: #{r.motherfullname}" if r.motherfullname.present?),
              ("Spouse: #{r.spousefullname}" if r.spousefullname.present?)
            ].compact.join(" | ")
          )
        end
      end
    end
    say.call "Done."
  end
end
