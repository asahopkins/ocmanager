class AddSearchesToDb < ActiveRecord::Migration
  def self.up
    create_table :searches, :force => true do |t|
      t.integer :user_id
      t.integer :campaign_id
      t.text :cond
      t.text :includes
      t.string :joins
      t.timestamps
    end
  end

  def self.down
    drop_table :seaches
  end
end
