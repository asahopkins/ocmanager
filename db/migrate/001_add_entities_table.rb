class AddEntitiesTable < ActiveRecord::Migration
  def self.up
    create_table :entities, :force => true do |t|
      t.column :type, :string, :limit => 40, :default => "", :null => false
      t.column :campaign_id, :integer, :default => 0, :null => false
      t.column :household_id, :integer
      t.column :field_id, :integer
      t.column :name, :string, :default => "", :null => false
      t.column :title, :string
      t.column :first_name, :string
      t.column :middle_name, :string
      t.column :last_name, :string
      t.column :name_suffix, :string
      t.column :nickname, :string
      t.column :voter_ID, :string
      t.column :precinct, :string
      t.column :languages, :string
      t.column :skills, :text
      t.column :occupation, :string
      t.column :employer, :string
      t.column :time_to_reach, :string
      t.column :receive_email, :boolean
      t.column :receive_phone, :boolean
      t.column :federal_ID, :string, :limit => 20
      t.column :state_ID, :string, :limit => 20
      t.column :party, :string
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :entities
  end
end
