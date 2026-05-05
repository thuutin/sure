require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include SyncableInterfaceTest, EntriesTestHelper, BalanceTestHelper

  setup do
    @account = @syncable = accounts(:depository)
    @family = families(:dylan_family)
  end

  test "can destroy" do
    assert_difference "Account.count", -1 do
      @account.destroy
    end
  end

  test "gets short/long subtype label" do
    investment = Investment.new(subtype: "hsa")
    account = @family.accounts.create!(
      name: "Test Investment",
      balance: 1000,
      currency: "USD",
      accountable: investment
    )

    assert_equal "HSA", account.short_subtype_label
    assert_equal "Health Savings Account", account.long_subtype_label

    # Test with nil subtype
    account.accountable.update!(subtype: nil)
    assert_equal "Investments", account.short_subtype_label
    assert_equal "Investments", account.long_subtype_label
  end

  test "balance series memoizes per target currency" do
    @account.save!
    @account.balances.destroy_all

    create_balance(account: @account, date: 1.day.ago.to_date, balance: 1000)
    create_balance(account: @account, date: Date.current, balance: 1200)

    ExchangeRate.create!(
      date: 1.day.ago.to_date,
      from_currency: "USD",
      to_currency: "EUR",
      rate: 2
    )

    period = Period.custom(start_date: 1.day.ago.to_date, end_date: Date.current)

    usd_series = @account.balance_series(period: period, currency: "USD")
    eur_series = @account.balance_series(period: period, currency: "EUR")

    assert_equal [ 1000, 1200 ], usd_series.map { |value| value.value.amount }
    assert_equal [ 2000, 2400 ], eur_series.map { |value| value.value.amount }
  end
end
