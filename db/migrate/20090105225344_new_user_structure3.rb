class NewUserStructure3 < ActiveRecord::Migration
  def self.up
    remove_column :users, :firstname
    remove_column :users, :lastname
    remove_column :users, :delete_after
    remove_column :users, :deleted
    remove_column :users, :security_token
    remove_column :users, :token_expiry
  end

  def self.down
    add_column :users, :token_expiry, :datetime
    add_column :users, :security_token, :string,            :limit => 40
    add_column :users, :deleted, :boolean,                                  :default => false
    add_column :users, :delete_after, :datetime
    add_column :users, :lastname, :string,                  :limit => 40
    add_column :users, :firstname, :string,                 :limit => 40
  end
end
