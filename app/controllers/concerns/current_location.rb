# frozen_string_literal: true

# Exposes current_city to controllers and views.
#
# City detection is session-cached so geocoder/CF-header lookups only happen
# once per session, keeping Turbo frame requests fast.
#
# In development, visiting /?dev_city=Los+Angeles overrides the city for the
# rest of the browser session. Clear with /?dev_city=clear.
#
module CurrentLocation
  extend ActiveSupport::Concern

  included do
    helper_method :current_city
    before_action :apply_dev_city_override if Rails.env.development?
  end

  def current_city
    @current_city ||= city_from_session || detect_and_cache_city
  end

  private

  # Reads the city stored from a previous request in this session.
  # Skipped in development so overrides and env-var changes take effect immediately.
  def city_from_session
    return if Rails.env.development?
    return if session[:city_slug].blank?

    CityLocator::City.new(
      name: session[:city_name],
      slug: session[:city_slug]
    )
  end

  def detect_and_cache_city
    city = CityLocator.call(request, dev_override: dev_city_override)
    store_city_in_session(city)
    city
  end

  def store_city_in_session(city)
    return unless city
    return if Rails.env.development?

    session[:city_name] = city.name
    session[:city_slug] = city.slug
  end

  # Returns the active dev override value from the session, or nil.
  def dev_city_override
    session[:dev_city_override] if Rails.env.development?
  end

  # In development: ?dev_city=Los+Angeles pins the city for the session.
  #                 ?dev_city=clear removes the override.
  def apply_dev_city_override
    return unless params[:dev_city].present?

    if params[:dev_city] == "clear"
      session.delete(:dev_city_override)
    else
      session[:dev_city_override] = params[:dev_city]
    end
  end
end
