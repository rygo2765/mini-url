class Visit < ApplicationRecord
  belongs_to :url

  attr_accessor :ip_address

  before_create :geocode_ip_address

  private
  def geocode_ip_address
    return unless ip_address.present?

    begin
      location_data = Geocoder.search(ip_address).first
      self.city = location_data.city || "Unknown"
      self.region = location_data.region || "Unknown"
      self.country = location_data.country || "Unknown"
    rescue => e
      Rails.logger.error "Geocoding error for IP #{ip_address}: #{e.message}"
      self.city = "Unknown"
      self.region = "Unknown"
      self.country = "Unknown"
    end
  end
end
