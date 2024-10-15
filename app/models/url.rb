require "nokogiri"
require "open-uri"

class Url < ApplicationRecord
  # Unique ID Length determines the number of characters in the Short URL path
  UNIQUE_ID_LENGTH = 8

  # Validation to ensure the target URL is in the correct format
  validates :target_url, presence: true, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }

  before_create :generate_short_url, :fetch_title_from_target_url

  private

  # Method to generate a short URL
  def generate_short_url
    loop do
      # Generate a random unique short code based on Unique Id Length
      short_url_path = SecureRandom.base58(UNIQUE_ID_LENGTH)
      self.short_url = "https://miniurl.com/#{short_url_path}"
      if !Url.exists?(short_url: self.short_url)
        break
      end
    end
  end

  # Method to fetch title form the target URL
  def fetch_title_from_target_url
    begin
      doc = Nokogiri::HTML(URI.parse(target_url).open)
      self.title = doc.title if doc
    rescue OpenURI::HTTPError => e
      Rails.logger.error "HTTP error fetching title from URL: #{e.message}"
      self.title = "Unknown Title"
    rescue => e
      Rails.logger.error "Failed to fetch title from URL: #{e.message}"
      self.title = "Unknown Title"
    end
  end
end
