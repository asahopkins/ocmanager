class RemoveContributionRecipients < ActiveRecord::Migration
  def self.up
    drop_table :contribution_recipients
    add_column :contributions, :recipient, :string
    remove_column :contributions, :contribution_recipient_id
  end

  def self.down
    remove_column :contributions, :recipient
    add_column :contributions, :contribution_recipient_id
    create_table :contribution_recipients, :force=>true do |t|
      t.column :campaign_id, :integer
      t.column :name, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end
end
