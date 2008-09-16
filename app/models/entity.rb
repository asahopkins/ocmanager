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

class Entity < ActiveRecord::Base
  include DRbUndumped

  belongs_to :campaign
  has_many :contributions, :dependent=>:destroy, :order=>"date DESC"
  has_many :custom_field_values, :dependent=>:destroy
  has_many :treasurer_entities, :dependent=>:destroy
  has_and_belongs_to_many :volunteer_interests, :class_name=>"VolunteerTask", :order=>'display_order ASC'
  has_many :volunteer_events, :dependent=>:destroy
  
  has_many :group_memberships, :dependent=>:destroy
  has_many :groups, :through=>:group_memberships
  
  has_many :email_addresses, :dependent=>:destroy
  belongs_to :primary_email, :class_name=>"EmailAddress", :foreign_key=>"primary_email_id"
  
  has_many :contact_events, :dependent=>:destroy
  has_many :rsvps, :dependent=>:destroy
  has_many :campaign_events, :through=>:rsvps, :order=>"campaign_events.start_time DESC"
  
  has_many :cart_items, :dependent=>:destroy
  
  acts_as_taggable

  serialize :phones
  serialize :faxes
  serialize :emails # :label=>[:address, :bounces]

  has_many :addresses, :dependent=>:destroy
  
  # figure out how to _require_ that this exist in the DB so self.primary_address isn't nil:
  belongs_to :primary_address, :class_name=>"Address", :foreign_key=>"primary_address_id" 
  belongs_to :mailing_address, :class_name=>"Address", :foreign_key=>"mailing_address_id"
  # validates_presence_of :primary_address_id
  
  validates_presence_of :name

  before_save :create_sort_name
  
  def create_sort_name
    # TODO: add a migration for an entity field which will sort correctly for alphbetizing in the database, so that we can use SQL for sorting, not ruby
  end

  def to_basic
    basic_hash = {:id=>self.id,
                              :type=>self.class,
                              :name=>self.name, 
                              :first_name=>self.first_name.to_s, 
                              :last_name=>self.last_name.to_s,
                              :phone=>self.primary_phone_number.to_s, 
                              :fax=>self.primary_fax_number.to_s,
                              :email=>self.primary_email_address.to_s,
                              :occupation=>self.occupation.to_s,
                              :employer=>self.employer.to_s,
                              :federal_ID=>self.federal_ID,
                              :state_ID=>self.state_ID,
                              :party=>self.party}
    if self.primary_address
      address_hash = {:addr_line1=>self.primary_address.line_1, 
                              :addr_line2=>self.primary_address.line_2,
                              :addr_city=>self.primary_address.city,
                              :addr_state=>self.primary_address.state,
                              :addr_ZIP=>self.primary_address.zip,
                              :addr_ZIP_4=>self.primary_address.zip_4}
      basic_hash.update(address_hash)
    end
    @return = BasicEntity.new(basic_hash)
  end

  def custom_field_value(field_id)
    values = self.custom_field_values
    cf_val_object = values.find(:first,:conditions=>["custom_field_id=:field",{:field=>field_id}])
    unless cf_val_object.nil? 
      return cf_val_object.value
    else
      return nil
    end
  end

  def primary_phone_number
    unless phones.nil?
      return phones[primary_phone]
    else
      return nil
    end
  rescue
    return nil
  end
  
  def num_to_phone(string)
    return number_to_phone(string)
  end

  def primary_fax_number
    unless faxes.nil?
      return faxes[primary_fax]
    else
      return nil
    end
  rescue
    return nil
  end

  def primary_email_address
    unless self.primary_email_id.nil?
      unless self.primary_email.nil?
        return self.primary_email.address
      else
        return nil
      end
    else
      return nil
    end
  end

  def mark_primary_email_as_invalid
    # mark primary as bad
    email = self.primary_email
    email.update_attribute(:valid,false)
    if self.email_addresses.length > 1
      # make another one the primary address
      self.email_addresses.each do |address|
        unless address.id == self.primary_email_id
          self.primary_email_id = address.id
          self.save!
          break
        end
      end
    end
  end
  
  def remove_primary_email
    email = self.primary_email
    email.destroy
    if self.email_addresses.length == 0
      self.primary_email_id = nil
    else
      self.primary_email_id = self.email_addresses.first.id
    end
    self.save!
  end

  def zip_code
    if self.primary_address.nil?
      nil
    else
      self.primary_address.zip
    end
  end
  
  def household_last_name
    self.name
  end

  def add_to_group(group, role)
    if self.groups.include?(group)
      gm = GroupMembership.find(:first,:conditions=>["entity_id = :entity AND group_id = :group",{:entity=>self.id,:group=>group.id}])
      if gm.role == role
        return true
      else
        gm.role = role
        if gm.save
          return true
        else
          return false
        end
      end
    else
      gm = GroupMembership.new(:group_id=>group.id,:entity_id=>self.id,:role=>role)
      if gm.save
        return true
      else
        return false
      end
    end
  end
  
  def remove_from_group(group)
    gm = GroupMembership.find(:first,:conditions=>["entity_id = :entity AND group_id = :group",{:entity=>self.id,:group=>group.id}])
    if gm.destroy
      return true
    else
      return false
    end
  end
  
  def role(group)
    gm = GroupMembership.find(:first,:conditions=>["entity_id = :entity AND group_id = :group",{:entity=>self.id,:group=>group.id}])
    return gm.role
  end

  def mailing_name
    if self.class==Person
      mailing_name = ""
      unless self.title.nil? or self.title.to_s==""
        mailing_name += self.title+" "
      end
      unless self.first_name.nil? or self.first_name.to_s==""
        if self.nickname.nil? or self.nickname.to_s=="" or self.nickname==self.first_name
          mailing_name += " "+self.first_name+" "
        else
          mailing_name += " "+self.nickname+" "
        end
      end
      unless self.middle_name.nil? or self.middle_name.to_s==""
        if self.middle_name.length==1
          mailing_name += " "+self.middle_name+". "
        end
      end
      unless self.last_name.nil? or self.last_name.to_s==""
        mailing_name += " "+self.last_name+" "
      end
      unless self.name_suffix.nil? or self.name_suffix.to_s==""
        mailing_name += " "+self.name_suffix+" "
      end      
      # remove extra spaces
      mailing_name = mailing_name.gsub(/\s+/,' ')
      mailing_name.strip!
    else
      mailing_name = self.name.strip
    end
    #logger.debug name
    return mailing_name.to_s
  end
  
  def casual_name
    unless nickname.nil? or nickname.to_s.strip == ""
      return nickname
    end
    unless first_name.nil? or first_name.to_s.strip == ""
      return first_name
    end
    return name
  end
  
  # returns -1, 0 or 1, for use in array sort method
  def Entity.sort_by_name(a,b)
    if a.last_name.to_s == ""
      a_name = a.name.to_s
    else
      a_name = a.last_name.to_s
    end
    if b.last_name.to_s == ""
      b_name = b.name.to_s
    else
      b_name = b.last_name.to_s
    end
    a_name = a_name.upcase
    b_name = b_name.upcase
    answer = a_name <=> b_name
    return answer unless answer == 0
    return a.first_name.to_s.upcase <=> b.first_name.to_s.upcase
  end
  
  def event_rsvp(campaign_event)
    rsvp = Rsvp.find(:first,:conditions=>["entity_id = :entity AND campaign_event_id = :event",{:entity=>self.id, :event=>campaign_event.id}])
  end

  def event_response(campaign_event)
    rsvp = Rsvp.find(:first,:conditions=>["entity_id = :entity AND campaign_event_id = :event",{:entity=>self.id, :event=>campaign_event.id}])
    if rsvp
      return rsvp.response
    else
      return nil
    end
  end
  
  def event_attendance(campaign_event)
    rsvp = Rsvp.find(:first,:conditions=>["entity_id = :entity AND campaign_event_id = :event",{:entity=>self.id, :event=>campaign_event.id}])
    if rsvp and rsvp.attended?
      return "Yes"
    else
      logger.debug "didn't attend"
      if rsvp and campaign_event.start_time < Time.now
        return "No"
      else
        return ""
      end
    end
  end
  
  def event_invitation(campaign_event)
    rsvp = Rsvp.find(:first,:conditions=>["entity_id = :entity AND campaign_event_id = :event",{:entity=>self.id, :event=>campaign_event.id}])
    if rsvp and rsvp.invited?
      return "Yes"
    else
      return "No"
    end
  end
  
  # def pledges_yes(campaign_event)
  #   contact_events.find(:all, :conditions=>["will_contribute = :true AND campaign_event_id = :event",{:true=>true, :event=>campaign_event.id}])
  # end
  
  def pledge_value(campaign_event)
    latest_contact = contact_events.find(:first, :conditions=>["will_contribute = :true AND campaign_event_id = :event AND pledge_value > 0",{:true=>true, :event=>campaign_event.id}], :order=>"when_contact DESC")
    return latest_contact.pledge_value.to_f unless latest_contact.nil?
    return nil
  end
  
  def will_contribute?(campaign_event)
    contact = contact_events.find(:first, :conditions=>["will_contribute = :true AND campaign_event_id = :event",{:true=>true, :event=>campaign_event.id}])
    return true unless contact.nil?
    false
  end
  
  def event_contribution(campaign_event)
    contribs = contributions.find(:all,:conditions=>["contributions.campaign_event_id = :event",{:event=>campaign_event.id}])
    return nil if contribs.empty?
    total = 0
    contribs.each do |contrib|
      total += contrib.amount
    end
    total
  end
  
  def recent_contributions(num)
    contributions.find(:all,:limit=>num.to_i,:order=>"date DESC")
  end

  def contribs_by_date(committee_id, latest = false, start_date = DateTime.now, end_date = DateTime.now)
    if latest
      return contributions.find(:first,:conditions=>["recipient_committee_id = :recipient_committee",{:recipient_committee=>committee_id}])
    else
      return contributions.find(:all,:conditions=>["recipient_committee_id = :recipient_committee AND date >= :start_date AND date <= :end_date",{:recipient_committee=>committee_id,:start_date=>start_date, :end_date=>end_date}])
    end
  end

  def top_recent_recipients(num)
    contribs = contributions.find(:all,:conditions=>["date >= :start_date",{:start_date=>(Time.now).beginning_of_year}])
    tmp_hash = Hash.new(0)
    contribs.each do |contribution|
      tmp_hash[contribution.recipient] += contribution.amount
    end
    sorted_array = tmp_hash.sort {|a,b| b[1]<=>a[1]}
    if sorted_array.length < num
      prev_contribs = contributions.find(:all,:conditions=>["date >= :start_date AND date < :end_date",{:start_date=>(Time.now-1.year).beginning_of_year, :end_date=>(Time.now).beginning_of_year}])
      prev_2_contribs = contributions.find(:all,:conditions=>["date >= :start_date AND date < :end_date",{:start_date=>(Time.now-2.years).beginning_of_year, :end_date=>(Time.now-1.year).beginning_of_year}])
      prev_3_contribs = contributions.find(:all,:conditions=>["date >= :start_date AND date < :end_date",{:start_date=>(Time.now-3.years).beginning_of_year, :end_date=>(Time.now-2.years).beginning_of_year}])
    end
    tmp_hash_1 = Hash.new(0)
    tmp_hash_2 = Hash.new(0)
    tmp_hash_3 = Hash.new(0)
    prev_contribs.each do |contribution|
      tmp_hash_1[contribution.recipient] += contribution.amount
    end
    prev_2_contribs.each do |contribution|
      tmp_hash_2[contribution.recipient] += contribution.amount
    end
    prev_3_contribs.each do |contribution|
      tmp_hash_3[contribution.recipient] += contribution.amount
    end
    prev_sorted_array = tmp_hash_1.sort {|a,b| b[1]<=>a[1]}
    prev_2_sorted_array = tmp_hash_2.sort {|a,b| b[1]<=>a[1]}
    prev_3_sorted_array = tmp_hash_3.sort {|a,b| b[1]<=>a[1]}
    prev_sorted_array.each do |recip|
      recip[0] = recip[0]+" (#{Time.now.year-1})"
    end
    prev_2_sorted_array.each do |recip|
      recip[0] = recip[0]+" (#{Time.now.year-2})"
    end
    prev_3_sorted_array.each do |recip|
      recip[0] = recip[0]+" (#{Time.now.year-3})"
    end
    old_sorted_array = prev_sorted_array + prev_2_sorted_array + prev_3_sorted_array
    keep_old = old_sorted_array[0,num-sorted_array.length]
    sorted_array = sorted_array + keep_old
    return sorted_array[0,num.to_i]
  end

  def current_volunteer_session
    self.volunteer_events.find(:first, :conditions=>"end_time IS NULL AND start_time IS NOT NULL") 
  end
  
  def total_volunteer_minutes_this_year
    events = self.volunteer_events
    sum = 0
    events.each do |event|
      if event.start_time > Time.now.beginning_of_year and event.end_time
        sum += event.duration
      end
    end
    return sum
  end

  def total_volunteer_minutes(start_date, end_date)
    events = self.volunteer_events.find(:all, :conditions=>["start_time > :start_date AND start_time < :end_date",{:start_date=>start_date, :end_date=>end_date}])
    sum = 0
    events.each do |event|
        sum += event.duration
    end
    return sum
  end
  
  def current_volunteer_task
    vol_session = current_volunteer_session
    unless vol_session.nil?
      return vol_session.volunteer_task_id
    else
      return nil
    end
  end

  def current_volunteer_duration
    vol_session = current_volunteer_session
    unless vol_session.nil?
      hours = (vol_session.current_duration/60.floor)
      min = (vol_session.current_duration-hours*60).to_s
      if min.length==1
        min="0"+min
      end
      return hours.to_s+":"+min
    else
      return "0:00"
    end
  end

end

