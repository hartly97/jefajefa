# app/jobs/census_ingest_image_job.rb
class CensusIngestImageJob < ApplicationJob
  queue_as :default

  def perform(census_id, remote_url)
    census = Census.find(census_id)
    file = URI.parse(remote_url).open # requires: require "open-uri"
    census.image.attach(io: file, filename: File.basename(URI.parse(remote_url).path))
  end
end

# app/jobs/census_ingest_image_job.rb
require "open-uri"
 queue_as :default
 
  retry_on OpenURI::HTTPError, Net::OpenTimeout, Net::ReadTimeout,
           wait: :exponentially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(census_id, remote_url, replace: false)
    census = Census.find(census_id)
    raise ArgumentError, "URL blank" if remote_url.blank?

    uri = URI.parse(remote_url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise ArgumentError, "URL must be http(s)"
    end

    # Skip if something is already attached (unless replace==true)
    if census.image.attached? && !replace
      Rails.logger.info("CensusIngestImageJob: image already attached for ##{census.id}; skipping")
      return
    end

    filename = File.basename(uri.path.presence || "census-#{census.id}")
    ext      = File.extname(filename).presence || ".bin"

    Tempfile.create(["census-#{census.id}-", ext]) do |tmp|
      # Download with timeouts
      URI.open(uri, open_timeout: 10, read_timeout: 25, redirect: true) do |io|
        IO.copy_stream(io, tmp)
      end
      tmp.rewind

      # Sniff content type (Marcel ships with Rails)
      # Read a small chunk to help detection, then rewind.
      sample = tmp.read(2048)
      tmp.rewind
      content_type = Marcel::MimeType.for(StringIO.new(sample), name: filename)

      census.image.purge if replace && census.image.attached?

      census.image.attach(
        io: tmp,
        filename: filename,
        content_type: content_type
      )
    end
  end
end
