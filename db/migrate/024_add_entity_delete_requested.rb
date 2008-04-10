class AddEntityDeleteRequested < ActiveRecord::Migration
  def self.up
    add_column :entities, :delete_requested, :boolean
  end

  def self.down
    remove_column :entities, :delete_requested 
  end
end
