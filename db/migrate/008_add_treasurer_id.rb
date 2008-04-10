class AddTreasurerId < ActiveRecord::Migration
  def self.up
    add_column :entities, :treasurer_id, :integer
  end

  def self.down
    remove_column :entities, :treasurer_id
  end
end
