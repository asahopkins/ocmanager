class MovePhoneAndEmailIntoEntityTable < ActiveRecord::Migration
  def self.up
    add_column :entities, :phones, :text
    add_column :entities, :primary_phone, :string, :limit => 40
    add_column :entities, :faxes, :text
    add_column :entities, :primary_fax, :string, :limit => 40
    add_column :entities, :emails, :text
    add_column :entities, :primary_email, :string
    
    drop_table :phones
    drop_table :emails
  end

  def self.down
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
    
    remove_column :entities, :phones
    remove_column :entities, :primary_phone
    remove_column :entities, :faxes
    remove_column :entities, :primary_fax
    remove_column :entities, :emails
    remove_column :entities, :primary_email
    
  end
end
