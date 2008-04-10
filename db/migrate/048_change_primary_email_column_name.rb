class ChangePrimaryEmailColumnName < ActiveRecord::Migration
  def self.up
    rename_column :entities, :primary_email, :primary_email_label
  end

  def self.down
    rename_column :entities, :primary_email_label, :primary_email
  end
end
