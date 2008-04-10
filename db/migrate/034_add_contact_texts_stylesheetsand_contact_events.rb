class AddContactTextsStylesheetsandContactEvents < ActiveRecord::Migration
  def self.up
    create_table "contact_texts" do |t|
      t.column "stylesheet_id", :integer, :default=>nil
      t.column "label", :string
      t.column "type", :string
      t.column "sender", :string
      t.column "subject", :string
      t.column "text", :text
      t.column "complete", :boolean, :default => false
      t.column "created_at", :datetime
      t.column "updated_at", :datetime      
    end
    add_column "campaigns", "from_emails", :text

    create_table "stylesheets", :force => true do |t|
      t.column "name", :string, :default => "", :null => false
      t.column "side_bg", :string, :default => "465F7E"
      t.column "title_bg", :string, :default => "C0D9FF"
      t.column "body_bg", :string, :default => "FFFFFF"
      t.column "h1_color", :string, :default => "000000"
      t.column "h2_color", :string, :default => "000000"
      t.column "h3_color", :string, :default => "000000"
      t.column "h4_color", :string, :default => "000000"
      t.column "h5_color", :string, :default => "000000"
      t.column "p_color", :string, :default => "000000"
      t.column "a_color", :string, :default => "000099"
      t.column "strong_color", :string, :default => "000000"
      t.column "h1_size", :string, :default => "24"
      t.column "h2_size", :string, :default => "18"
      t.column "h3_size", :string, :default => "14"
      t.column "h4_size", :string, :default => "12"
      t.column "h5_size", :string, :default => "10"
      t.column "p_size", :string, :default => "12"
      t.column "h1_serif", :boolean, :default => false
      t.column "h2_serif", :boolean, :default => false
      t.column "h3_serif", :boolean, :default => false
      t.column "h4_serif", :boolean, :default => false
      t.column "h5_serif", :boolean, :default => false
      t.column "p_serif", :boolean, :default => false
      t.column "h1_align", :string, :default => "left"
      t.column "h2_align", :string, :default => "left"
      t.column "h3_align", :string, :default => "left"
      t.column "h4_align", :string, :default => "left"
      t.column "h5_align", :string, :default => "left"
      t.column "p_justify", :boolean, :default => false
      t.column "h1_weight", :string, :default => "bold"
      t.column "h2_weight", :string, :default => "bold"
      t.column "h3_weight", :string, :default => "bold"
      t.column "h4_weight", :string, :default => "bold"
      t.column "h5_weight", :string, :default => "bold"
      t.column "em_weight", :string, :default => "normal"
      t.column "strong_weight", :string, :default => "bold"
      t.column "em_style", :string, :default => "italic"
      t.column "strong_style", :string, :default => "normal"
      t.column "a_decoration", :string, :default => "underline"
      t.column "ul_type", :string, :default => "disc"
      t.column "ol_type", :string, :default => "decimal"
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "hr_width", :string, :default => "80"
      t.column "hr_height", :string, :default => "3"
      t.column "hr_color", :string, :default => "CCCCCC"
    end
    
    create_table "contact_events" do |t|
      t.column "entity_id", :integer
      t.column "contact_text_id", :integer, :default=>nil
      t.column "when_contact", :datetime
      t.column "initiated_by", :string
      t.column "interaction", :boolean, :default=>false
      t.column "form", :string
      t.column "will_contribute", :boolean, :default=>false
      t.column "pledge_value", :string
      t.column "will_volunteer", :boolean, :default=>false
      t.column "how_volunteer", :string
      t.column "when_volunteer", :date
      t.column "when_volunteer_text", :string
      t.column "yard_sign", :boolean, :default=>false
      t.column "memo", :text
      t.column "requires_followup", :boolean, :default=>false
      t.column "future_contact_date", :date
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    
    
  end

  def self.down
    drop_table "contact_texts"
    remove_column "campaigns", "from_emails"
    drop_table "stylesheets"
    drop_table "contact_events"
  end
end
