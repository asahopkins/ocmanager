class AddVolunteerTasks < ActiveRecord::Migration
  def self.up
    create_table :volunteer_tasks, :force => true do |t|
      t.column "name", :string
    end
    
    create_table :entities_volunteer_tasks, :force => true do |t|
      t.column "volunteer_task_id", :integer
      t.column "entity_id", :integer
    end

    add_column :entities, :referred_by, :string
  end

  def self.down
    drop_table :volunteer_tasks
    drop_table :entities_volunteer_tasks
    
    remove_column :entities, :referred_by
  end
end
