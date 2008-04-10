class AddAddressesTable < ActiveRecord::Migration
  def self.up
    create_table :addresses, :force => true do |t|
      t.column :entity_id, :integer, :default => 0, :null => false
      t.column :entity_primary_id, :integer
      t.column :entity_mailing_id, :integer
      t.column :label, :string, :null => false
      t.column :line_1, :string
      t.column :line_2, :string
      t.column :city, :string
      t.column :state, :string
      t.column :zip, :string, :limit=>5
      t.column :zip_4, :string, :limit=>4
      t.column :valid_from, :date, :null=>true
      t.column :valid_to, :date, :null=>true
      t.column :created_by, :integer
      t.column :updated_by, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :addresses
  end
end
