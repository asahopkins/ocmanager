class FleshOutEventsAndContributions < ActiveRecord::Migration
  def self.up
    remove_column :contact_events, :pledge_value
    add_column :contact_events, :pledge_value, :float
    add_column :contributions, :campaign_event_id, :integer
    add_column :contributions, :recipient_committee_id, :integer
    add_column :campaign_events, :goal, :float
  end

  def self.down
    remove_column :contact_events, :pledge_value
    add_column :contact_events, :pledge_value, :string
    remove_column :contributions, :campaign_event_id
    remove_column :contributions, :recipient_committee_id
    remove_column :campaign_events, :goal
  end
end
