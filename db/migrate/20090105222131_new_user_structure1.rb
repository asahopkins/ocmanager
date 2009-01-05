class NewUserStructure1 < ActiveRecord::Migration
  def self.up
    add_column :users, :name, :string, :limit => 100, :default => ""
    add_column :users, :activation_code, :string, :limit=>40
    add_column :users, :activated_at, :datetime, :default=>nil
    add_column :users, :remember_token, :string, :limit=>40, :default=>nil
    add_column :users, :remember_token_expires_at, :datetime, :default=>nil
    add_column :users, :deleted_at, :datetime, :default=>nil
    add_column :users, :state, :string, :default=>"passive"
    rename_column :users, :salted_password, :crypted_password
    add_index :users, [:login], :name => "index_users_on_login", :unique => true
  end

  def self.down
    remove_index :users, :column => [:login]    
    rename_column :users, :crypted_password, :salted_password
    remove_column :users, :state
    remove_column :users, :deleted_at
    remove_column :users, :remember_token_expires_at
    remove_column :users, :remember_token
    remove_column :users, :activated_at
    remove_column :users, :activation_code
    remove_column :users, :name
  end
end
