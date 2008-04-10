class AddEntitiesFollowupRequired < ActiveRecord::Migration
  def self.up
    add_column "entities", "followup_required", :boolean
  end

  def self.down
    remove_column "entities", "followup_required"
  end
end
