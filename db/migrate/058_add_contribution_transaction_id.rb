class AddContributionTransactionId < ActiveRecord::Migration
  def self.up
    add_column :contributions, :import_transaction_id, :string
  end

  def self.down
    remove_column :contributions, :import_transaction_id
  end
end
