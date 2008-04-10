class CreateHouseholdTable < ActiveRecord::Migration
  def self.up
    create_table :households do |t|
    end
  end

  def self.down
    drop_table :households
  end
end
