class AddEntityWebsite < ActiveRecord::Migration
  def self.up
    add_column :entities, :website, :string
  end

  def self.down
    remove_column :entities, :website
  end
end
