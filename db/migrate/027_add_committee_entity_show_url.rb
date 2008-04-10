class AddCommitteeEntityShowUrl < ActiveRecord::Migration
  def self.up
    add_column :committees, :treasurer_entity_show_url, :string
  end

  def self.down
    remove_column :committees, :treasurer_entity_show_url
  end
end
