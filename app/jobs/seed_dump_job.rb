class SeedDumpJob < ApplicationJob
  queue_as :scheduled

  def perform
    return if Rails.env.development?

    models = [
      "Setting",
      "ActiveStorage::VariantRecord",
      "ActiveStorage::Attachment",
      "ActiveStorage::Blob",
      "Security::Price",
      "Rule::Condition",
      "Rule::Action",
      "TransactionImport",
      "Import::Row",
      "Valuation",
      "User",
      "Transfer",
      "Transaction",
      "Trade",
      "Tagging",
      "Sync",
      "Session",
      "Security",
      "Rule",
      "RejectedTransfer",
      "Investment",
      "Holding",
      "Family",
      "ExchangeRate",
      "Entry",
      "Depository",
      "DataEnrichment",
      "Crypto",
      "CreditCard",
      "Chat",
      "BudgetCategory",
      "Budget",
      "Balance",
      "Account",
      "Tag",
      "Category",
      "Import::TagMapping",
      "Import::CategoryMapping",
      "ToolCall::Function",
      "UserMessage",
      "AssistantMessage"
    ].join(",")
    SeedDump.dump_using_environment({
      "IMPORT" => true,
      "FILE" => "db/seeds/db_restore.rb",
      "EXCLUDE" => "",
      "MODELS" => models
    })
  end
end
