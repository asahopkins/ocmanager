class AddIndicesToForeignKeys < ActiveRecord::Migration
  def self.up
    add_index :addresses, :entity_id
    add_index :campaign_events, :campaign_id
    add_index :campaign_user_roles, :user_id
    add_index :campaign_user_roles, [:user_id, :campaign_id], :name => "user_campaign_index" #is this unique?
    add_index :cart_items, :user_id
    add_index :committees, :campaign_id
    add_index :contact_events, :entity_id
    add_index :contact_events, :contact_text_id
    add_index :contact_texts, :campaign_id
    add_index :contact_events, :campaign_event_id
    add_index :contributions, :entity_id
    add_index :custom_field_values, :entity_id
    add_index :custom_field_values, :custom_field_id
    add_index :custom_fields, :campaign_id
    add_index :email_addresses, :entity_id
    add_index :entities, :type
    add_index :entities, :campaign_id
    add_index :entities, :household_id
    add_index :entities, :primary_address_id
    add_index :entities, :primary_email_id
    add_index :entities_volunteer_tasks, :entity_id
    add_index :entities_volunteer_tasks, :volunteer_task_id
    add_index :group_memberships, :entity_id
    add_index :group_memberships, :group_id
    add_index :groups, :campaign_id
    add_index :stylesheets, :campaign_id
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type], :name => "taggable_index"
    add_index :tags, :campaign_id
    add_index :treasurer_entities, :entity_id
    add_index :volunteer_events, :entity_id
    add_index :volunteer_tasks, :campaign_id
  end

  def self.down
    remove_index :addresses, :entity_id
    remove_index :campaign_events, :campaign_id
    remove_index :campaign_user_roles, :user_id
    remove_index :campaign_user_roles, :name => :user_campaign_index
    remove_index :cart_items, :user_id
    remove_index :committees, :campaign_id
    remove_index :contact_events, :entity_id
    remove_index :contact_events, :contact_text_id
    remove_index :contact_texts, :campaign_id
    remove_index :contact_events, :campaign_event_id
    remove_index :contributions, :entity_id
    remove_index :custom_field_values, :entity_id
    remove_index :custom_field_values, :custom_field_id
    remove_index :custom_fields, :campaign_id
    remove_index :email_addresses, :entity_id
    remove_index :entities, :type
    remove_index :entities, :campaign_id
    remove_index :entities, :household_id
    remove_index :entities, :primary_address_id
    remove_index :entities, :primary_email_id
    remove_index :entities_volunteer_tasks, :entity_id
    remove_index :entities_volunteer_tasks, :volunteer_task_id
    remove_index :group_memberships, :entity_id
    remove_index :group_memberships, :group_id
    remove_index :groups, :campaign_id
    remove_index :stylesheets, :campaign_id
    remove_index :taggings, :tag_id
    remove_index :taggings, :name => :taggable_index
    remove_index :tags, :campaign_id
    remove_index :treasurer_entities, :entity_id
    remove_index :volunteer_events, :entity_id
    remove_index :volunteer_tasks, :campaign_id
  end
end
