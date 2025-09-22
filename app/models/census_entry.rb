# app/models/census_entry.rb
class CensusEntry < ApplicationRecord
    self.table_name = "censuses" 
  include Citable
  include Categorizable
  include Slugsgable

  belongs_to :census
  belongs_to :soldier, optional: true

  def display_name
    [firstname, lastname].compact.join(" ")
  end
end

private 
def slug_source = display_name.presence || "entry-#{id || SecureRandom.hex(2)}"

