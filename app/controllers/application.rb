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

# require 'acl_system'
# require 'localization'
# require 'user_system'
# require 'rdiscount'
require 'bluecloth'
require 'memory_logging'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '5033a1fef429baef6bc61053d19ac924'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  before_filter :login_required#, :only=>[]
  # include Localization
  # include ACLSystem
  include MemoryLogging
  
  # helper :user
  # model  :user
  # model  :contact_text
  # model  :email
  # model  :stylesheet
  # model  :contact_event
  # model  :mailer
  # model  :entity

  if File.exists?(TRIGGER_FILE) # on remote server
    @@protocol = REMOTE_PROTOCOL
    @@file_path_prefix = REMOTE_DOWNLOAD_PATH
  else # on local server (in development)
    @@protocol = LOCAL_PROTOCOL
    @@file_path_prefix = LOCAL_DOWNLOAD_PATH
  end
  
  before_filter :check_user_agent
  
  protected
  
  def check_user_agent
    logger.info request.user_agent
    if request.user_agent.downcase.include?("smartphone") #TODO: edit this to be a separate global method with a long list of keywords
      @mobile = true
    else
      @mobile = false
    end
    true
  end
  
  def paginate_collection(collection, options = {})
    default_options = {:per_page=>10, :page=>1}
    options = default_options.merge options
    
    new_collect = WillPaginate::Collection.create(options[:page],options[:per_page]) do |pager|
      pager.replace collection[pager.offset, pager.per_page].to_a
      pager.total_entries = collection.size
    end
    return new_collect
    
    # pages = Paginator.new self, collection.size, options[:per_page], options[:page]
    # first = pages.current.offset
    # last = [first+options[:per_page], collection.size].min
    # slice = collection[first...last]
    # return [pages, slice]
  end
  
  def get_campaign
    if current_user and current_user.current_campaign
      @campaign = Campaign.find(current_user.current_campaign)
    else
      redirect_to :controller=>'sessions', :action=>'destroy'
    end
    if @campaign.nil?
      redirect_to :controller=>'sessions', :action=>'destroy'
    end
  end
  
  # removes everythng except the digits 0-9 from a string.  
  # Used as pre-cleaning before storing phone and fax numbers.
  def to_numbers(string)
    @a = string.to_s.gsub(/[^0-9]/,'')
    return @a
  end
  
  def number_to_phone(number, options = {})
    options   = options.stringify_keys
    area_code = options.delete("area_code") { false }
    delimiter = options.delete("delimiter") { "-" }
    extension = options.delete("extension") { "" }
    begin
      str = area_code == true ? number.to_s.gsub(/([0-9]{3})([0-9]{3})([0-9]{4})/,"(\\1) \\2#{delimiter}\\3") : number.to_s.gsub(/([0-9]{3})([0-9]{3})([0-9]{4})/,"\\1#{delimiter}\\2#{delimiter}\\3")
      extension.to_s.strip.empty? ? str : "#{str} x #{extension.to_s.strip}"
    rescue
      number
    end
  end

  def strip_white_space
    params.each do |key,param|
      logger.debug key.to_s
      logger.debug param.to_s
      if param.kind_of?(String)
        params[key] = param.strip
        logger.debug key.to_s+"*"
        logger.debug params[key]+"*"
      end
      if param.kind_of?(Hash)
        param.each do |new_key, new_param|
          if new_param.kind_of?(String)
            params[key][new_key] = new_param.strip
            logger.debug new_key.to_s+"*"
            logger.debug params[key][new_key]+"*"
          end          
          if new_param.kind_of?(Hash)
            new_param.each do |new_key2, new_param2|
              if new_param2.kind_of?(String)
                params[key][new_key][new_key2] = new_param2.strip
                logger.debug new_key2.to_s+"*"
                logger.debug params[key][new_key][new_key2]+"*"
              end          
              if new_param2.kind_of?(Hash)
                new_param2.each do |new_key3, new_param3|
                  if new_param3.kind_of?(String)
                    params[key][new_key][new_key2][new_key3] = new_param3.strip
                    logger.debug new_key3.to_s+"*"
                    logger.debug params[key][new_key][new_key2][new_key3]+"*"
                  end          
                end
              end
            end
          end
        end
      end
    end
  end
  
  def process_entity_params(params)
    logger.debug params
    logger.debug params.class
    unless params[:entity][:class].nil?
      params[:entity][:type] = params[:entity][:class]
      params[:entity].delete(:class)
    end

    #phone
    if params[:entity][:primary_phone_number].to_s!=""
      params[:entity][:primary_phone].to_s=="" ? params[:entity][:primary_phone]="Primary" : params[:entity][:primary_phone]
      phone_hash = {params[:entity][:primary_phone]=>to_numbers(params[:entity][:primary_phone_number])}
    elsif (params[:phone] and params[:phone][:number].to_s!="")
      params[:entity][:primary_phone].to_s=="" ? params[:entity][:primary_phone]="Primary" : params[:entity][:primary_phone]
      phone_hash = {params[:entity][:primary_phone]=>to_numbers(params[:phone][:number])}
    else
      phone_hash = Hash.new
      params[:entity].delete(:primary_phone)      
    end
    params[:entity].delete(:primary_phone_number)      
    #fax
    if params[:entity][:primary_fax_number].to_s!=""
      params[:entity][:primary_fax].to_s=="" ? params[:entity][:primary_fax]="Primary" : params[:entity][:primary_fax]
      fax_hash = {params[:entity][:primary_fax]=>to_numbers(params[:entity][:primary_fax_number])}
    elsif params[:fax] and params[:fax][:number].to_s!=""
      params[:entity][:primary_fax].to_s=="" ? params[:entity][:primary_fax]="Primary" : params[:entity][:primary_fax]
      fax_hash = {params[:entity][:primary_fax]=>to_numbers(params[:fax][:number])}
    else
      fax_hash = Hash.new
      params[:entity].delete(:primary_fax)      
    end
    #email
    if params[:entity][:primary_email_address].to_s!=""
      params[:entity][:primary_email].to_s=="" ? params[:entity][:primary_email]="Primary" : params[:entity][:primary_email]
      email_hash = {params[:entity][:primary_email]=>params[:entity][:primary_email_address]}
    elsif params[:email] and params[:email][:address].to_s!=""
      params[:entity][:primary_email].to_s=="" ? params[:entity][:primary_email]="Primary" : params[:entity][:primary_email]
      email_hash = {params[:entity][:primary_email]=>params[:email][:address]}
    else
      email_hash = Hash.new
      # params[:entity].delete(:primary_email)
    end
    params[:entity].delete(:primary_email)

    params[:entity].delete(:primary_phone_number)      
    params[:entity].delete(:primary_fax_number)      
    params[:entity].delete(:primary_email_address)
          
    params[:entity][:receive_phone].to_s=="" ? params[:entity][:receive_phone]=nil : params[:entity][:receive_phone]
    params[:entity][:receive_email].to_s=="" ? params[:entity][:receive_email]=nil : params[:entity][:receive_email]
    return params, phone_hash, fax_hash, email_hash
  end

  
  def generate_password(length=10)
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ123456789'
    password = ''
    length.downto(1) { |i| password << chars[rand(chars.length - 1)] }
    password
  end
  
  def validate(campaign_id, login, token)
    user = User.find(:first,:conditions=>["login=:login",{:login=>login}])
    cur = CampaignUserRole.find(:first,:conditions=>["user_id=:user AND campaign_id=:campaign", {:user=>user.id, :campaign=>campaign_id}])
    if cur.api_token.to_s == ""
      return nil
    end
    if cur.api_token == token
      return user
    else
      return nil
    end
  end
  
  # This is out of date, now that prohibitions are checked 
  def reset_and_update_permissions
    logger.debug "inside Application.update_permissions"
    @roles = ['Manager','Edit All', 'Edit Groups','Data Entry','Read Only','Sign In','Inactive']
    @manager_prohib_controllers = ['group_fields']
    @manager_prohib_actions = []
    @manager_prohib_strings = ['campaigns/new', 'campaigns/create','campaigns/destroy','admin/update_permissions']
    @edit_all_prohib_controllers = ['admin','custom_fields', 'group_fields']
    @edit_all_prohib_actions = []
    @edit_all_prohib_strings = ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy']
    @edit_groups_prohib_controllers = ['admin','custom_fields', 'group_fields']
    @edit_groups_prohib_actions = []
    @edit_groups_prohib_strings = ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution']
    @dataentry_prohib_controllers = ['admin', 'custom_fields', 'group_fields']
    @dataentry_prohib_actions = []
    @dataentry_prohib_strings = ['campaigns/new', 'campaigns/create', 'campaigns/edit', 'campaigns/update','campaigns/destroy', 'committees/new', 'committees/create', 'committees/edit', 'committees/update', 'committees/destroy', 'groups/new', 'groups/edit', 'groups/update', 'groups/create', 'groups/remove_member', 'groups/add_cart_to_group', 'groups/destroy', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'volunteer_tasks/new', 'volunteer_tasks/create', 'volunteer_tasks/edit', 'volunteer_tasks/update', 'volunteer_tasks/destroy', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/destroy', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution', 'entities/add_to_group', 'entities/remove_from_group']
    @readonly_prohib_controllers = ['admin', 'committees','custom_fields', 'group_fields']
    @readonly_prohib_actions = ['edit', 'update', 'new', 'create','destroy']
    @readonly_prohib_strings = ['backend/update_entity_from_struct', 'backend/create_entity_from_struct', 'groups/remove_member', 'groups/add_cart_to_group', 'user/edit_roles', 'user/update_roles', 'user/delete', 'user/restore_deleted', 'user/inactivate', 'entities/upload_file', 'entities/save_and_redirect', 'entities/import_from_csv', 'entities/process_csv_data', 'entities/load_treasurer_summaries', 'entities/update_contribution', 'entities/create_contribution', 'entities/add_to_group', 'entities/remove_from_group', 'entities/add_tag_to_cart', 'entities/add_to_household', 'entities/remove_from_household', 'entities/household_search', 'entities/update_partial','entities/update_custom', 'entities/update_name', 'entities/update_address', 'entities/delete_address', 'entities/add_address', 'entities/update_phones', 'entities/add_phone', 'entities/delete_phone', 'entities/update_faxes', 'entities/add_fax', 'entities/delete_fax', 'entities/update_emails', 'entities/add_email', 'entities/delete_email', 'entities/update_website', 'entities/update_skills']
    @sign_in_prohib_controllers = ['admin', 'backend', 'campaigns', 'committees', 'custom_fields', 'entities', 'group_fields', 'groups', 'user', 'volunteeer_tasks']
    @sign_in_prohib_actions = []
    @sign_in_prohib_strings = []
    @inactive_prohib_controllers = ['admin', 'backend', 'campaigns', 'committees', 'custom_fields', 'entities', 'group_fields', 'groups', 'user', 'volunteeer_tasks']
    @inactive_prohib_actions = []
    @inactive_prohib_strings = []

    @prohibited_controller_array = [@manager_prohib_controllers, @edit_all_prohib_controllers, @edit_groups_prohib_controllers, @dataentry_prohib_controllers, @readonly_prohib_controllers, @sign_in_prohib_controllers, @inactive_prohib_controllers]
    logger.debug @prohibited_controller_array
    @prohibited_action_array = [@manager_prohib_actions, @edit_all_prohib_actions, @edit_groups_prohib_actions, @dataentry_prohib_actions, @readonly_prohib_actions, @sign_in_prohib_actions, @inactive_prohib_actions]
    logger.debug @prohibited_action_array
    @prohibited_string_array = [@manager_prohib_strings, @edit_all_prohib_strings, @edit_groups_prohib_strings, @dataentry_prohib_strings, @readonly_prohib_strings, @sign_in_prohib_strings, @inactive_prohib_strings]
    logger.debug @prohibited_string_array

    counter = 0
    @roles.each { |role_name| 
      @role = Role.find(:first,:conditions=>["name = :name",{:name=>role_name}])
      Role.transaction do 
        @role.prohibited_controllers.clear
        @role.prohibited_actions.clear
        @role.prohibitions.clear
        logger.debug counter
        @prohibited_controller_array[counter].each { |cont_name|
          #logger.debug cont_name
          #logger.debug @prohibited_controller_array[counter]
          @prohib_cont = ProhibitedController.find(:first,:conditions=>["name= :name",{:name=>cont_name}])
          if @prohib_cont.nil?
            @prohib_cont = ProhibitedController.new(:name=>cont_name)
            @prohib_cont.save!
          end
          @role.prohibited_controllers << @prohib_cont
        }
        @prohibited_action_array[counter].each { |action_name|
          #logger.debug action_name
          #logger.debug @prohibited_action_array[counter]
          @prohib_action = ProhibitedAction.find(:first,:conditions=>["name= :name",{:name=>action_name}])
          if @prohib_action.nil?
            @prohib_action = ProhibitedAction.new(:name=>action_name)
            @prohib_action.save!
          end
          @role.prohibited_actions << @prohib_action
        }
        @prohibited_string_array[counter].each { |prohib_name|
          @prohib = Prohibition.find(:first,:conditions=>["name= :name",{:name=>prohib_name}])
          if @prohib.nil?
            @prohib = Prohibition.new(:name=>prohib_name)
            @prohib.save!
          end
          @role.prohibitions << @prohib
        }
        logger.debug "on to the next role"
        counter = counter+1
      end
    }
  end
  
  def make_web_color(params, red, green, blue, combined)
    final = ""
    [red, green, blue].each do |color_sym|
      color = params[color_sym].to_i.to_s(16)
      if color.length==1
        color = "0"+color
      end
      final = final+color
      params.delete color_sym
    end
    params[combined] = final
    return params
  end
  
end