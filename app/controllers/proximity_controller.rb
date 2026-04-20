# frozen_string_literal: true

# Accepts the visitor's approximate browser geolocation and stores it in session.
class ProximityController < ApplicationController
  def create
    lat, lng = coordinate_params
    if valid_coordinates?(lat, lng)
      store_proximity(latitude: lat, longitude: lng)
      render json: { ok: true }, status: :created
    else
      render json: { ok: false, error: I18n.t('errors.bad_coordinates') },
             status: :unprocessable_entity
    end
  end

  def destroy
    clear_proximity
    head :no_content
  end

  private

  def coordinate_params
    [params[:latitude], params[:longitude]].map { |v| v.present? ? Float(v) : nil }
  rescue ArgumentError, TypeError
    [nil, nil]
  end

  def valid_coordinates?(lat, lng)
    return false if lat.nil? || lng.nil?

    lat.between?(-90, 90) && lng.between?(-180, 180)
  end
end
