class AddCartItems < ActiveRecord::Migration
  def self.up
    create_table "cart_items" do |t|
        t.column "user_id", :integer
        t.column "entity_id", :integer
    end
  end

  def self.down
    drop_table "cart_items"
  end
end
