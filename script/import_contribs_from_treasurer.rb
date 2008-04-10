#!/usr/bin/env ruby

@committees = Committee.find(:all,:conditions=>"treasurer_id IS NOT NULL")
user = User.find(1)
@committees.each do |committee|
  outside_comm = OutsideCommittee.find(:first,:conditions=>["name LIKE :name",{:name=>"%"+committee.name[0...15]+"%"}])
  unless outside_comm
    recipient = committee.name
    recipient_id = nil
  else
    recipient = outside_comm.name
    recipient_id = outside_comm.id
  end
  treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,committee.treasurer_api_url)
  t_entities = TreasurerEntity.find(:all,:conditions=>["committee_id=:committee", {:committee=>committee.id}])
  t_entities.each do |treasurer_entity|
    events = treasurer.get_transactions_by_entity_id_and_date(user.treasurer_info[committee.id][0], user.treasurer_info[committee.id][1],committee.treasurer_id,treasurer_entity.treasurer_id,true,(Time.now-30.years),Time.now)
    counter = 0
	  events.each do |event|
	    contrib = Contribution.new(:entity_id=>treasurer_entity.entity_id, :amount=>event.value, :date=>event.when_occurred,:recipient=>recipient, :recipient_committee_id=>recipient_id)
	    contrib.save!
	    counter += 1
    end
  end
end