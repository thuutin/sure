module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    private
      def report_error(e)
        Rails.error.report(error)
        Sentry.capture_exception(error) # TODO: Remove this once we've migrated to Rails.error
      end
  end
end
