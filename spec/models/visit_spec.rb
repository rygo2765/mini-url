require 'rails_helper'

RSpec.describe Visit, type: :model do
  let(:url) { Url.create!(short_url: 'abcd1234', target_url: 'https://example.com') }

  before do
    stub_request(:get, "https://example.com/")
      .to_return(status: 200, body: "<html><head><title>Example Site</title></head><body></body></html>", headers: { 'Content-Type' => 'text/html' })
  end

  describe 'geocode_ip_address' do
    context 'when geocoding is successful' do
      it 'sets the city, region and country based on the IP address' do
        allow(Geocoder).to receive(:search).and_return([ OpenStruct.new(city: 'Mountain View', region: 'California', country: 'United States') ])

        visit = url.visits.create!(ip_address: '8.8.8.8')
        expect(visit.city).to eq('Mountain View')
        expect(visit.region).to eq('California')
        expect(visit.country).to eq('United States')
      end
    end

    context 'when no geocoding data is found' do
      it 'sets the city, region and country to "Unknown' do
        allow(Geocoder).to receive(:search).and_return([])
        visit = url.visits.create!(ip_address: '8.8.8.8')
        expect(visit.city).to eq('Unknown')
        expect(visit.region).to eq('Unknown')
        expect(visit.country).to eq('Unknown')
      end
    end

    context 'when an error occurs during geocoding' do
      it 'sets the city, region and country to "Unknown' do
        allow(Geocoder).to receive(:search).and_raise(StandardError, 'Geocoding error')
        visit = url.visits.create!(ip_address: '8.8.8.8')
        expect(visit.city).to eq('Unknown')
        expect(visit.region).to eq('Unknown')
        expect(visit.country).to eq('Unknown')
      end
    end
  end
end
