@campaign = Campaign.find(2)
telephoning = VolunteerTask.find(4)
walking = VolunteerTask.find(3)
block_captain = VolunteerTask.find(11)
data = VolunteerTask.find(5)
gotv = VolunteerTask.find(6)
voter = VolunteerTask.find(7)
hq = VolunteerTask.find(8)
funds = VolunteerTask.find(9)
nl = VolunteerTask.find(10)
@campaign.entities.each do |entity|
  if entity.skills =~ /[[:print:]*]\sT\s/ or entity.skills =~ /\sT\z/
    entity.volunteer_interests << telephoning
  end
  if entity.skills =~ /[[:print:]*]\sPW\s/ or entity.skills =~ /\sPW\z/
    entity.volunteer_interests << walking
  end
  if entity.skills =~ /[[:print:]*]\sBC\s/ or entity.skills =~ /\sBC\z/
    entity.volunteer_interests << block_captain
  end
  if entity.skills =~ /[[:print:]*]\sDE\s/ or entity.skills =~ /\sDE\z/
    entity.volunteer_interests << data
  end
  if entity.skills =~ /[[:print:]*]\sGOTV\s/ or entity.skills =~ /\sGOTV\z/
    entity.volunteer_interests << gotv
  end
  if entity.skills =~ /[[:print:]*]\sVR\s/ or entity.skills =~ /\sVR\z/
    entity.volunteer_interests << block_captain
  end
  if entity.skills =~ /[[:print:]*]\sHQ\s/ or entity.skills =~ /\sHQ\z/
    entity.volunteer_interests << block_captain
  end
  if entity.skills =~ /[[:print:]*]\sFP\s/ or entity.skills =~ /\sFP\z/ or entity.skills =~ /[[:print:]*]\s\$\s/ or entity.skills =~ /\s\$\z/
    entity.volunteer_interests << funds
  end
  if entity.skills =~ /[[:print:]*]\sNL\s/ or entity.skills =~ /\sNL\z/
    entity.volunteer_interests << nl
  end
end