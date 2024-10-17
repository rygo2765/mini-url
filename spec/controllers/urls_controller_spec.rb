require 'rails_helper'

RSpec.describe UrlsController, type: :controller do
  let(:valid_url) { "https://example.com" }
  let(:invalid_url) { "invalid-url" }
  let(:html_content) { "<html><head><title>Example Site</title></head><body></body></html>" }
  let(:short_url_base) { "http://localhost:3000" }

  before do
    stub_request(:get, valid_url).
      to_return(status: 200, body: html_content, headers: { 'Content-Type' => 'text/html' })
  end

  let!(:url) { Url.create(target_url: valid_url) }

  describe "GET #index" do
    it "assigns @urls" do
      get :index
      expect(assigns(:urls)).to eq([ url ])
    end
  end

  describe "GET #show" do
    before do
      allow(ENV).to receive(:[]).with('SHORT_URL_BASE').and_return(short_url_base)
    end

    it "assigns the requested url and generates the full shortened URL" do
      get :show, params: { id: url.id }
      expect(assigns(:url)).to eq(url)
      expect(assigns(:full_short_url)).to eq("#{short_url_base}/#{url.short_url}")
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Url and renders JSON response" do
        expect {
          post :create, params: { url: { target_url: valid_url } }, format: :json
        }.to change(Url, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response["target_url"]).to eq(valid_url)
        expect(json_response["short_url"]).to be_present
        expect(json_response["title"]).to be_present

        created_url = Url.last
        expect(created_url.target_url).to eq(valid_url)
        expect(created_url.short_url).to eq(json_response["short_url"].split('/').last)
        expect(created_url.title).to eq(json_response["title"])
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

  describe "GET #redirect_to_target" do
    context "with a valid short URL" do
      it "redirects to the target URL" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('203.0.113.195')

        allow(Geocoder).to receive(:search).and_return([
          OpenStruct.new(city: 'Sample City', region: 'Sample Region', country: 'Sample Country')
        ])
        expect {
          get :redirect_to_target, params: { short_url: url.short_url }
        }.to change(Visit, :count).by(1)

        expect(response).to redirect_to(valid_url)
        visit = Visit.last
        expect(visit.city).to eq('Sample City')
        expect(visit.region).to eq('Sample Region')
        expect(visit.country).to eq('Sample Country')
        expect(visit.created_at).to be_present
      end
    end

    context "with an invalid short URL" do
      it "renders a 404 page" do
        get :redirect_to_target, params: { short_url: "nonexistent" }
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("The page you were looking for doesn't exist")
      end
    end
  end

  describe "GET #show_visits" do
    context "with a valid short URL" do
      it "assigns the requested url and its visits" do
        visit = url.visits.create(city: "Sample City", region: "Sample Region", country: "Sample Country") # 
        get :show_visits, params: { short_url: url.short_url }

        expect(assigns(:url)).to eq(url)
        expect(assigns(:visits)).to include(visit)
      end
    end

    context "with an invalid short URL" do
      it "renders a 404 page" do
        get :show_visits, params: { short_url: "nonexistent" }
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("The page you were looking for doesn't exist")
      end
    end
  end
end
