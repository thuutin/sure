class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authentication

  def plaid
    Rails.error.handle(fallback: -> {
      render json: { error: "Invalid webhook:" }, status: :bad_request
    }) do
      webhook_body = request.body.read
      plaid_verification_header = request.headers["Plaid-Verification"]

      client = Provider::Registry.plaid_provider_for_region(:us)

      client.validate_webhook!(plaid_verification_header, webhook_body)

      PlaidItem::WebhookProcessor.new(webhook_body).process

      render json: { received: true }, status: :ok
    end
  end

  def plaid_eu
    Rails.error.handle(fallback: -> {
      render json: { error: "Invalid webhook" }, status: :bad_request
    }) do
      webhook_body = request.body.read
      plaid_verification_header = request.headers["Plaid-Verification"]

      client = Provider::Registry.plaid_provider_for_region(:eu)

      client.validate_webhook!(plaid_verification_header, webhook_body)

      PlaidItem::WebhookProcessor.new(webhook_body).process

      render json: { received: true }, status: :ok
    end
  end

  def stripe
    stripe_provider = Provider::Registry.get_provider(:stripe)

    Rails.error.handle(JSON::ParserError, Stripe::SignatureVerificationError, fallback: -> {
      Rails.logger.error "Stripe webhook processing error"
      head :bad_request
    }) do
      webhook_body = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      stripe_provider.process_webhook_later(webhook_body, sig_header)

      head :ok
    end
  end
end
