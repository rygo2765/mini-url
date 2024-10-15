require 'rails_helper'

RSpec.describe Url, type: :model do
  let(:valid_url) { 'https://example.com' }
  let(:invalid_url) { 'invalid-url' }

  # Describe validations
  describe 'validations' do
    context 'with a valid target_url' do
      it 'is valid' do
        url = Url.new(target_url: valid_url)
        expect(url).to be_valid
      end

      it 'is invalid without a target_url' do
        url = Url.new(target_url: '')
        expect(url).to_not be_valid
      end

      it 'is invalid with an improperly formatted URL' do
        url = Url.new(target_url: invalid_url)
        expect(url).to_not be_valid
      end
    end
  end
end
