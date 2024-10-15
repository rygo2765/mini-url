require "nokogiri"
require "open-uri"

class Url < ApplicationRecord
  # Unique ID Length determines the number of characters in the Short URL path
  UNIQUE_ID_LENGTH = 8

  before_validation :sanitize_target_url

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

  # Method to sanitize target_url before validation
  def sanitize_target_url
    return if target_url.blank?

    begin
      # Remove leading or trailing whitespaces from URL
      stripped_url = target_url.strip

      # Parse URL to ensure its a valid URI object
      uri = URI.parse(stripped_url)

      # Check if URL has a http or https scheme; if not, add "http://" by default
      unless uri.scheme
        uri = URI.parse("http://#{stripped_url}")
      end

      # Check if URI object is a valid HTTP/ HTTPS and if the hostname is valid
      if (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && uri.host.include?(".")
        # Reconstruct URL as a string
        self.target_url = uri.to_s
      else
        # set to nil so validation fails
        self.target_url = nil
      end
    rescue URI::InvalidURIError
      # IF parsing fails, set target_url to nil so validation will fail
      self.target_url = nil
    end
  end
end
