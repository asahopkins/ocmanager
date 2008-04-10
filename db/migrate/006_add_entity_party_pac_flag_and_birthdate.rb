class AddEntityPartyPacFlagAndBirthdate < ActiveRecord::Migration
  def self.up
    change_column :entities, :party, :boolean
    add_column :entities, :registered_party, :string, :limit=>40
    add_column :entities, :birthdate, :date
  end

  def self.down
    change_column :entities, :party, :string
    remove_column :entities, :registered_party
    remove_column :entities, :birthdate
  end
end
