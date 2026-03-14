class Provider::TwelveData < Provider
  include ExchangeRateConcept, SecurityConcept

  # Subclass so errors caught in this provider are raised as Provider::TwelveData::Error
  Error = Class.new(Provider::Error)
  InvalidExchangeRateError = Class.new(Error)
  InvalidSecurityPriceError = Class.new(Error)

  def initialize(api_key)
    @api_key = api_key
  end

  def healthy?
    with_provider_response do
      response = client.get("#{base_url}/api_usage")
      JSON.parse(response.body).dig("plan_category").present?
    end
  end

  def usage
    with_provider_response do
      response = client.get("#{base_url}/api_usage")

      parsed = JSON.parse(response.body)

      limit = parsed.dig("plan_daily_limit")
      used = parsed.dig("daily_usage")
      remaining = limit - used

      UsageData.new(
        used: used,
        limit: limit,
        utilization: used / limit * 100,
        plan: parsed.dig("plan_category"),
      )
    end
  end

  # ================================
  #          Exchange Rates
  # ================================

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      response = client.get("#{base_url}/exchange_rate") do |req|
        req.params["symbol"] = "#{from}/#{to}"
        req.params["date"] = date.to_s
      end

      parsed = JSON.parse(response.body)
      validate_exchange_rate_symbol!(
        parsed: parsed,
        from: from,
        to: to,
        context: "on #{date}",
        response_body: response.body
      )

      rate = parsed.dig("rate")
      if rate.nil?
        Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} on: #{date}, response: #{response.body}")
        raise InvalidExchangeRateError.new("Could not fetch exchange rate for #{from}/#{to} on #{date}, response: #{response.body}")
      end
      Rate.new(date: date.to_date, from:, to:, rate: rate)
    end
  end

  def fetch_exchange_cross_rates(from:, to:, start_date:, end_date:)
    # Add a random delay to avoid rate limiting
    sleep(rand(60..300))
    response = client.get("#{base_url}/time_series/cross") do |req|
      req.params["base"] = "#{from}"
      req.params["quote"] = "#{to}"
      req.params["start_date"] = start_date.to_s
      req.params["end_date"] = end_date.to_s
      req.params["interval"] = "1day"
    end
    parsed = JSON.parse(response.body)
    validate_exchange_cross_metadata!(
      parsed: parsed,
      from: from,
      to: to,
      start_date: start_date,
      end_date: end_date,
      response_body: response.body
    )

    data = parsed.dig("values")
    if data.nil?
      Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} between: #{start_date} and #{end_date}, response: #{response.body}")
      raise InvalidExchangeRateError.new("Could not fetch exchange rates for #{from}/#{to} between #{start_date} and #{end_date}, response: #{response.body}")
    end
    data
  end

  def fetch_exchange_rates_internal(from:, to:, start_date:, end_date:)
    response = client.get("#{base_url}/time_series") do |req|
      req.params["symbol"] = "#{from}/#{to}"
      req.params["start_date"] = start_date.to_s
      req.params["end_date"] = end_date.to_s
      req.params["interval"] = "1day"
    end
    parsed = JSON.parse(response.body)
    if parsed.dig("code") == 404
      Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} between: #{start_date} and #{end_date}, response: #{response.body}")
      return fetch_exchange_cross_rates(from:, to:, start_date:, end_date:)
    end
    validate_exchange_rate_symbol!(
      parsed: parsed.dig("meta") || parsed,
      from: from,
      to: to,
      context: "between #{start_date} and #{end_date}",
      response_body: response.body
    )

    data = parsed.dig("values")
    if data.nil?
      Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} between: #{start_date} and #{end_date}, response: #{response.body}")
      raise InvalidExchangeRateError.new("Could not fetch exchange rates for #{from}/#{to} between #{start_date} and #{end_date}, response: #{response.body}")
    end
    data
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      data = fetch_exchange_rates_internal(from:, to:, start_date:, end_date:)
      data.map do |resp|
        rate = resp.dig("close")
        date = resp.dig("datetime")
        if rate.nil?
          Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} on: #{date}.  Rate data: #{rate.inspect}")
          next
        end

        Rate.new(date: date.to_date, from:, to:, rate:)
      end.compact
    end
  end

  # ================================
  #           Securities
  # ================================

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    with_provider_response do
      response = client.get("#{base_url}/symbol_search") do |req|
        req.params["symbol"] = symbol
        req.params["outputsize"] = 25
      end

      parsed = JSON.parse(response.body)

      parsed.dig("data").map do |security|
        country = ISO3166::Country.find_country_by_any_name(security.dig("country"))

        Security.new(
          symbol: security.dig("symbol"),
          name: security.dig("instrument_name"),
          logo_url: nil,
          exchange_operating_mic: security.dig("mic_code"),
          country_code: country ? country.alpha2 : nil
        )
      end
    end
  end

  def fetch_security_info(symbol:, exchange_operating_mic:)
    with_provider_response do
      response = client.get("#{base_url}/profile") do |req|
        req.params["symbol"] = symbol
        req.params["mic_code"] = exchange_operating_mic
      end

      profile = JSON.parse(response.body)

      response = client.get("#{base_url}/logo") do |req|
        req.params["symbol"] = symbol
        req.params["mic_code"] = exchange_operating_mic
      end

      logo = JSON.parse(response.body)

      SecurityInfo.new(
        symbol: symbol,
        name: profile.dig("name"),
        links: profile.dig("website"),
        logo_url: logo.dig("url"),
        description: profile.dig("description"),
        kind: profile.dig("type"),
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_price(symbol:, exchange_operating_mic: nil, date:)
    with_provider_response do
      historical_data = fetch_security_prices(symbol:, exchange_operating_mic:, start_date: date, end_date: date)

      raise ProviderError, "No prices found for security #{symbol} on date #{date}" if historical_data.data.empty?

      historical_data.data.first
    end
  end

  def fetch_security_prices(symbol:, exchange_operating_mic: nil, start_date:, end_date:)
    with_provider_response do
      response = client.get("#{base_url}/time_series") do |req|
        req.params["symbol"] = symbol
        req.params["mic_code"] = exchange_operating_mic
        req.params["start_date"] = start_date.to_s
        req.params["end_date"] = end_date.to_s
        req.params["interval"] = "1day"
      end

      parsed = JSON.parse(response.body)
      meta = parsed.dig("meta")
      if !parsed.dig("code").nil?
        Rails.logger.warn("#{self.class.name} returned invalid price data for security #{symbol} between #{start_date} and #{end_date}.")
        raise InvalidSecurityPriceError.new("Could not fetch security prices for #{symbol} between #{start_date} and #{end_date}, response: #{response.body}")
      end
      parsed.dig("values").map do |resp|
        price = resp.dig("close")
        date = resp.dig("datetime")
        if price.nil?
          Rails.logger.warn("#{self.class.name} returned invalid price data for security #{symbol} on: #{date}.  Price data: #{price.inspect}")
          next
        end

        Price.new(
          symbol: symbol,
          date: date.to_date,
          price: price,
          currency: meta.dig("currency"),
          exchange_operating_mic: exchange_operating_mic
        )
      end.compact
    end
  end

  private
    attr_reader :api_key

    def validate_exchange_rate_symbol!(parsed:, from:, to:, context:, response_body:)
      actual_symbol = parsed.dig("symbol")&.upcase
      expected_symbol = "#{from}/#{to}".upcase

      return if actual_symbol.blank? || actual_symbol == expected_symbol

      raise_invalid_exchange_rate_payload!(
        "Expected #{expected_symbol} but provider returned #{actual_symbol} #{context}",
        response_body: response_body
      )
    end

    def validate_exchange_cross_metadata!(parsed:, from:, to:, start_date:, end_date:, response_body:)
      base_instrument = parsed.dig("meta", "base_instrument").to_s.upcase
      quote_instrument = parsed.dig("meta", "quote_instrument").to_s.upcase

      return if base_instrument.blank? || quote_instrument.blank?

      actual_from = base_instrument.split("/").first
      actual_to = quote_instrument.split("/").first

      return if actual_from == from.upcase && actual_to == to.upcase

      raise_invalid_exchange_rate_payload!(
        "Expected #{from}/#{to} but provider returned cross metadata #{base_instrument} -> #{quote_instrument} between #{start_date} and #{end_date}",
        response_body: response_body
      )
    end

    def raise_invalid_exchange_rate_payload!(message, response_body:)
      Rails.logger.warn("#{self.class.name} #{message}, response: #{response_body}")
      raise InvalidExchangeRateError.new("#{message}, response: #{response_body}")
    end

    def base_url
      ENV["TWELVE_DATA_URL"] || "https://api.twelvedata.com"
    end

    def client
      @client ||= Faraday.new(url: base_url) do |builder|
        builder.request(:retry, {
          max: 2,
          retry_block: ->(env, _, retries, _) {
            # Sleep between 1-4 minutes when retrying
            sleep(60 + rand(180))
          },
          retry_if: ->(env, exception) {
            env.body[:code] == 429
          }
        })

        builder.request :json
        builder.response :raise_error
        builder.headers["Authorization"] = "apikey #{api_key}"
      end
    end
end
