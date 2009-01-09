require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :campaign_user_roles
  has_many :roles, :through=>:campaign_user_roles
  has_many :campaigns, :through=>:campaign_user_roles
  
  has_many :cart_items, :dependent=>:destroy
  has_many :entities, :through=>:cart_items, :include=>:primary_address

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

  protected
    
    def make_activation_code
        self.deleted_at = nil
        self.activation_code = self.class.make_token
    end


end
