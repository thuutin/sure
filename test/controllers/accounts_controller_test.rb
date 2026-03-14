require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  include BalanceTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get show" do
    get account_url(@account)
    assert_response :success
  end

  test "show exposes a secondary chart series for foreign currency accounts" do
    @account.update!(currency: "EUR")
    @account.save!
    @account.balances.destroy_all

    create_balance(account: @account, date: 1.day.ago.to_date, balance: 1000)
    create_balance(account: @account, date: Date.current, balance: 1200)

    ExchangeRate.create!(
      date: 1.day.ago.to_date,
      from_currency: "EUR",
      to_currency: "USD",
      rate: 1.1
    )

    get account_url(@account)
    assert_response :success

    chart = Nokogiri::HTML(response.body).at_css("[data-controller='time-series-chart']")
    assert chart, "expected account chart to be rendered"
    assert chart["data-time-series-chart-secondary-data-value"].present?
    assert_equal "EUR", chart["data-time-series-chart-primary-series-label-value"]
    assert_equal "USD equivalent", chart["data-time-series-chart-secondary-series-label-value"]

    secondary_data = JSON.parse(CGI.unescapeHTML(chart["data-time-series-chart-secondary-data-value"]))

    assert_equal "USD", secondary_data["values"].last["value"]["currency"]
    assert_in_delta 1320, secondary_data["values"].last["value"]["amount"].to_f, 0.001
  end

  test "should sync account" do
    post sync_account_url(@account)
    assert_redirected_to account_url(@account)
  end

  test "should get sparkline" do
    get sparkline_account_url(@account)
    assert_response :success
  end

  test "destroys account" do
    delete account_url(@account)
    assert_redirected_to accounts_path
    assert_enqueued_with job: DestroyJob
    assert_equal "Account scheduled for deletion", flash[:notice]
  end
end
