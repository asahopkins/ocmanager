class CreateRsvps < ActiveRecord::Migration
  def self.up
    create_table :rsvps do |t|
      t.column :entity_id, :integer
      t.column :campaign_event_id, :integer
      t.column :response, :string
      t.column :invited, :boolean, :default=>false
      t.column :attended, :boolean, :default=>false
    end
  end

  def self.down
    drop_table :rsvps
  end
end
