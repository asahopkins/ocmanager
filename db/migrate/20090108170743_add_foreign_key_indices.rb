class AddForeignKeyIndices < ActiveRecord::Migration
  def self.up
    add_index :campaign_events, :recipient_committee_id
    add_index :contact_events, :will_contribute
    add_index :contact_events, :pledge_value
    add_index :contact_events, [:will_volunteer, :when_volunteer], :name => "contact_events_will_volunteer_when_volunteer_index"
    add_index :contact_texts, :campaign_event_id
    add_index :contributions, :campaign_event_id
    add_index :custom_fields, :display_order
    add_index :entities, [:last_name, :name, :first_name], :name => "entities_sort_name_index"
    add_index :entities, :name
    add_index :exported_files, :campaign_id
    add_index :group_field_values, :group_membership_id
    add_index :group_field_values, :group_field_id
    add_index :group_fields, :group_id
    add_index :rsvps, :campaign_event_id
    add_index :rsvps, [:entity_id, :campaign_event_id], :name => "rsvps_entity_id_campaign_event_id_index", :unique => true
    add_index :volunteer_tasks, :display_order
  end

  def self.down
    remove_index :volunteer_tasks, :display_order
    remove_index :rsvps, :name => :rsvps_entity_id_campaign_event_id_index
    remove_index :rsvps, :campaign_event_id
    remove_index :group_fields, :group_id
    remove_index :group_field_values, :group_field_id
    remove_index :group_field_values, :group_membership_id
    remove_index :exported_files, :campaign_id
    remove_index :entities, :name => :entities_sort_name_index
    remove_index :entities, :name
    remove_index :custom_fields, :display_order
    remove_index :contributions, :campaign_event_id
    remove_index :contact_texts, :campaign_event_id
    remove_index :contact_events, :name => :contact_events_will_volunteer_when_volunteer_index
    remove_index :contact_events, :pledge_value
    remove_index :contact_events, :will_contribute
    remove_index :campaign_events, :recipient_committee_id
  end
end
