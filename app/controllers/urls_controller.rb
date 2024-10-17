class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show edit update destroy ]

  # GET /urls or /urls.json
  def index
    @urls = Url.all
  end

  # GET /urls/1 or /urls/1.json
  def show
    @full_short_url = full_short_url(@url.short_url)
  end

  # GET /urls/new
  def new
    @url = Url.new
  end

  # GET /:short_url
  def redirect_to_target
    short_url_param = params[:short_url]
    url = Url.find_by(short_url: short_url_param)

    if url
      url.visits.create(ip_address: request.remote_ip)

      redirect_to url.target_url, allow_other_host: true
    else
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
    end
  end

  def show_visits
    short_url_param = params[:short_url]
    @url = Url.find_by(short_url: short_url_param)

    if @url
      @visits = @url.visits
      @full_short_url = full_short_url(@url.short_url)
      render "show_visits"
    else
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
    end
  end

  # POST /urls or /urls.json
  def create
    @url = Url.new(url_params)

    respond_to do |format|
      if @url.save
        format.html { redirect_to @url, notice: "Url was successfully created." }
        format.json { render json: { target_url: @url.target_url, short_url: full_short_url(@url.short_url), title: @url.title }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @url.errors, status: :unprocessable_entity }
      end
    end
  end

   # PATCH/PUT /urls/1 or /urls/1.json
   def update
    respond_to do |format|
      if @url.update(url_params)
        format.html { redirect_to @url, notice: "Url was successfully updated." }
        format.json { render json: { target_url: @url.target_url, short_url: full_short_url(@url.short_url), title: @url.title }, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @url.errors, status: :unprocessable_entity }
      end
    end
   end

  # DELETE /urls/1 or /urls/1.json
  def destroy
    @url.destroy
    respond_to do |format|
      format.html { redirect_to urls_url, notice: "Url was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_url
      @url = Url.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def url_params
      params.require(:url).permit(:target_url, :short_url, :title)
    end

    def full_short_url(path)
      base = ENV["SHORT_URL_BASE"] || request.base_url
      "#{base}/#{path}"
    end
end
