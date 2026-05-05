require "test_helper"

class Provider::TwelveDataTest < ActiveSupport::TestCase
  JsonResponse = Struct.new(:body)
  Request = Struct.new(:params)

  setup do
    @provider = Provider::TwelveData.new("test-key")
    @client = mock

    @provider.stubs(:client).returns(@client)
    @provider.stubs(:sleep)
  end

  test "fetch_exchange_rate rejects a mismatched provider symbol" do
    request = Request.new({})

    @client.expects(:get)
           .with("https://api.twelvedata.com/exchange_rate")
           .yields(request)
           .returns(json_response({
             symbol: "USD/VND",
             rate: "25500.10"
           }))

    response = @provider.fetch_exchange_rate(
      from: "EUR",
      to: "VND",
      date: Date.parse("2026-03-01")
    )

    assert_not response.success?
    assert_kind_of Provider::TwelveData::Error, response.error
    assert_match "Expected EUR/VND but provider returned USD/VND", response.error.message
    assert_equal "EUR/VND", request.params["symbol"]
  end

  test "fetch_exchange_rates falls back to cross rates when direct symbol is unavailable" do
    direct_request = Request.new({})
    cross_request = Request.new({})

    @client.expects(:get)
           .with("https://api.twelvedata.com/time_series")
           .yields(direct_request)
           .returns(json_response({
             code: 404,
             message: "Symbol not found"
           }))

    @client.expects(:get)
           .with("https://api.twelvedata.com/time_series/cross")
           .yields(cross_request)
           .returns(json_response({
             meta: {
               base_instrument: "EUR/USD",
               quote_instrument: "VND/USD"
             },
             values: [
               { datetime: "2026-03-01", close: "28000.10" }
             ]
           }))

    response = @provider.fetch_exchange_rates(
      from: "EUR",
      to: "VND",
      start_date: Date.parse("2026-03-01"),
      end_date: Date.parse("2026-03-02")
    )

    assert response.success?
    assert_equal "EUR/VND", direct_request.params["symbol"]
    assert_equal "EUR", cross_request.params["base"]
    assert_equal "VND", cross_request.params["quote"]
    assert_equal 1, response.data.count
    assert_equal "EUR", response.data.first.from
    assert_equal "VND", response.data.first.to
    assert_equal 28000.10, response.data.first.rate.to_f
  end

  test "fetch_exchange_rates rejects mismatched direct series metadata" do
    request = Request.new({})

    @client.expects(:get)
           .with("https://api.twelvedata.com/time_series")
           .yields(request)
           .returns(json_response({
             meta: {
               symbol: "USD/VND"
             },
             values: [
               { datetime: "2026-03-01", close: "25500.10" }
             ]
           }))

    response = @provider.fetch_exchange_rates(
      from: "EUR",
      to: "VND",
      start_date: Date.parse("2026-03-01"),
      end_date: Date.parse("2026-03-02")
    )

    assert_not response.success?
    assert_kind_of Provider::TwelveData::Error, response.error
    assert_match "Expected EUR/VND but provider returned USD/VND", response.error.message
    assert_equal "EUR/VND", request.params["symbol"]
  end

  test "fetch_exchange_rates rejects mismatched cross series metadata" do
    direct_request = Request.new({})
    cross_request = Request.new({})

    @client.expects(:get)
           .with("https://api.twelvedata.com/time_series")
           .yields(direct_request)
           .returns(json_response({
             code: 404,
             message: "Symbol not found"
           }))

    @client.expects(:get)
           .with("https://api.twelvedata.com/time_series/cross")
           .yields(cross_request)
           .returns(json_response({
             meta: {
               base_instrument: "USD/JPY",
               quote_instrument: "VND/USD"
             },
             values: [
               { datetime: "2026-03-01", close: "25500.10" }
             ]
           }))

    response = @provider.fetch_exchange_rates(
      from: "EUR",
      to: "VND",
      start_date: Date.parse("2026-03-01"),
      end_date: Date.parse("2026-03-02")
    )

    assert_not response.success?
    assert_kind_of Provider::TwelveData::Error, response.error
    assert_match "Expected EUR/VND but provider returned cross metadata USD/JPY -> VND/USD", response.error.message
    assert_equal "EUR/VND", direct_request.params["symbol"]
    assert_equal "EUR", cross_request.params["base"]
    assert_equal "VND", cross_request.params["quote"]
  end

  private
    def json_response(payload)
      JsonResponse.new(payload.to_json)
    end
end
