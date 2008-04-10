class AddFormattedText < ActiveRecord::Migration
  def self.up
    add_column :contact_texts, :formatted_text, :text
  end

  def self.down
    remove_column :contact_texts, :formatted_text
  end
end
