class Url < ApplicationRecord
  # Unique ID Length determines the number of characters in the Short URL path
  UNIQUE_ID_LENGTH = 8

  # Validation to ensure the target URL is in the correct format
  validates :target_url, presence: true, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }

  before_create :generate_short_url

  private

  # Method to generate a short URL
  def generate_short_url
    # Generate a random short code based on Unique Id Length
    short_url_path = SecureRandom.base58(UNIQUE_ID_LENGTH)
    self.short_url = "https://miniurl.com/#{short_url_path}"
  end
end
