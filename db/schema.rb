# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090106000506) do

  create_table "addresses", :force => true do |t|
    t.integer  "entity_id",               :default => 0,  :null => false
    t.string   "label",                   :default => "", :null => false
    t.string   "line_1"
    t.string   "line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip",        :limit => 5
    t.string   "zip_4",      :limit => 4
    t.date     "valid_from"
    t.date     "valid_to"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "addresses", ["entity_id"], :name => "addresses_entity_id_index"

  create_table "campaign_events", :force => true do |t|
    t.integer  "campaign_id"
    t.string   "name"
    t.datetime "start_time"
    t.boolean  "hidden",                              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "end_time"
    t.string   "website"
    t.string   "addr_line1"
    t.string   "addr_line2"
    t.string   "addr_city"
    t.string   "addr_state"
    t.string   "addr_zip",               :limit => 5
    t.string   "location_name"
    t.float    "goal"
    t.integer  "recipient_committee_id"
  end

  add_index "campaign_events", ["campaign_id"], :name => "campaign_events_campaign_id_index"

  create_table "campaign_user_roles", :force => true do |t|
    t.integer "user_id",     :default => 0,     :null => false
    t.integer "role_id",     :default => 0,     :null => false
    t.integer "campaign_id", :default => 0,     :null => false
    t.integer "created_by"
    t.integer "updated_by"
    t.string  "api_token"
    t.boolean "financial",   :default => false
  end

  add_index "campaign_user_roles", ["campaign_id", "user_id"], :name => "user_campaign_index"
  add_index "campaign_user_roles", ["user_id"], :name => "campaign_user_roles_user_id_index"

  create_table "campaigns", :force => true do |t|
    t.string "name"
    t.text   "from_emails"
  end

  create_table "cart_items", :force => true do |t|
    t.integer "user_id"
    t.integer "entity_id"
  end

  add_index "cart_items", ["user_id"], :name => "cart_items_user_id_index"

  create_table "committees", :force => true do |t|
    t.integer "campaign_id"
    t.string  "name"
    t.integer "treasurer_id"
    t.string  "treasurer_api_url"
    t.string  "treasurer_entity_show_url"
  end

  add_index "committees", ["campaign_id"], :name => "committees_campaign_id_index"

  create_table "contact_events", :force => true do |t|
    t.integer  "entity_id"
    t.integer  "contact_text_id"
    t.datetime "when_contact"
    t.string   "initiated_by"
    t.boolean  "interaction",         :default => false
    t.string   "form"
    t.boolean  "will_contribute",     :default => false
    t.boolean  "will_volunteer",      :default => false
    t.string   "how_volunteer"
    t.date     "when_volunteer"
    t.string   "when_volunteer_text"
    t.boolean  "yard_sign",           :default => false
    t.text     "memo"
    t.boolean  "requires_followup",   :default => false
    t.date     "future_contact_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campaign_id"
    t.integer  "campaign_event_id"
    t.string   "message_id"
    t.string   "status"
    t.float    "pledge_value"
  end

  add_index "contact_events", ["campaign_event_id"], :name => "contact_events_campaign_event_id_index"
  add_index "contact_events", ["contact_text_id"], :name => "contact_events_contact_text_id_index"
  add_index "contact_events", ["entity_id"], :name => "contact_events_entity_id_index"

  create_table "contact_texts", :force => true do |t|
    t.integer  "stylesheet_id"
    t.string   "label"
    t.string   "type"
    t.string   "sender"
    t.string   "subject"
    t.text     "text"
    t.boolean  "complete",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campaign_id"
    t.text     "formatted_text"
    t.integer  "campaign_event_id"
  end

  add_index "contact_texts", ["campaign_id"], :name => "contact_texts_campaign_id_index"

  create_table "contributions", :force => true do |t|
    t.integer  "entity_id"
    t.float    "amount"
    t.datetime "date"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "recipient"
    t.integer  "campaign_event_id"
    t.integer  "recipient_committee_id"
    t.string   "import_transaction_id"
  end

  add_index "contributions", ["entity_id"], :name => "contributions_entity_id_index"

  create_table "custom_field_values", :force => true do |t|
    t.integer  "entity_id"
    t.integer  "custom_field_id"
    t.string   "value"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "custom_field_values", ["custom_field_id"], :name => "custom_field_values_custom_field_id_index"
  add_index "custom_field_values", ["entity_id"], :name => "custom_field_values_entity_id_index"

  create_table "custom_fields", :force => true do |t|
    t.integer  "campaign_id"
    t.string   "name"
    t.string   "field_type"
    t.text     "select_options"
    t.boolean  "hidden"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "display_order"
  end

  add_index "custom_fields", ["campaign_id"], :name => "custom_fields_campaign_id_index"

  create_table "email_addresses", :force => true do |t|
    t.integer  "entity_id"
    t.string   "label"
    t.string   "address"
    t.boolean  "invalid",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  add_index "email_addresses", ["entity_id"], :name => "email_addresses_entity_id_index"

  create_table "entities", :force => true do |t|
    t.string   "type",                  :limit => 40, :default => "", :null => false
    t.integer  "campaign_id",                         :default => 0,  :null => false
    t.integer  "household_id"
    t.integer  "field_id"
    t.string   "name",                                :default => "", :null => false
    t.string   "title"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "name_suffix"
    t.string   "nickname"
    t.string   "voter_ID"
    t.string   "precinct"
    t.string   "languages"
    t.text     "skills"
    t.string   "occupation"
    t.string   "employer"
    t.string   "time_to_reach"
    t.boolean  "receive_email"
    t.boolean  "receive_phone"
    t.string   "federal_ID",            :limit => 20
    t.string   "state_ID",              :limit => 20
    t.boolean  "party"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.text     "phones"
    t.string   "primary_phone",         :limit => 40
    t.text     "faxes"
    t.string   "primary_fax",           :limit => 40
    t.text     "emails"
    t.string   "primary_email_label"
    t.string   "registered_party",      :limit => 40
    t.date     "birthdate"
    t.integer  "primary_address_id"
    t.integer  "mailing_address_id"
    t.string   "referred_by"
    t.text     "comments"
    t.string   "website"
    t.boolean  "delete_requested"
    t.boolean  "followup_required"
    t.integer  "primary_email_id"
    t.string   "import_contributor_id"
  end

  add_index "entities", ["campaign_id"], :name => "entities_campaign_id_index"
  add_index "entities", ["household_id"], :name => "entities_household_id_index"
  add_index "entities", ["primary_address_id"], :name => "entities_primary_address_id_index"
  add_index "entities", ["primary_email_id"], :name => "entities_primary_email_id_index"
  add_index "entities", ["type"], :name => "entities_type_index"

  create_table "entities_volunteer_tasks", :id => false, :force => true do |t|
    t.integer "volunteer_task_id"
    t.integer "entity_id"
  end

  add_index "entities_volunteer_tasks", ["entity_id"], :name => "entities_volunteer_tasks_entity_id_index"
  add_index "entities_volunteer_tasks", ["volunteer_task_id"], :name => "entities_volunteer_tasks_volunteer_task_id_index"

  create_table "exported_files", :force => true do |t|
    t.string   "filename",    :limit => 32
    t.integer  "campaign_id"
    t.boolean  "downloaded"
    t.integer  "num_entries"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  create_table "group_field_values", :force => true do |t|
    t.integer  "group_membership_id"
    t.integer  "group_field_id"
    t.string   "value"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at"
  end

  create_table "group_fields", :force => true do |t|
    t.integer  "group_id"
    t.string   "name"
    t.string   "field_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at"
    t.text     "select_options"
    t.boolean  "hidden"
  end

  create_table "group_memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "entity_id"
    t.string   "role"
    t.datetime "created_at", :null => false
    t.datetime "updated_at"
  end

  add_index "group_memberships", ["entity_id"], :name => "group_memberships_entity_id_index"
  add_index "group_memberships", ["group_id"], :name => "group_memberships_group_id_index"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at"
    t.integer  "campaign_id", :null => false
  end

  add_index "groups", ["campaign_id"], :name => "groups_campaign_id_index"

  create_table "households", :force => true do |t|
    t.integer "campaign_id"
  end

  create_table "prohibited_actions", :force => true do |t|
    t.string "name", :limit => 40, :default => "", :null => false
  end

  create_table "prohibited_actions_roles", :id => false, :force => true do |t|
    t.integer "role_id",              :default => 0, :null => false
    t.integer "prohibited_action_id", :default => 0, :null => false
  end

  create_table "prohibited_controllers", :force => true do |t|
    t.string "name", :limit => 40, :default => "", :null => false
  end

  create_table "prohibited_controllers_roles", :id => false, :force => true do |t|
    t.integer "role_id",                  :default => 0, :null => false
    t.integer "prohibited_controller_id", :default => 0, :null => false
  end

  create_table "prohibitions", :force => true do |t|
    t.string "name", :limit => 40, :default => "", :null => false
  end

  create_table "prohibitions_roles", :id => false, :force => true do |t|
    t.integer "role_id",        :default => 0, :null => false
    t.integer "prohibition_id", :default => 0, :null => false
  end

  create_table "roles", :force => true do |t|
    t.string  "name", :limit => 40, :default => "", :null => false
    t.integer "rank",               :default => 1,  :null => false
  end

  create_table "rsvps", :force => true do |t|
    t.integer "entity_id"
    t.integer "campaign_event_id"
    t.string  "response"
    t.boolean "invited",           :default => false
    t.boolean "attended",          :default => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "stylesheets", :force => true do |t|
    t.string   "name",          :default => "",          :null => false
    t.string   "side_bg",       :default => "465F7E"
    t.string   "title_bg",      :default => "C0D9FF"
    t.string   "body_bg",       :default => "FFFFFF"
    t.string   "h1_color",      :default => "000000"
    t.string   "h2_color",      :default => "000000"
    t.string   "h3_color",      :default => "000000"
    t.string   "h4_color",      :default => "000000"
    t.string   "h5_color",      :default => "000000"
    t.string   "p_color",       :default => "000000"
    t.string   "a_color",       :default => "000099"
    t.string   "strong_color",  :default => "000000"
    t.string   "h1_size",       :default => "24"
    t.string   "h2_size",       :default => "18"
    t.string   "h3_size",       :default => "14"
    t.string   "h4_size",       :default => "12"
    t.string   "h5_size",       :default => "10"
    t.string   "p_size",        :default => "12"
    t.boolean  "h1_serif",      :default => false
    t.boolean  "h2_serif",      :default => false
    t.boolean  "h3_serif",      :default => false
    t.boolean  "h4_serif",      :default => false
    t.boolean  "h5_serif",      :default => false
    t.boolean  "p_serif",       :default => false
    t.string   "h1_align",      :default => "left"
    t.string   "h2_align",      :default => "left"
    t.string   "h3_align",      :default => "left"
    t.string   "h4_align",      :default => "left"
    t.string   "h5_align",      :default => "left"
    t.boolean  "p_justify",     :default => false
    t.string   "h1_weight",     :default => "bold"
    t.string   "h2_weight",     :default => "bold"
    t.string   "h3_weight",     :default => "bold"
    t.string   "h4_weight",     :default => "bold"
    t.string   "h5_weight",     :default => "bold"
    t.string   "em_weight",     :default => "normal"
    t.string   "strong_weight", :default => "bold"
    t.string   "em_style",      :default => "italic"
    t.string   "strong_style",  :default => "normal"
    t.string   "a_decoration",  :default => "underline"
    t.string   "ul_type",       :default => "disc"
    t.string   "ol_type",       :default => "decimal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hr_width",      :default => "80"
    t.string   "hr_height",     :default => "3"
    t.string   "hr_color",      :default => "CCCCCC"
    t.integer  "campaign_id"
  end

  add_index "stylesheets", ["campaign_id"], :name => "stylesheets_campaign_id_index"

  create_table "taggings", :force => true do |t|
    t.integer "taggable_id"
    t.integer "tag_id"
    t.string  "taggable_type"
  end

  add_index "taggings", ["tag_id"], :name => "taggings_tag_id_index"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "taggable_index"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "campaign_id", :default => 0
  end

  add_index "tags", ["campaign_id"], :name => "tags_campaign_id_index"

  create_table "treasurer_entities", :force => true do |t|
    t.integer "committee_id"
    t.integer "entity_id"
    t.integer "treasurer_id"
  end

  add_index "treasurer_entities", ["entity_id"], :name => "treasurer_entities_entity_id_index"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 80,  :default => "",        :null => false
    t.string   "crypted_password",          :limit => 40,  :default => "",        :null => false
    t.string   "email",                     :limit => 60,  :default => "",        :null => false
    t.string   "salt",                      :limit => 40,  :default => "",        :null => false
    t.boolean  "verified",                                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.integer  "created_by"
    t.text     "treasurer_info"
    t.integer  "current_campaign"
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "deleted_at"
    t.string   "state",                                    :default => "passive"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "volunteer_events", :force => true do |t|
    t.integer  "entity_id"
    t.integer  "volunteer_task_id"
    t.string   "comments"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volunteer_events", ["entity_id"], :name => "volunteer_events_entity_id_index"

  create_table "volunteer_tasks", :force => true do |t|
    t.string  "name"
    t.integer "campaign_id"
    t.integer "display_order"
  end

  add_index "volunteer_tasks", ["campaign_id"], :name => "volunteer_tasks_campaign_id_index"

end
