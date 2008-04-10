campaign_id = 2

campaign = Campaign.find(campaign_id)
people = Entity.find(:all, :conditions=>["entities.campaign_id = :campaign AND entities.type = 'Person'",{:campaign=>campaign_id}], :order=>"entities.last_name ASC")

people.each do |person|
  person.reload
  if person.primary_address and person.last_name.to_s != "" and person.last_name != "?" and person.primary_address.line_1.to_s != ""
    # find other potential household members
    last_name = line_1 = id = household = ""
    other_members = []
    
    last_name = person.last_name
    line_1 = person.primary_address.line_1
    id = person.id
    household = person.household_id
    other_members = Entity.find(:all,:include=>:primary_address, :conditions=>["entities.last_name = :name AND addresses.line_1 = :address AND entities.id != '#{id}' AND entities.type = 'Person' AND entities.household_id != '#{household}'",{:name=>last_name,:address=>line_1}])
    # if there are any, assign them to the same household
    if other_members.length > 0
      puts person.name+": "
      other_members.each do |member|
        puts member.name
        if gets
                member.household_id = person.household_id
                member.save
        end
      end
    end
    
  end
end
