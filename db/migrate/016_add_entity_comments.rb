class AddEntityComments < ActiveRecord::Migration
  def self.up
    add_column :entities, :comments, :text
  end

  def self.down
    remove_column :entities, :comments
  end
end
