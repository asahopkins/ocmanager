class ChangeCustomFieldValueToString < ActiveRecord::Migration
  def self.up
    change_column :custom_field_values, :value, :string
  end

  def self.down
    change_column :custom_field_values, :value, :float
  end
end
