class Visit < ApplicationRecord
  belongs_to :url

  attr_accessor :ip_address

  before_create :geocode_ip_address

  private
  def geocode_ip_address
    return unless ip_address.present?

    location_data = Geocoder.search(ip_address).first
    if location_data
      self.city = location_data.city
      self.country = location_data.country
    end
  end
end
