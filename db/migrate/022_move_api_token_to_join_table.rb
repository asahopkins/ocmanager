class MoveApiTokenToJoinTable < ActiveRecord::Migration
  def self.up
    remove_column :users, :api_token
    add_column :campaign_user_roles, :api_token, :string
  end

  def self.down
    add_column :users, :api_token, :string
    remove_column :campaign_user_roles, :api_token
  end
end
