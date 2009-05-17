require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :campaign_user_roles
  has_many :roles, :through=>:campaign_user_roles
  has_many :campaigns, :through=>:campaign_user_roles
  
  has_many :cart_items, :dependent=>:destroy
  has_many :entities, :through=>:cart_items, :include=>:primary_address
  
  has_many :searches

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def reset_password_process
    make_activation_code
    self.save!
    UserMailer.deliver_reset_password(self)
  end

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


  # def treasurer_login(comm_id)
  #   logger.debug self.treasurer_info.class.to_s
  #   t_i = self.treasurer_info
  #   if t_i.nil?
  #     return nil
  #   end
  #   array = self.treasurer_info[comm_id]
  #   unless array.nil?
  #     return array[0]
  #   else
  #     return nil
  #   end
  # end
  # 
  # def treasurer_token(comm_id)
  #   t_i = self.treasurer_info
  #   if t_i.nil?
  #     return nil
  #   end
  #   array = self.treasurer_info[comm_id]
  #   unless array.nil?
  #     return array[1]
  #   else
  #     return nil
  #   end
  # end

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
  
  # Return true/false if User is authorized for resource.
  def prohibited?(controller, action, vol_sign_in = false) # pass in campaign_id
    logger.debug "controller: "+controller.to_s
    logger.debug "action: "+action.to_s
    resource = "%s/%s" % [ controller, action ]
    # resources where nil campaign_id is OK: 
    open_to_all = ["users/forgot_password", "users/reset_password_email", "users/reset_password", "users/set_password", "users/activate", "sessions/new", "sessions/create", "sessions/destroy"]
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
      financial = cur.financial
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
        logger.debug "edit groups"
        logger.debug financial
        if ['admin','custom_fields', 'group_fields'].include?(controller) or  ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'campaign_events/new', 'campaign_events/create', 'campaign_events/edit', 'campaign_events/update', 'campaign_events/hide'].include?(resource)
          return true
        elsif ( !financial and ['entities/update_contribution', 'entities/create_contribution'].include?(resource))
            return true
        else
          return false
        end
      when 5 # Basic Edit (Data Entry)
        if ['admin', 'custom_fields', 'group_fields'].include?(controller) or  ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'groups/new', 'groups/edit', 'groups/update', 'groups/create', 'groups/remove_member', 'groups/add_cart_to_group', 'groups/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'entities/add_to_group', 'entities/remove_from_group', 'campaign_events/new', 'campaign_events/create', 'campaign_events/edit', 'campaign_events/update', 'campaign_events/hide'].include?(resource)
          return true
        elsif ( !financial and ['entities/update_contribution', 'entities/create_contribution'].include?(resource))
            return true
        else
          return false
        end
      when 6 # Read Only # TODO: ?? allow readonly folks to fill MyPeople, or no?
        # TODO: should be able to access user/edit to change password
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

  protected
    
    def make_activation_code
        self.deleted_at = nil
        self.activation_code = self.class.make_token
    end


end
