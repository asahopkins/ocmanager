class AddUserTreasurerInfo < ActiveRecord::Migration
  def self.up
    add_column :users, :treasurer_info, :text
  end

  def self.down
    remove_column :users, :treasurer_info
  end
end
