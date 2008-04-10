class FixTypoInTreasurerEntityDefinition < ActiveRecord::Migration
  def self.up
    rename_column :treasurer_entities, :entities_id, :entity_id
  end

  def self.down
    rename_column :treasurer_entities, :entity_id, :entities_id
  end
end
