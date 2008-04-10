class AddDisplayOrderToVolTasksAndCustomFields < ActiveRecord::Migration
  def self.up
    add_column :volunteer_tasks, :display_order, :integer
    add_column :custom_fields, :display_order, :integer
  end

  def self.down
    remove_column :volunteer_tasks, :display_order
    remove_column :custom_fields, :display_order
  end
end
