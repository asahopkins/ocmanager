class AddPhonesAndEmailsTables < ActiveRecord::Migration
  def self.up
    create_table :phones, :force => true do |t|
      t.column :type, :string, :limit => 40, :default => "", :null => false
      t.column :entity_id, :integer, :default => 0, :null => false
      t.column :entity_primary_id, :integer
      t.column :label, :string, :null => false
      t.column :number, :string, :null => false
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end

    create_table :emails, :force => true do |t|
      t.column :entity_id, :integer, :default => 0, :null => false
      t.column :entity_primary_id, :integer
      t.column :label, :string, :null => false
      t.column :address, :string, :null => false
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :phones
    drop_table :emails
  end
end
