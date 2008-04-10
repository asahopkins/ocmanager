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

class Campaign < ActiveRecord::Base
  has_many :committees, :dependent=>:nullify
  has_many :entities, :dependent=>:nullify
  has_many :custom_fields, :dependent=>:nullify, :order=>'display_order ASC'
  has_many :volunteer_tasks, :dependent=>:nullify, :order=>'display_order ASC'
  has_many :groups, :order=>"name"
  has_many :campaign_events, :order=>"start_time"
  has_many :tags
  
  has_many :contact_texts
  has_many :contact_events
  
  has_many :stylesheets
  
  serialize :from_emails, Array
  
  def find_all_tags
    #logger.debug "finding all tags"
    tags = []
    entity_ids = []
    #@ents = self.entities
    #logger.debug @ents
    #SELECT tags.* FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE (taggings.taggable_id = 2479 AND taggings.taggable_type = 'Entity')
    
    self.entities.each { |entity|
      entity_ids << entity.id
    }
    
    tags = Tag.find(:all, :include=>:taggings,:conditions=>["taggings.taggable_id IN (:campaign_entities) AND taggings.taggable_type = 'Entity'",{:campaign_entities=>entity_ids}])
    
#    self.entities.each { |entity|
      #p = Person.find(entity.id)
#      entity.tags.each { |tag|
#          tags << tag
#        }
#    }
    tags.uniq!
    return tags
  end
  
  # given a date, give back an array of everyone who volunteered on that date
  def past_volunteers(date)
    start_time = date.to_time.at_beginning_of_day
    end_time = date.to_time.tomorrow.at_beginning_of_day
    entities = self.entities.find(:all, :include=>:volunteer_events, :conditions=>["volunteer_events.start_time BETWEEN :start AND :end",{:start=>start_time, :end=>end_time}], :order=>'entities.last_name, entities.name')
    entities.uniq
  end

  # given a date, give back an array fo all the people who have promised to volunteer on that date
  def promised_volunteers(date)
    start_time = date.to_time.at_beginning_of_day
    end_time = date.to_time.tomorrow.at_beginning_of_day-1.minute
    entities = self.entities.find(:all, :include=>:contact_events, :conditions=>["contact_events.when_volunteer BETWEEN :start AND :end",{:start=>start_time, :end=>end_time}], :order=>'entities.last_name, entities.name')
    entities.uniq
  end
  
  def get_recent_texts
    all_texts = self.contact_texts.find(:all, :limit=>30, :order=>'updated_at DESC',:conditions=>["updated_at > :date",{:date=>Time.now.months_ago(12)}])
    # recent_texts = []
    # all_texts.each do |text|
    #   if text.updated_at > Time.now.months_ago(12)
    #     recent_texts << text
    #   end
    # end
    # recent_texts.sort!{ |a,b| b.updated_at <=> a.updated_at }
    all_texts
  end

  def get_recent_events
    all_events = self.campaign_events.find(:all, :limit=>20, :order=>'start_time DESC',:conditions=>["updated_at > :date",{:date=>Time.now.months_ago(12)}])
    # recent_events = []
    # all_events.each do |event|
    #   if event.date > Time.now.months_ago(12)
    #     recent_events << event
    #   end
    # end
    # recent_events.sort!{ |a,b| b.updated_at <=> a.updated_at }
    all_events
  end

  def outside_committees
    comms = entities.find(:all, :conditions=>"type = 'OutsideCommittee'",:order=>"name ASC")
    campaign_comm = entities.find(:first,:conditions=>["type = 'OutsideCommittee' AND name = :name",{:name=>self.name}])
    if campaign_comm
      comms.delete(campaign_comm)
      comms.insert(0, campaign_comm)
    end
    comms
  end

end
