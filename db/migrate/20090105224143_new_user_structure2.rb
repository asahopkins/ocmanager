class NewUserStructure2 < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |u|
      u.name = u.firstname + " " + u.lastname
      u.save
    end
  end

  def self.down
    User.find(:all).each do |u|
      u.firstname = u.name.split[0]
      u.name.split[1..-1].each do |n|
        u.lastname = u.lastname.to_s+n+" "
      end
      u.lastname = u.lastname[0..-2]
      u.save
    end
  end
end
