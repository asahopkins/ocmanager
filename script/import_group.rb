#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require 'fastercsv'
path_to_file = "/home/vu2028/groups/infocentral-lcf.csv"
group_id = 6
campaign_id = 2

FasterCSV.foreach(path_to_file) do |row|
  first_name = row[1]
  last_name = row[2]
  matches = Entity.find(:all,:conditions=>['(first_name = :first OR nickname = :first) AND last_name = :last AND campaign_id = :campaign',{:first=>first_name,:last=>last_name,:campaign=>campaign_id}])
  if matches and matches.length == 1
    # exactly one match
    existing = GroupMembership.find(:first, :conditions=>['entity_id = :ent AND group_id = :group', {:ent=>matches.first.id, :group=>group_id}])
    if existing.nil?
      gm = GroupMembership.new(:entity_id=>matches.first.id,:group_id=>group_id,:role=>"Member")
      if gm.save
        # puts "added to group: "+row[0]
      else
        puts "error, not saved: "+row[0]
      end
    else
#      puts "already a member: "+row[0]
    end
  elsif matches.length > 1
    puts "multiple matches: "+row[0]
  else
    puts "not found: "+row[0]
  end
end
puts "done"
