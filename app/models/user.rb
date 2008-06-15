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

require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  has_many :campaign_user_roles
  has_many :roles, :through=>:campaign_user_roles
  has_many :campaigns, :through=>:campaign_user_roles
  
  has_many :cart_items, :dependent=>:destroy
  has_many :entities, :through=>:cart_items, :include=>:primary_address
  
  attr_accessor :new_password
 
  serialize :treasurer_info
 
  # Return true/false if User is authorized for resource.
  def prohibited?(controller, action, campaign_id, vol_sign_in = false) # pass in campaign_id
    #logger.debug "controller: "+controller.to_s
    #logger.debug "action: "+action.to_s
    #logger.debug "campaign_id: "+campaign_id.to_s
    resource = "%s/%s" % [ controller, action ]
    # resources where nil campaign_id is OK: 
    open_to_all = ["user/login", "user/logout", "user/not_available", "user/change_password", "user/forgot_pasword"]
    no_id = ["user/welcome",'campaigns/select']
    if open_to_all.include?(resource)
      logger.debug "open to all"
      return false
    elsif no_id.include?(resource)
      logger.debug "no id"
      return false
    elsif self.highest_role==1 # TODO: this should be cached, probably
        return false
    else
      logger.debug "checking permissions"
      self.reload unless self.current_campaign
      cur = CampaignUserRole.find(:first, :conditions=>["user_id = :user AND campaign_id = :comm",{:user=>self.id, :comm=>self.current_campaign}]) # TODO: cache this
      role = cur.role # TODO: cache this
      ####
      rank = cur.role.rank
      if vol_sign_in # boolean
        rank = 7
      end
      logger.debug "rank = "+rank.to_s
      case rank
      when 1
        return false
      when 2 #Manager
        if ['group_fields'].include?(controller) or ['campaigns/new', 'campaigns/create','campaigns/destroy','admin/update_permissions'].include?(resource)
          return true
        else
          return false
        end
      when 3 # Edit All
        if ['admin','custom_fields', 'group_fields'].include?(controller) or ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'campaign_events/new', 'campaign_events/create', 'campaign_events/edit', 'campaign_events/update', 'campaign_events/hide'].include?(resource)
          return true
        else
          return false
        end
      when 4 # Edit Groups
        if ['admin','custom_fields', 'group_fields'].include?(controller) or  ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution', 'campaign_events/new', 'campaign_events/create', 'campaign_events/edit', 'campaign_events/update', 'campaign_events/hide'].include?(resource)
          return true
        else
          return false
        end
      when 5 # Basic Edit
        if ['admin', 'custom_fields', 'group_fields'].include?(controller) or  ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'groups/new', 'groups/edit', 'groups/update', 'groups/create', 'groups/remove_member', 'groups/add_cart_to_group', 'groups/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution', 'entities/add_to_group', 'entities/remove_from_group', 'campaign_events/new', 'campaign_events/create', 'campaign_events/edit', 'campaign_events/update', 'campaign_events/hide'].include?(resource)
          return true
        else
          return false
        end
      when 6 # Read Only # TODO: ?? allow readonly folks to fill MyPeople, or no?
        # TODO: should be about to access user/edit to change password
        if ['admin', 'committees','custom_fields', 'group_fields'].include?(controller) or ['edit', 'update', 'new', 'create','destroy'].include?(action) or ['backend/update_entity_from_struct', 'backend/create_entity_from_struct', 'groups/remove_member', 'groups/add_cart_to_group', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution', 'entities/add_to_group', 'entities/remove_from_group', 'entities/add_tag_to_cart', 'entities/add_to_household', 'entities/remove_from_household', 'entities/household_search', 'entities/update_partial','entities/update_custom', 'entities/update_name', 'entities/update_address', 'entities/delete_address', 'entities/add_address', 'entities/update_phones', 'entities/add_phone', 'entities/delete_phone', 'entities/update_faxes', 'entities/add_fax', 'entities/delete_fax', 'entities/update_emails', 'entities/add_email', 'entities/delete_email', 'entities/update_website', 'entities/update_skills', 'campaign_events/hide'].include?(resource)
          return true
        else
          return false
        end
      when 7 # Sign In
        if ['volunteer_events/sign_out', 'volunteer_events/autocomplete_for_sign_out', 'volunteer_events/sign_out_form', 'volunteer_events/sign_in_form', 'volunteer_events/welcome', 'volunteer_events/sign_in', 'entities/autocomplete_for_sign_in', 'entities/simple_show_for_sign_in', 'entities/simple_show_for_sign_out', 'entities/simple_self_edit', 'entities/self_update'].include?(resource)
          return false
        else
          return true
        end
      when 8 # Inactive
        if ['admin', 'backend', 'campaigns', 'committees', 'custom_fields', 'entities', 'group_fields', 'groups', 'user', 'volunteeer_tasks', 'campaign_events', 'contact_events', 'volunteer_events', 'contact_texts', 'cart_items'].include?(controller)
          return true
        else
          return false
        end
      end
      return true
      
      ####
#      return (prohibition_strings.include?(resource) or prohibited_controllers.include?(controller) or prohibited_actions.include?(action))
    end
  end
  
#  def prohibited?(resource, campaign_id) # pass in campaign_id
#    logger.debug "resource: "+resource.to_s
#    logger.debug "campaign_id: "+campaign_id.to_s
    # resources where nil campaign_id is OK: campaigns/summary, admin/index, admin, campaigns/navigation
#    no_id = ["campaigns/summary","campaigns/new","campaigns/list","admin/index", "admin", "campaigns/navigation","user/edit","user/list","user/login","user/logout","user/not_available","user/new","user/change_password","user/forgot_pasword","user/welcome","entities/full_search"]
#    if (campaign_id.nil? and no_id.include?(resource))
#      campaign_id = -1
#    end
#    return prohibition_strings(campaign_id).include?(resource)
#  end

  # Load permission strings 
  def prohibition_strings
    a = []
    logger.debug "in prohibition_strings"
    # @cur = CampaignUserRole.find(:first,:conditions=>["user_id = :user AND campaign_id = :comm",{:user=>self.id, :comm=>campaign_id}])
    # unless prohibs = Cache.get "ManagerRole:#{@role.id}:prohibs"
    #   prohibs = @role.prohibitions
    #   Cache.put "Role:#{@role.id}:prohibs", prohibs
    # end
    # prohibs.each{|p| a<< p.name }
    @role.prohibitions.each{|p| a<< p.name } # TODO: cache these
    a
  end
  
  def prohibited_controllers
    a = []
    logger.debug "in prohibited_controllers"
    # @cur = CampaignUserRole.find(:first,:conditions=>["user_id = :user AND campaign_id = :comm",{:user=>self.id, :comm=>campaign_id}])
    @role.prohibited_controllers.each{|p| a<< p.name } # TODO: cache these
    a
  end
  
  def prohibited_actions
    a = []
    logger.debug "in prohibited_actions"
    # @cur = CampaignUserRole.find(:first,:conditions=>["user_id = :user AND campaign_id = :comm",{:user=>self.id, :comm=>campaign_id}])
    @role.prohibited_actions.each{|p| a<< p.name } # TODO: cache these
    a
  end
  
  # replaced by :through
  # return an array of campaigns that the user has any role for (including inactive)
#  def campaigns
#    c = []
#    self.campaign_user_roles.each{ |cur| 
#      if cur.role.rank==1
#        Campaign.find(:all).each { |comm| 
#          c << comm.id
#          }
#      else
#        if Campaign.find(cur.campaign_id)
#          c << cur.campaign_id
#        end
#      end
#      }
#    c
#  end
  
  # return an array of campaign_ids that the user is active for
  def active_campaigns 
    c = []
    self.campaign_user_roles.each{ |cur| 
      if cur.role.rank<=7
        c << cur.campaign_id
      end
      }
    c
  end

  #returns an array of campaign_ids the user has Manager-level access to
  def manager_campaigns 
    c = []
    self.campaign_user_roles.each{ |cur| 
      if cur.role.rank <= 2
        c << cur.campaign_id
      end
      }
    c
  end

  def initialize(attributes = nil)
    super
    @new_password = false
  end
  
  def manager?(campaign)
    return self.role(campaign)<=2
  end
  
  def edit_groups?(campaigns)
    if campaigns.is_a?(Array)
      campaigns.each do |campaign|
        if self.role(campaign)<=4
          return true
        end
      end
      return false
    elsif campaigns.is_a?(Campaign)
      return self.role(campaigns)<=4
    end
  end

  def can_see_financial?(campaign)
    if cur = CampaignUserRole.find(:first,:conditions=>["campaign_id = :campaign AND user_id = :user",{:campaign=>campaign.id, :user=>self.id}])
      if cur.role.rank <= 3 and (cur.financial.nil? or cur.financial == false)
        cur.update_attribute(:financial,true)
      end
      return cur.financial
    else
      return false
    end
  end
    
  #   return self.role(campaign)<=3
  # end

  def can_edit_entities?(campaign)
    return self.role(campaign)<=5
  end
  
  def inactive?(campaign)
    if self.role(campaign).nil? or self.role(campaign)==8
      return true
    else
      return false
    end
  end
  
  def empty_cart
    cart_items = self.cart_items
    CartItem.transaction do
      cart_items.each do |item|
        item.destroy
      end  
    end
  end
  
  def self.authenticate(login, pass)
    u = find(:first,:conditions=>["login = :login AND deleted = :false", {:login=>login, :false=>false}])
    return nil if u.nil?
    find(:first,:conditions=>["login = ? AND salted_password = ?", login, salted_password(u.salt, hashed(pass))])
  end

  def self.authenticate_by_token(id, token)
    # Allow logins for deleted accounts, but only via this method (and
    # not the regular authenticate call)
    u = find(:first,:conditions=>["id = ? AND security_token = ?", id, token])
    return nil if u.nil? or u.token_expired?
    return nil if false == u.update_expiry
    u
  end

  def token_expired?
    self.security_token and self.token_expiry and (Time.now > self.token_expiry)
  end

  def update_expiry
    write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
    write_attribute('authenticated_by_token', true)
    write_attribute("verified", true)
    update_without_callbacks
  end

  def generate_security_token(hours = nil)
    if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
        (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
      return new_security_token(hours)
    else
      return self.security_token
    end
  end

  def set_delete_after
    hours = UserSystem::CONFIG[:delayed_delete_days] * 24
    write_attribute('deleted', 1)
    write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))

    # Generate and return a token here, so that it expires at
    # the same time that the account deletion takes effect.
    return generate_security_token(hours)
  end

  def change_password(pass, confirm = nil)
    self.password = pass
    self.password_confirmation = confirm.nil? ? pass : confirm
    @new_password = true
    self.new_password = true
    #logger.debug self.password
    #logger.debug self.password_confirmation
    #logger.debug @new_password
  end

  def name
    self.firstname+" "+self.lastname
  end
    
  def api_token(campaign_id)
    cur = CampaignUserRole.find(:first,:conditions=>["user_id=:user AND campaign_id = :campaign_id",{:user=>self.id,:campaign_id=>campaign_id}])
    unless cur.nil?
      return cur.api_token
    else 
      return nil
    end
  end  
    
  def treasurer_login(comm_id)
    logger.debug self.treasurer_info.class.to_s
    t_i = self.treasurer_info
    if t_i.nil?
      return nil
    end
    array = self.treasurer_info[comm_id]
    unless array.nil?
      return array[0]
    else
      return nil
    end
  end
  
  def treasurer_token(comm_id)
    t_i = self.treasurer_info
    if t_i.nil?
      return nil
    end
    array = self.treasurer_info[comm_id]
    unless array.nil?
      return array[1]
    else
      return nil
    end
  end

  def superuser?
    self.roles.each {|role| 
		    if role.rank == 1 
		      return true 
		    end
	    }
	  return false
  end
  
  def role(campaign) #TODO: make this return the role id, and make a new function to return the rank (and propagate it through)
    if cur = CampaignUserRole.find(:first,:conditions=>["campaign_id = :campaign AND user_id = :user",{:campaign=>campaign.id, :user=>self.id}])
      return cur.role.rank
    else
      return nil
    end
  end

