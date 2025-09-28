# app/controllers/concerns/prime_citations.rb (optional, or put private in controller)
module PrimeCitations
    extend ActiveSupport::Concern
  private
  def prime_citations_for(record)
    record.citations.build if record.citations.empty?
    record.citations.each do |c|
      c.build_source unless c.source || c.source_id.present?
    end
  end
end
