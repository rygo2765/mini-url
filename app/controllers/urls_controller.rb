class UrlsController < ApplicationController
  before_action :set_url, only: %i[ edit update destroy ]

  def index
    user_uuid = cookies[:user_uuid]
    @urls = Url.where(user_uuid: user_uuid)
  end

  def show
    @url = Url.find_by(short_url: params[:short_url])

    if @url
      @full_short_url = full_short_url(@url.short_url)
      render :show
      return
    end
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
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
      visit = url.visits.new(ip_address: request.remote_ip)

      if visit.save
        redirect_to url.target_url, allow_other_host: true
      else
        Rails.logger.error "Failed to save visit: #{visit.errors.full_messages.join(", ")}"
        redirect_to url.target_url, allow_other_host: true
      end

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
    user_uuid = cookies[:user_uuid] || generate_user_uuid
    @url = Url.new(url_params.merge(user_uuid: user_uuid))

    respond_to do |format|
      if @url.save
        format.html { redirect_to generate_url(@url.short_url), notice: "Url was successfully created." }
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

    def generate_user_uuid
      uuid = SecureRandom.uuid
      cookies[:user_uuid]={
        value: uuid,
        expires: 1.year.from_now,
        httponly: true
      }
    end

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
