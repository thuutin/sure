# Event Subscriber
class LogEventSubscriber
  def emit(event)
    payload = event[:payload].map { |key, value| "#{key}=#{value}" }.join(" ")

    source_location = event[:source_location]

    log = "[#{event[:name]}] #{payload} at #{source_location[:filepath]}:#{source_location[:lineno]}"
    Rails.logger.info(log)
    Honeybadger.event(event[:name], payload: event[:payload], source_location: source_location)
  end
end

# Error Subscriber
class LogErrorSubscriber
  def report(error, handled:, severity:, context:, source:)
    error_message = "#{error.class}: #{error.message}"
    error_message += " (handled: #{handled}, severity: #{severity}, source: #{source})"

    if context.any?
      context_str = context.map { |k, v| "#{k}=#{v}" }.join(", ")
      error_message += " [context: #{context_str}]"
    end

    Rails.logger.error("[Error] #{error_message}")

    # Log backtrace in development
    if Rails.env.development? && error.backtrace
      Rails.logger.error("Backtrace:\n#{error.backtrace.first(10).join("\n")}")
    end
  end
end

# Register subscribers
Rails.event.subscribe(LogEventSubscriber.new)
Rails.error.subscribe(LogErrorSubscriber.new)
