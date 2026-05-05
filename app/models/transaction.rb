class Transaction < ApplicationRecord
  include Entryable, Transferable, Ruleable, Splittable

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true

  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # File attachments (receipts, invoices, etc.) using Active Storage
  # Supports images (JPEG, PNG, GIF, WebP) and PDFs up to 10MB each
  # Maximum 10 attachments per transaction, family-scoped access
  has_many_attached :attachments do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [ 150, 150 ]
  end

  # Attachment validation constants
  MAX_ATTACHMENTS_PER_TRANSACTION = 10
  MAX_ATTACHMENT_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg image/jpg image/png image/gif image/webp
    application/pdf
  ].freeze

  validate :validate_attachments, if: -> { attachments.attached? }

  accepts_nested_attributes_for :taggings, allow_destroy: true

  before_save :normalize_foreign_keys

  enum :kind, {
    standard: "standard", # A regular transaction, included in budget analytics
    funds_movement: "funds_movement", # Movement of funds between accounts, excluded from budget analytics
    cc_payment: "cc_payment", # A CC payment, excluded from budget analytics (CC payments offset the sum of expense transactions)
    loan_payment: "loan_payment", # A payment to a Loan account, treated as an expense in budgets
    one_time: "one_time", # A one-time expense/income, excluded from budget analytics
    investment_contribution: "investment_contribution" # Transfer to investment/crypto account, treated as an expense in budgets
  }

  # All kinds where money moves between accounts (transfer? returns true).
  # Used for search filters, rule conditions, and UI display.
  TRANSFER_KINDS = %w[funds_movement cc_payment loan_payment investment_contribution].freeze

  # Kinds excluded from budget/income-statement analytics.
  # loan_payment and investment_contribution are intentionally NOT here —
  # they represent real cash outflow from a budgeting perspective.
  BUDGET_EXCLUDED_KINDS = %w[funds_movement one_time cc_payment].freeze

  # All valid investment activity labels (for UI dropdown)
  ACTIVITY_LABELS = [
    "Buy", "Sell", "Sweep In", "Sweep Out", "Dividend", "Reinvestment",
    "Interest", "Fee", "Transfer", "Contribution", "Withdrawal", "Exchange", "Other"
  ].freeze

  # Internal movement labels that should be excluded from budget (auto cash management)
  INTERNAL_MOVEMENT_LABELS = [ "Transfer", "Sweep In", "Sweep Out", "Exchange" ].freeze

  # Providers that support pending transaction flags
  PENDING_PROVIDERS = %w[simplefin plaid lunchflow enable_banking].freeze

  # Pending transaction scopes - filter based on provider pending flags in extra JSONB
  # Works with any provider that stores pending status in extra["provider_name"]["pending"]
  scope :pending, -> {
    conditions = PENDING_PROVIDERS.map { |provider| "(transactions.extra -> '#{provider}' ->> 'pending')::boolean = true" }
    where(conditions.join(" OR "))
  }

  scope :excluding_pending, -> {
    conditions = PENDING_PROVIDERS.map { |provider| "(transactions.extra -> '#{provider}' ->> 'pending')::boolean IS DISTINCT FROM true" }
    where(conditions.join(" AND "))
  }

  # SQL snippet for raw queries that must exclude pending transactions.
  # Use in income statements, balance sheets, and raw analytics.
  def self.pending_providers_sql(table_alias = "t")
    PENDING_PROVIDERS.map do |provider|
      "AND (#{table_alias}.extra -> '#{provider}' ->> 'pending')::boolean IS DISTINCT FROM true"
    end.join("\n")
  end

  # Family-scoped query for Enrichable#clear_ai_cache
  def self.family_scope(family)
    joins(entry: :account).where(accounts: { family_id: family.id })
  end

  # Overarching grouping method for all transfer-type transactions
  def transfer?
    TRANSFER_KINDS.include?(kind)
  end

  def set_category!(category)
    if category.is_a?(String)
      category = entry.account.family.categories.find_or_create_by!(
        name: category
      )
    end

    update!(category: category)
  end

  def normalize_foreign_keys
    %w[category_id merchant_id].each do |field|
      value = send(field)
      send("#{field}=", nil) if value.blank?
    end
  end
end
