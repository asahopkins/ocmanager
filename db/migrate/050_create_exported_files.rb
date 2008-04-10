class CreateExportedFiles < ActiveRecord::Migration
  def self.up
    create_table :exported_files do |t|
      t.column :filename, :string, :limit=>32
      t.column :campaign_id, :integer
      t.column :downloaded, :boolean
      t.column :num_entries, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :created_by, :integer
      t.column :updated_by, :integer
    end
  end

  def self.down
    drop_table :exported_files
  end
end
