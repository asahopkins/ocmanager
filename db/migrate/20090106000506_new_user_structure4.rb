class NewUserStructure4 < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |u|
      u.state = "active"
      u.activated_at = Time.now
      u.save
    end
  end

  def self.down
    User.find(:all).each do |u|
      u.state = nil
      u.activated_at = nil
      u.save
    end
  end
end
