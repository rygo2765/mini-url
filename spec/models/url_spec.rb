require 'rails_helper'

RSpec.describe Url, type: :model do
  let(:valid_url) { 'https://example.com' }
  let(:invalid_url) { 'invalid-url' }

  before do
    stub_request(:get, "https://example.com/")
        .to_return(status: 200, body: "<html><head><title>Example Website</title></ head><body></body></html>")
  end

  # Describe validations
  describe 'validations' do
    context 'with a valid target_url' do
      it 'is valid' do
        url = Url.new(target_url: valid_url)
        expect(url).to be_valid
      end
    end

    context 'without a target_url' do
      it 'is invalid' do
        url = Url.new(target_url: '')
        expect(url).to_not be_valid
      end
    end

    context 'with an improperly formatted URL' do
      it 'is invalid' do
        url = Url.new(target_url: invalid_url)
        expect(url).to_not be_valid
      end
    end
  end

  # Describe short URL generation
  describe '#generate_short_url' do
    let(:url) { Url.create(target_url: valid_url) }

    it 'generates unique short URL paths' do
      generated_urls = []
      100.times do
        url = Url.create(target_url: "https://example.com")
        generated_urls << url.short_url
      end

      expect(generated_urls.uniq.length).to eq(generated_urls.length)
    end

    it 'generates a short URL path not exceeding 15 characters' do
      path = url.short_url.split('/').last
      expect(path.length).to be <= 15
    end

    it 'allows multiple short URLs for the same target URL' do
      url1 = Url.create(target_url: valid_url)
      url2 = Url.create(target_url: valid_url)
      expect(url1.short_url).not_to eq(url2.short_url)
    end
  end

  # Describe title fetching
  describe '#fetch_title_from_target_url' do
    it 'fetches the title from the target URL' do
      url = Url.create(target_url: valid_url)
      expect(url.title).to eq('Example Website')
    end

    it 'sets "Unknown Title" when unable to fetch title' do
      stub_request(:get, "https://example.com").to_return(status: 404)
      url = Url.create(target_url: valid_url)
      expect(url.title).to eq('Unknown Title')
    end
  end

  # Describe sanitize target_url
  describe '#sanitize_target_url' do
    it 'adds http:// to URLs without a scheme' do
      url = Url.new(target_url: 'example.com')
      url.valid?
      expect(url.target_url).to eq('http://example.com')
    end

    it 'keeps https:// URLs unchanged' do
      url = Url.new(target_url: valid_url)
      url.valid?
      expect(url.target_url).to eq('https://example.com')
    end
  end
end
