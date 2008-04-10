class AddUsersRolesPermissionsAndJoinTables < ActiveRecord::Migration
  def self.up
    create_table "campaign_user_roles", :force => true do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "campaign_id", :integer, :default => 0, :null => false
      t.column "created_by", :integer
      t.column "updated_by", :integer
    end

    create_table "prohibited_actions", :force => true do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
    end

    create_table "prohibited_actions_roles", :id => false, :force => true do |t|
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "prohibited_action_id", :integer, :default => 0, :null => false
    end

    create_table "prohibited_controllers", :force => true do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
    end

    create_table "prohibited_controllers_roles", :id => false, :force => true do |t|
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "prohibited_controller_id", :integer, :default => 0, :null => false
    end

    create_table "prohibitions", :force => true do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
    end

    create_table "prohibitions_roles", :id => false, :force => true do |t|
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "prohibition_id", :integer, :default => 0, :null => false
    end

    create_table "roles", :force => true do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
      t.column "rank", :integer, :default => 1, :null => false
    end

    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 80, :default => "", :null => false
      t.column "salted_password", :string, :limit => 40, :default => "", :null => false
      t.column "email", :string, :limit => 60, :default => "", :null => false
      t.column "firstname", :string, :limit => 40
      t.column "lastname", :string, :limit => 40
      t.column "salt", :string, :limit => 40, :default => "", :null => false
      t.column "verified", :boolean, :default => false
      t.column "security_token", :string, :limit => 40
      t.column "token_expiry", :datetime
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "logged_in_at", :datetime
      t.column "delete_after", :datetime
      t.column "deleted", :boolean, :default => false
      t.column "created_by", :integer
    end

  end

  def self.down
    drop_table :users
    drop_table :roles
    drop_table :prohibitions
    drop_table :prohibited_actions
    drop_table :prohibited_controllers
    drop_table :campaign_user_roles
    drop_table :prohibited_actions_roles
    drop_table :prohibited_controllers_roles
    drop_table :prohibitions_roles
  end
end
