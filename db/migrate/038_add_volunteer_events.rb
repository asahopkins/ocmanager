class AddVolunteerEvents < ActiveRecord::Migration
  def self.up
    create_table "volunteer_events" do |t|
      t.column "entity_id", :integer
      t.column "volunteer_task_id", :integer
      t.column "comments", :string
      t.column "start_time", :datetime
      t.column "end_time", :datetime
      t.column "duration", :integer #in minutes
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  end

  def self.down
    drop_table "volunteer_events"
  end
end
