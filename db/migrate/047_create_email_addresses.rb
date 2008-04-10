class CreateEmailAddresses < ActiveRecord::Migration
  def self.up
    create_table :email_addresses do |t|
      t.column :entity_id, :integer
      t.column :label, :string
      t.column :address, :string
      t.column :invalid, :boolean, :default=>false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by, :integer
      t.column :updated_by, :integer
    end
    add_column :entities, :primary_email_id, :integer
  end

  def self.down
    drop_table :email_addresses
    remove_column :entities, :primary_email_id
  end
end
