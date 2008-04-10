class AddBounceTrackingFields < ActiveRecord::Migration
  def self.up
    add_column :contact_events, :message_id, :string
    add_column :contact_events, :status, :string
  end

  def self.down
    remove_column :contact_events, :message_id
    remove_column :contact_events, :status
  end
end