# TODO: update/double check this for correct role numbers
  def highest_role
    unless self.roles.empty?
      base = 5
      self.roles.each { |role|
        #logger.debug role
        #logger.debug role.rank
        if role.rank<base
          base = role.rank
        end
      }
    else
      logger.debug "No roles"
      created_by = User.find(:first,:conditions=>["id = :created_by_id",{:created_by_id=>self.created_by}])
      logger.debug "created_by: "+created_by.id.to_s
      if created_by.superuser?
        base = 2
      else
        base = 5
      end
    end
    return base
  end

  protected

  attr_accessor :password, :password_confirmation

  def validate_password?
    @new_password or self.new_password
  end

  def self.hashed(str)
    return Digest::SHA1.hexdigest("lsakjdfh--#{str}--")[0..39]
  end

  after_save '@new_password = false'
  after_validation :crypt_password
  def crypt_password
    #logger.debug 'crypt_password'
    if @new_password or self.new_password
      #logger.debug 'new password'
      #logger.debug self.salt
      #logger.debug self.salted_password
      write_attribute("salt", self.class.hashed("salt-#{Time.now}"))
      write_attribute("salted_password", self.class.salted_password(salt, self.class.hashed(@password)))
      #logger.debug self.salt
      #logger.debug self.salted_password
    end
  end

  def new_security_token(hours = nil)
    write_attribute('security_token', self.class.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
    write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
    update_without_callbacks
    return self.security_token
  end

  def token_lifetime(hours = nil)
    if hours.nil?
      UserSystem::CONFIG[:security_token_life_hours] * 60 * 60
    else
      hours * 60 * 60
    end
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end

  validates_presence_of :login, :on => :create
  validates_length_of :login, :within => 3..50, :on => :create
  validates_uniqueness_of :login, :on => :create
  validates_uniqueness_of :email, :on => :create

  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?
  validates_length_of :password, { :minimum => 5, :if => :validate_password? }
  validates_length_of :password, { :maximum => 40, :if => :validate_password? }
end

