class AddEntityImportContributorId < ActiveRecord::Migration
  def self.up
    add_column :entities, :import_contributor_id, :string
  end

  def self.down
    remove_column :entities, :import_contributor_id
  end
end
