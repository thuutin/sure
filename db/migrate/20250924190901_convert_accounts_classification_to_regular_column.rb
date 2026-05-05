class ConvertAccountsClassificationToRegularColumn < ActiveRecord::Migration[7.0]
  def change
    # Remove the virtual column
    remove_column :accounts, :classification, :string

    # Add a regular string column
    add_column :accounts, :classification, :string

    # Populate the classification column based on accountable_type
    execute <<-SQL
      UPDATE accounts#{' '}
      SET classification = CASE
        WHEN accountable_type IN ('Loan', 'CreditCard', 'OtherLiability')
        THEN 'liability'
        ELSE 'asset'
      END
    SQL
  end
end
