require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include SyncableInterfaceTest, EntriesTestHelper, BalanceTestHelper

  setup do
    @account = @syncable = accounts(:depository)
    @family = families(:dylan_family)
    @admin = users(:family_admin)
    @member = users(:family_member)
  end

  test "can destroy" do
    assert_difference "Account.count", -1 do
      @account.destroy
    end
  end

  test "create_and_sync calls sync_later by default" do
    Account.any_instance.expects(:sync_later).once

    account = Account.create_and_sync({
      family: @family,
      owner: @admin,
      name: "Test Account",
      balance: 100,
      currency: "USD",
      accountable_type: "Depository",
      accountable_attributes: {}
    })

    assert account.persisted?
    assert_equal "USD", account.currency
    assert_equal 100, account.balance
  end

  test "create_and_sync skips sync_later when skip_initial_sync is true" do
    Account.any_instance.expects(:sync_later).never

    account = Account.create_and_sync(
      {
        family: @family,
        owner: @admin,
        name: "Linked Account",
        balance: 500,
        currency: "EUR",
        accountable_type: "Depository",
        accountable_attributes: {}
      },
      skip_initial_sync: true
    )

    assert account.persisted?
    assert_equal "EUR", account.currency
    assert_equal 500, account.balance
  end

  test "create_and_sync creates opening anchor with correct currency" do
    Account.any_instance.stubs(:sync_later)

    account = Account.create_and_sync(
      {
        family: @family,
        owner: @admin,
        name: "Test Account",
        balance: 1000,
        currency: "GBP",
        accountable_type: "Depository",
        accountable_attributes: {}
      },
      skip_initial_sync: true
    )

    opening_anchor = account.valuations.opening_anchor.first
    assert_not_nil opening_anchor
    assert_equal "GBP", opening_anchor.entry.currency
    assert_equal 1000, opening_anchor.entry.amount
  end

  test "create_and_sync uses provided opening balance date" do
    Account.any_instance.stubs(:sync_later)
    opening_date = Time.zone.today

    account = Account.create_and_sync(
      {
        family: @family,
        owner: @admin,
        name: "Test Account",
        balance: 1000,
        currency: "USD",
        accountable_type: "Depository",
        accountable_attributes: {}
      },
      skip_initial_sync: true,
      opening_balance_date: opening_date
    )

    opening_anchor = account.valuations.opening_anchor.first
    assert_equal opening_date, opening_anchor.entry.date
  end

  test "gets short/long subtype label" do
    investment = Investment.new(subtype: "hsa")
    account = @family.accounts.create!(
      owner: @admin,
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
