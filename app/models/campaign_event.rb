# ---------------------------------------------------------------------------
# 
# Open Campaigns Manager
# Copyright (C) 2008 Asa S. Hopkins, Open Campaigns
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# ---------------------------------------------------------------------------

class CampaignEvent < ActiveRecord::Base
  include DRbUndumped
  belongs_to :campaign
  has_many :contact_events, :dependent=>:destroy # use for pledged contributions
  has_many :rsvps, :dependent=>:destroy
  has_many :contributions
  has_many :entities, :through=>:contributions
  belongs_to :recipient_committee, :class_name=>"OutsideCommittee", :foreign_key=>"recipient_committee_id"

  def validate
    errors.add('goal', 'must be a positive number or blank.') unless (goal.nil? or goal > 0)
  end
  
  validates_presence_of :name

  def label
    name
  end
  
  def date
    start_time
  end
  
  def all_entities
    (self.invited + self.attended + self.contributors + self.pledged_contributors).flatten.uniq
  end
  
  def rsvp_entities(sort = "name")
    
    if sort == "name"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    if sort == "invited"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions],:conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"rsvps.invited ASC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    if sort == "attendance"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions],:conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"rsvps.attended ASC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    if sort == "response"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions],:conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"rsvps.response DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    if sort == "pledge"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)", {:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"contact_events.pledge_value DESC, contact_events.will_contribute DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    if sort == "contribution"
      ents = Entity.find :all, :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)", {:event_id=>self.id, :campaign=>self.campaign_id}], :order=>"contributions.amount DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    
    # pledges = self.pledged_contributors
    # contribs = self.contributors
    # ents = (self.invited + self.attended + pledges + contribs).flatten.uniq
    # ents.sort! { |a,b| Entity.sort_by_name(a,b) }
    # if sort == "response"
    #   ents.sort! { |a,b| Rsvp.sort_by_response(a.event_rsvp(self),b.event_rsvp(self)) }
    # elsif sort == "invited"
    #   ents.sort! { |a,b| Rsvp.sort_by_invitation(a.event_rsvp(self),b.event_rsvp(self)) }
    # elsif sort == "attendance"
    #   ents.sort! { |a,b| Rsvp.sort_by_attendance(a.event_rsvp(self),b.event_rsvp(self)) }
    # elsif sort == "pledge"
    #   ents.sort! { |a,b| 
    #     if pledges.include?(a) and pledges.include?(b)
    #       b.pledge_value(self).to_i <=> a.pledge_value(self).to_i
    #     elsif pledges.include?(a) and a.pledge_value(self).to_i > 0
    #       -1
    #     elsif pledges.include?(b) and b.pledge_value(self).to_i > 0
    #       1
    #     else
    #       0
    #     end }
    # elsif sort == "contribution"
    #   ents.sort! { |a,b| 
    #     if contribs.include?(a) and contribs.include?(b)
    #       b.event_contribution(self).to_i <=> a.event_contribution(self).to_i
    #     elsif contribs.include?(a) and a.event_contribution(self).to_i > 0
    #       -1
    #     elsif contribs.include?(b) and b.event_contribution(self).to_i > 0
    #       1
    #     else
    #       0
    #     end }
    # end
    ents
  end

  # returns an array of entities who have been invited to the event
  def invited
    # sorted_rsvps = self.rsvps.sort { |a,b| a.response <=> b.response }
    ents = Entity.find :all, :include=>[:rsvps],:conditions=>["rsvps.invited = :true AND rsvps.campaign_event_id = :self",{:true=>true, :self=>self.id}]
  end

  # returns a count of the entities who have been invited to the event
  def invited_count
    # sorted_rsvps = self.rsvps.sort { |a,b| a.response <=> b.response }
    count = Entity.count 'entities.id', :include=>[:rsvps],:conditions=>["rsvps.invited = :true AND rsvps.campaign_event_id = :self",{:true=>true, :self=>self.id}]
  end

  # returns an array of entities who have RSVPed "Yes" to the event
  def attending
    ents = Entity.find :all, :include=>[:rsvps],:conditions=>["rsvps.response = :yes AND rsvps.campaign_event_id = :self",{:yes=>"Yes", :self=>self.id}]
  end

  # returns a count of the entities who have RSVPed "Yes" to the event
  def attending_count
    ents = Entity.count 'entities.id', :include=>[:rsvps],:conditions=>["rsvps.response = :yes AND rsvps.campaign_event_id = :self",{:yes=>"Yes", :self=>self.id}]
  end

  # returns an array of entities who attended the event
  def attended
    ents = Entity.find :all, :include=>[:rsvps],:conditions=>["rsvps.attended = :true AND rsvps.campaign_event_id = :self",{:true=>true, :self=>self.id}]
  end

  # returns a count of the entities who attended the event
  def attended_count
    ents = Entity.count 'entities.id', :include=>[:rsvps],:conditions=>["rsvps.attended = :true AND rsvps.campaign_event_id = :self",{:true=>true, :self=>self.id}]
  end

  def contributors(threshold = 0)
    if threshold <= 0
      entities
    else
      tmp = []
      entities.each do |ent|
        if ent.event_contribution(self) >= threshold
          tmp << ent
        end
      end
      return tmp
    end
  end
  
  def total_contributions
    total = 0
    contributions.each do |contrib|
      total += contrib.amount.to_f
    end
    total
  end
  
  def pledges
    contact_events.find(:all, :conditions=>["will_contribute = :true",{:true=>true}], :include=>:entity)
  end
  
  def pledged_contributors(threshold = 0)
    ents = []
    pledges.each do |pledge|
      ents << pledge.entity
    end
    ents.uniq
    if threshold > 0
      tmp = []
      ents.each do |ent|
        if ent.pledge_value(self) >= threshold
          tmp << ent
        end
      end
      return tmp
    end
    ents
  end
  
  def total_pledged
    total = 0
    pledged_contributors.each do |entity|
      total += entity.pledge_value(self)
    end
    total
  end
  
  def recipient_committee_name
    return recipient_committee.name unless recipient_committee.nil?
    return ""
  end
  
end
