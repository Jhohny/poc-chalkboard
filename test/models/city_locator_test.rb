# frozen_string_literal: true

require "test_helper"

class CityLocatorTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers, :remote_ip) do
    def get_header(header_key) = headers[header_key]
  end

  # Branch 1: dev session override
  test "returns dev_override city in development" do
    with_rails_env("development") do
      city = CityLocator.call(FakeRequest.new({}, "127.0.0.1"), dev_override: "Austin")
      assert_equal "Austin", city.name
      assert_equal "austin", city.slug
    end
  end

  # Branch 2: dev localhost fallback
  test "returns San Francisco as default localhost fallback in development" do
    with_rails_env("development") do
      city = CityLocator.call(FakeRequest.new({}, "::1"))
      assert_equal "San Francisco", city.name
    end
  end

  test "returns custom LOCAL_CITY_FALLBACK for loopback in development" do
    with_rails_env("development") do
      with_env("LOCAL_CITY_FALLBACK" => "Denver") do
        city = CityLocator.call(FakeRequest.new({}, "127.0.0.1"))
        assert_equal "Denver", city.name
      end
    end
  end

  # Branch 3: X-App-City header (test env only)
  test "reads city from X-App-City header in test environment" do
    city = CityLocator.call(FakeRequest.new({ "HTTP_X_APP_CITY" => "Chicago" }, "1.2.3.4"))
    assert_equal "Chicago", city.name
    assert_equal "chicago", city.slug
  end

  test "X-App-City header is ignored in production" do
    with_rails_env("production") do
      stub_geocoder(nil) do
        city = CityLocator.call(FakeRequest.new({ "HTTP_X_APP_CITY" => "Chicago" }, "1.2.3.4"))
        assert_nil city  # header ignored; geocoder returns nil; no CF header → nil
      end
    end
  end

  # Branch 4: CF-IPCity header
  test "reads city from CF-IPCity header" do
    city = CityLocator.call(FakeRequest.new({ "HTTP_CF_IPCITY" => "Tokyo" }, "1.2.3.4"))
    assert_equal "Tokyo", city.name
    assert_equal "tokyo", city.slug
  end

  # Branch 5: Geocoder fallback
  test "falls back to geocoder when no header is set" do
    stub_geocoder("Seattle") do
      city = CityLocator.call(FakeRequest.new({}, "1.2.3.4"))
      assert_equal "Seattle", city.name
      assert_equal "seattle", city.slug
    end
  end

  test "returns nil when geocoder finds nothing" do
    stub_geocoder(nil) do
      city = CityLocator.call(FakeRequest.new({}, "1.2.3.4"))
      assert_nil city
    end
  end

  test "returns nil when geocoder raises an exception" do
    with_geocoder_raising(StandardError) do
      city = CityLocator.call(FakeRequest.new({}, "1.2.3.4"))
      assert_nil city
    end
  end

  test "skips geocoder for loopback IP outside development" do
    with_geocoder_raising("must not be called") do
      city = CityLocator.call(FakeRequest.new({}, "127.0.0.1"))
      assert_nil city
    end
  end

  # Priority ordering
  test "CF-IPCity header takes precedence over geocoder" do
    stub_geocoder("Portland") do
      city = CityLocator.call(FakeRequest.new({ "HTTP_CF_IPCITY" => "Miami" }, "1.2.3.4"))
      assert_equal "Miami", city.name
    end
  end

  # City value object
  test "City stream_name is derived from slug" do
    city = CityLocator::City.new(name: "New York", slug: "new-york")
    assert_equal "city_wall:new-york", city.stream_name
  end

  test "slug parameterizes multi-word city name" do
    city = CityLocator.call(FakeRequest.new({ "HTTP_X_APP_CITY" => "Los Angeles" }, "1.2.3.4"))
    assert_equal "los-angeles", city.slug
  end

  test "whitespace-only city name returns nil" do
    # Use loopback IP so geocoder is skipped; the blank header should produce nil.
    city = CityLocator.call(FakeRequest.new({ "HTTP_X_APP_CITY" => "   " }, "127.0.0.1"))
    assert_nil city
  end

  private

  def with_rails_env(environment_name)
    original_env = Rails.env
    Rails.env = ActiveSupport::StringInquirer.new(environment_name)
    yield
  ensure
    Rails.env = original_env
  end

  def with_env(env_vars)
    saved_values = env_vars.keys.to_h { |env_key| [env_key, ENV[env_key]] }
    env_vars.each { |env_key, env_value| ENV[env_key] = env_value }
    yield
  ensure
    saved_values.each { |env_key, original_value| ENV[env_key] = original_value }
  end

  def stub_geocoder(city_name)
    geocoder_result = Struct.new(:city).new(city_name)
    with_geocoder_returning([geocoder_result]) { yield }
  end

  def with_geocoder_returning(search_results)
    original_search = Geocoder.method(:search)
    Geocoder.define_singleton_method(:search) { |*_args| search_results }
    yield
  ensure
    Geocoder.define_singleton_method(:search, original_search)
  end

  def with_geocoder_raising(error)
    original_search = Geocoder.method(:search)
    Geocoder.define_singleton_method(:search) { |*_args| raise error }
    yield
  ensure
    Geocoder.define_singleton_method(:search, original_search)
  end
end
