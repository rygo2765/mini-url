require 'rails_helper'

RSpec.describe UrlsController, type: :controller do
  # Define common test variables
  let(:valid_url) { "https://example.com" }
  let(:invalid_url) { "invalid-url" }
  let(:html_content) { "<html><head><title>Example Site</title></head><body></body></html>" }
  let(:short_url_base) { "http://localhost:3000" }
  let(:user_uuid) { '123e4567-e89b-12d3-a456-426614174000' }

  # Mock external HTTP request
  before do
    stub_request(:get, valid_url).
      to_return(status: 200, body: html_content, headers: { 'Content-Type' => 'text/html' })
  end

  # Create test URLs for different users
  let!(:url) { Url.create(target_url: valid_url, user_uuid: user_uuid) }
  let!(:other_user_url) { Url.create(target_url: valid_url, user_uuid: 'other-uuid') }

  # Test URL display after user generate short url
  describe "GET #show" do
    before do
      allow(ENV).to receive(:[]).with('SHORT_URL_BASE').and_return(short_url_base)
    end

    context "with valid short url" do
      it "assigns the requested url and generates the full shortened URL" do
        get :show, params: { short_url: url.short_url }
        expect(assigns(:url)).to eq(url)
        expect(assigns(:full_short_url)).to eq("#{short_url_base}/#{url.short_url}")
      end
    end

    context "with invalid short url" do
      it "returns 404" do
        get :show, params: { short_url: 'invalid' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Test user's URLs Usage report
  describe "GET #my_urls" do
    before do
      cookies[:user_uuid] = user_uuid
    end

    context "with user_uuid" do
      it "redirects to first url's visits when urls exist" do
        get :my_urls
        expect(response).to redirect_to(show_visits_by_short_url_path(url.short_url))
      end

      it "redirects to error when no urls exist" do
        Url.destroy_all
        get :my_urls
        expect(response).to redirect_to(error_no_urls_path)
      end
    end

    context "without user_uuid" do
      it "redirects to error" do
        cookies.delete(:user_uuid)
        get :my_urls
        expect(response).to redirect_to(error_no_urls_path)
      end
    end
  end

  # Test short URL creation
  describe "POST #create" do
    context "with valid params" do
      it "creates url and sets user cookie" do
        cookies.delete(:user_uuid)
        expect {
          post :create, params: { url: { target_url: valid_url } }, format: :json
        }.to change(Url, :count).by(1)
        expect(cookies[:user_uuid]).to be_present
      end

      it "returns correct JSON response" do
        post :create, params: { url: { target_url: valid_url } }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response["target_url"]).to eq(valid_url)
        expect(json_response["short_url"]).to be_present
        expect(json_response["title"]).to be_present
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors" do
        post :create, params: { url: { target_url: invalid_url } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  # Test short URL redirection and visit tracking
  describe "GET #redirect_to_target" do
    context "with valid short URL" do
      # mock visit
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('203.0.113.195')
        allow(Geocoder).to receive(:search).and_return([
          OpenStruct.new(city: 'Sample City', region: 'Sample Region', country: 'Sample Country')
        ])
      end

      it "creates visit and redirects" do
        expect {
          get :redirect_to_target, params: { short_url: url.short_url }
        }.to change(Visit, :count).by(1)

        expect(response).to redirect_to(valid_url)

        visit = Visit.last
        expect(visit.city).to eq('Sample City')
        expect(visit.region).to eq('Sample Region')
        expect(visit.country).to eq('Sample Country')
      end

      it "handles failed visit save" do
        allow_any_instance_of(Visit).to receive(:save).and_return(false)
        get :redirect_to_target, params: { short_url: url.short_url }
        expect(response).to redirect_to(valid_url)
      end
    end

    context "with an invalid short URL" do
      it "renders a 404 page" do
        get :redirect_to_target, params: { short_url: "nonexistent" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Test visit statistics display
  describe "GET #show_visits" do
    context "with matching user_uuid" do
      before do
        cookies[:user_uuid] = user_uuid
      end

      it "shows visits for url" do
        visit = url.visits.create(city: "Sample City", region: "Sample Region", country: "Sample Country") #
        get :show_visits, params: { short_url: url.short_url }

        expect(assigns(:url)).to eq(url)
        expect(assigns(:visits)).to include(visit)
      end
    end

    context "with non-matching user_uuid" do
      before do
        cookies[:user_uuid] = 'different-uuid'
      end

      it "redirects to error" do
        get :show_visits, params: { short_url: "" }
        expect(response).to redirect_to(error_no_access_path)
      end
    end

    context "with non-existent short URL" do
      before do
        cookies[:user_uuid] = user_uuid
      end

      it "redirects to error" do
        get :show_visits, params: { short_url: 'nonexistent' }
        expect(response).to redirect_to(error_no_access_path)
      end
    end

    context "accessing other user's URL" do
      before do
        cookies[:user_uuid] = user_uuid
      end

      it "redirects to error" do
        get :show_visits, params: { short_url: other_user_url.short_url }
        expect(response).to redirect_to(error_no_access_path)
      end
    end
  end
end
