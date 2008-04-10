class AddGroups < ActiveRecord::Migration
  def self.up
    create_table "groups" do |t|
      t.column :name, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime
    end
    create_table "group_memberships" do |t|
      t.column :group_id, :integer
      t.column :entity_id, :integer
      t.column :role, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime
    end
    create_table "group_fields" do |t|
      t.column :group_id, :integer
      t.column :name, :string
      t.column :field_type, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime
    end
    create_table "group_field_values" do |t|
      t.column :group_membership_id, :integer
      t.column :group_field_id, :integer
      t.column :value, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table "groups"
    drop_table "group_memberships"
    drop_table "group_fields"
    drop_table "group_field_values"
  end
end
