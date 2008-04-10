class AddCustomFields < ActiveRecord::Migration
  def self.up
    create_table :custom_fields, :force=>true do |t|
      t.column :campaign_id, :integer
      t.column :name, :string
      t.column :field_type, :string
      t.column :select_options, :text
      t.column :hidden, :boolean
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end

    create_table :custom_field_values, :force=>true do |t|
      t.column :entity_id, :integer
      t.column :custom_field_id, :integer
      t.column :value, :float
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :custom_field_values
    drop_table :custom_fields
  end
end
