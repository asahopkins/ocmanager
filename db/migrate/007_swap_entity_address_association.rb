class SwapEntityAddressAssociation < ActiveRecord::Migration
  # NOTE: THIS DOES NOT PRESERVE DATA
  def self.up
    add_column :entities, :primary_address_id, :integer
    add_column :entities, :mailing_address_id, :integer
    remove_column :addresses, :entity_primary_id
    remove_column :addresses, :entity_mailing_id    
  end

  def self.down
    add_column :addresses, :entity_primary_id, :integer
    add_column :addresses, :entity_mailing_id, :integer
    remove_column :entities, :primary_address_id
    remove_column :entities, :mailing_address_id
  end
end
