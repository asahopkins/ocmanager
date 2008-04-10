class RemoveIdFromEntitiesVolunteerTasks < ActiveRecord::Migration
  def self.up
    drop_table :entities_volunteer_tasks
    
    create_table :entities_volunteer_tasks, :id=>false, :force => true do |t|
      t.column "volunteer_task_id", :integer
      t.column "entity_id", :integer
    end

  end

  def self.down
    drop_table :entities_volunteer_tasks

    create_table :entities_volunteer_tasks, :force => true do |t|
      t.column "volunteer_task_id", :integer
      t.column "entity_id", :integer
    end

  end
end
