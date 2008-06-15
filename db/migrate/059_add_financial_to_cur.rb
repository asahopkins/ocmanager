class AddFinancialToCur < ActiveRecord::Migration
  def self.up
    add_column :campaign_user_roles, :financial, :boolean, :default=>false
  end

  def self.down
    remove_column :campaign_user_roles, :financial
  end
end
