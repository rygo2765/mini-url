class UrlsController < ApplicationController
  before_action :set_url, only: %i[ edit update destroy ]

  # Lists all URLs belonging to the current user
  def index
    user_uuid = cookies[:user_uuid]
    @urls = Url.where(user_uuid: user_uuid)
  end

  # Displays the details of a shorten URL
  def show
    @url = Url.find_by(short_url: params[:short_url])

    if @url
      @full_short_url = full_short_url(@url.short_url)
      render :show
      return
    end
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
  end

  # Initializes a new URL object for creation
  def new
    @url = Url.new
  end

  # Shows the user's URL and redirects to the visits page of the most recent URL
  def my_urls
    user_uuid = cookies[:user_uuid]

    if user_uuid.present?
      @urls = Url.where(user_uuid: user_uuid).order(created_at: :desc)

      if @urls.present?
        redirect_to show_visits_by_short_url_path(@urls.first.short_url)
      else
        redirect_to error_no_urls_path
      end
    else
      redirect_to error_no_urls_path
    end
  end

  # Redirects to the target URL when accessed via the short URL
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

  # Displays visit details for a specific URL
  def show_visits
    short_url_param = params[:short_url]
    @url = Url.find_by(short_url: short_url_param)

    if @url && @url.user_uuid == cookies[:user_uuid]
      @urls = Url.where(user_uuid: cookies[:user_uuid]).order(created_at: :desc)
      @visits = @url.visits
      @full_short_url = full_short_url(@url.short_url)

      @urls.each do |url|
        url.define_singleton_method(:full_short_url) do
          base = ENV["SHORT_URL_BASE"] || Rails.application.routes.default_url_options[:host]
          "#{base}/#{url.short_url}"
        end
      end
      render "show_visits"
    else
      redirect_to error_no_access_path
    end
  end

  # Creates a new short URL and saves it to the database
  def create
    user_uuid = cookies[:user_uuid] || generate_user_uuid
    @url = Url.new(url_params.merge(user_uuid: user_uuid))
    respond_to do |format|
      if @url.save
        format.html { redirect_to generate_url(@url.short_url), notice: "Url was successfully created." }
        format.json { render json: { target_url: @url.target_url, short_url: full_short_url(@url.short_url), title: @url.title }, status: :created }
      else
        flash.now[:alert] = "Failed to shorten the URL. Please check the URL and try again."
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @url.errors, status: :unprocessable_entity }
      end
    end
  end

   # Updates an existing URL record
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

  # Deletes a URL record from the database
  def destroy
    @url.destroy
    respond_to do |format|
      format.html { redirect_to urls_url, notice: "Url was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Generates a UUID for the user and stores it in a cookie
  def generate_user_uuid
    uuid = SecureRandom.uuid
    cookies[:user_uuid]={
      value: uuid,
      expires: 1.year.from_now,
      httponly: true
    }
  end

  # Finds the URL record based on the provided ID
  def set_url
    @url = Url.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def url_params
    params.require(:url).permit(:target_url, :short_url, :title)
  end

  # Generates the full short URL with base path
  def full_short_url(path)
    base = ENV["SHORT_URL_BASE"] || request.base_url
    "#{base}/#{path}"
  end
end
