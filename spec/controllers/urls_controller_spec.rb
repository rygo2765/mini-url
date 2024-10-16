require 'rails_helper'

RSpec.describe UrlsController, type: :controller do
  before do
    stub_request(:get, "https://example.com/").
      to_return(status: 200, body: "<html><head><title>Example Site</title></head><body></body></html>", headers: { 'Content-Type' => 'text/html' })
  end

  let!(:url) { Url.create(target_url: "https://example.com") }

  describe "GET #index" do
    it "assigns @urls" do
      get :index
      expect(assigns(:urls)).to eq([ url ])
    end
  end

  describe "GET #show" do
    before do
      allow(ENV).to receive(:[]).with('SHORT_URL_BASE').and_return('http://localhost:3000')
    end

    it "assigns the requested url as @url and generates the full shortened URL" do
      get :show, params: { id: url.id }
      expect(assigns(:url)).to eq(url)

      full_short_url = assigns(:full_short_url)
      expect(full_short_url).to start_with('http://localhost:3000/')
      expect(full_short_url).to end_with(url.short_url)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Url" do
        expect {
          post :create, params: { url: { target_url: "https://example.com" } }, format: :json
        }.to change(Url, :count).by(1)
      end

      it "renders a JSON response with the new URL" do
        post :create, params: { url: { target_url: "https://example.com" } }, format: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')

        json_response = JSON.parse(response.body)
        expect(json_response["target_url"]).to eq('https://example.com')
        expect(json_response["short_url"]).to be_present
        expect(json_response["title"]).to be_present

        # Verify the short_url format
        expect(json_response["short_url"]).to match(%r{^http://localhost:3000/[a-zA-Z0-9]{8}$})

        # Verify that the created Url in the database matches the response
        created_url = Url.last
        expect(created_url.target_url).to eq('https://example.com')
        expect(created_url.short_url).to eq(json_response["short_url"].split('/').last)
        expect(created_url.title).to eq(json_response["title"])
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new URL" do
        post :create, params: { url: { target_url: "invalid-url" } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include ('application/json')
      end
    end
  end

  describe "GET #redirect_to_target" do
    context "with a valid short URL" do
      let!(:url) { Url.create!(target_url: "https://example.com") }

      it "redirects to the target URL" do
        get :redirect_to_target, params: { short_url: url.short_url }
        expect(response).to redirect_to("https://example.com")
      end

      it "allows redirection to other hosts" do
        get :redirect_to_target, params: { short_url: url.short_url }
        expect(response.headers["Location"]).to eq("https://example.com")
      end
    end

    context "with an invalid short URL" do
      it "renders a 404 page" do
        get :redirect_to_target, params: { short_url: "nonexistent" }
        expect(response).to have_http_status(:not_found)
      end

      it "uses the correct template for 404" do
        get :redirect_to_target, params: { short_url: "nonexistent" }
        expect(response.body).to include("The page you were looking for doesn't exist")
      end
    end
  end
end
