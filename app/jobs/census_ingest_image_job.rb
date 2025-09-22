# app/jobs/census_ingest_image_job.rb
class CensusIngestImageJob < ApplicationJob
  queue_as :default

  def perform(census_id, remote_url)
    census = Census.find(census_id)
    file = URI.parse(remote_url).open # requires: require "open-uri"
    census.image.attach(io: file, filename: File.basename(URI.parse(remote_url).path))
  end
end
