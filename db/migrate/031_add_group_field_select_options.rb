class AddGroupFieldSelectOptions < ActiveRecord::Migration
  def self.up
    add_column :group_fields, :select_options, :text
    add_column :group_fields, :hidden, :boolean
  end

  def self.down
    remove_column :group_fields, :select_options
    remove_column :group_fields, :hidden
  end
end
