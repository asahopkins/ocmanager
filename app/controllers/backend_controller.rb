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

class BackendController < ApplicationController
  skip_filter :login_required
  wsdl_service_name 'Backend'
  web_service_api EntityApi
  web_service_scaffold :invoke

  # TODO: something like on API tokens: filter_parameter_logging :password

  def find_entity_by_id(id, campaign_id, login, token)
    @user = validate(campaign_id, login, token)
    unless @user.nil?
      @entity = Entity.find(id)
      unless @entity
        raise "Record not found"
      end
      if @user.active_campaigns.include?(@entity.campaign_id) and @entity.campaign_id == campaign_id
        @return_entity = @entity.to_basic
        return @return_entity
      else
        raise "bad login"
      end
    else
      raise "bad login"
    end
  end

  def find_entities_by_name(value, limit, types, campaign_id, login, token)
    @user = validate(campaign_id, login, token)
    if @user.nil?
      raise 'bad login'
    end
    unless @user.active_campaigns.include?(campaign_id)
      raise 'bad login'
    end
    if types.nil?
      types = ["Person", "Organization", "OutsideCommittee"]
    end
    @entities = Entity.find(:all,:limit=>limit,:conditions=>["LOWER(name) LIKE :fragment AND type IN (:types) AND campaign_id = :campaign_id",{:fragment=>'%'+value.downcase.gsub(/\s+/,"%")+'%', :types=>types, :campaign_id=>campaign_id}],:order=>"name ASC")
    @return_entities = []
    @entities.each {|entity|
      @return_entities << entity.to_basic
      }
    return @return_entities
  end
  
  # redo this so that it brings in a struct (e.g. BasicEntity) and treasurer_id (how do we distinguish treasurer_ids?)
  # THIS SHOULDN'T BE USED
  def create_or_update_entity_from_fields(manager_id, treasurer_id, type, name, first_name, last_name, addr_line1, addr_line2, addr_city, addr_state, addr_ZIP, addr_ZIP_4, phone, fax, email, occupation, employer, federal_ID, state_ID, party)
    manager_id=="" ? manager_id = nil :
    treasurer_id == "" ? treasurer_id = nil : nil
    type == "" ? raise : nil
    name == "" ? raise : nil
    addr_line1 == "" ? addr_line1 = nil : nil
    addr_line2 == "" ? addr_line2 = nil : nil
    addr_city == "" ? addr_city = nil : nil
    addr_state == "" ? addr_state = nil : nil
    addr_ZIP == "" ? addr_ZIP = nil : addr_ZIP = addr_ZIP.to_i
    addr_ZIP_4 == "" ? addr_ZIP_4 = nil : addr_ZIP_4 = addr_ZIP_4.to_i
    phone == "" ? phone = nil : phone = to_numbers(phone)
    fax == "" ? fax = nil : fax = to_numbers(fax)
    email == "" ? email = nil : nil
    occupation == "" ? occupation = nil : nil
    employer == "" ? employer = nil : nil
    federal_ID == "" ? federal_ID = nil : nil
    state_ID == "" ? state_ID = nil : nil
    party == "" ? party = nil : nil
    @entity_hash = {:name=>name, :type=>type, :first_name=>first_name, :last_name=>last_name, :primary_phone=>"Primary", :primary_email=>"Primary", :primary_fax=>"Primary", :occupation=>occupation, :employer=>employer, :federal_ID=>federal_ID, :state_ID=>state_ID, :party=>party, :phones=>{"Primary"=>phone}, :emails=>{"Primary"=>email}, :faxes=>{"Primary"=>fax}}
    @address_hash = {:label=>"Primary", :line_1=>addr_line1, :line_2=>addr_line2, :city=>addr_city, :state=>addr_state, :zip=>addr_ZIP, :zip_4=>addr_ZIP_4}
    if manager_id.nil?
      logger.debug "create a new entity in Manager, and return its id"
      @address = Address.new(@address_hash)
      @entity = Entity.new(@entity_hash)
      @address.entity = @entity
      unless @address.save
        logger.debug "ERROR!"
      end
      @entity.primary_address = @address
      @entity.mailing_address = @address
      unless @entity.save
        logger.debug "ERROR!"
      end
      if type=="Person"
        @entity.update_attribute(:type,"Person") 
      elsif type=="Organization"
        @entity.update_attribute(:type,"Organization") 
      elsif type=="OutsideCommittee"
        @entity.update_attribute(:type,"OutsideCommittee") 
      else
        raise
      end
      return @entity.id
    else
      logger.debug "update an existing entity in Manager, if the id exists and corresponds to a user's campaign, otherwise create new.  Return entity id."
      @entity_hash.update({:id=>manager_id})
      @entity = Entity.find(:first,:conditions=>["id=:id",{:id=>manager_id}]) # add more :conditions to this when we do user login/campaign stuff
      if @entity.nil?
        logger.debug "create a new entity in Manager, and return its id"
        @address = Address.new(@address_hash)
        @entity = Entity.new(@entity_hash)
        @address.entity = @entity
        unless @address.save
          logger.debug "ERROR!"
        end
        @entity.primary_address = @address
        @entity.mailing_address = @address
        unless @entity.save
          logger.debug "ERROR!"
        end
        if type=="Person"
          @entity.update_attribute(:type,"Person") 
        elsif type=="Organization"
          @entity.update_attribute(:type,"Organization") 
        elsif type=="OutsideCommittee"
          @entity.update_attribute(:type,"OutsideCommittee") 
        else
          raise
        end
        return @entity.id
      else
        @entity_hash.update({:primary_phone=>"From_Remote", :primary_email=>"From_Remote", :primary_fax=>"From_Remote"})
        @address_hash.update({:label=>"From_Remote", :line_1=>addr_line1, :line_2=>addr_line2, :city=>addr_city, :state=>addr_state, :zip=>addr_ZIP, :zip_4=>addr_ZIP_4})
        @address = Address.new(@address_hash)
        @address.entity = @entity
        unless @address.save
          logger.debug "ERROR!"
        end
        @entity.update_attributes(@entity_hash)
        @entity.primary_address = @address
        @entity.mailing_address = @address
        @entity.phones["From_Remote"] = phone
        @entity.faxes["From_Remote"] = fax
        @entity.emails["From_Remote"] = email
        unless @entity.save
          logger.debug "ERROR!"
        end
        # change type??
        return @entity.id
      end
    end
  end
  
  # treasurer_id is not being used right now; will wait until treasurer is set up at the manager end
  # add info about _which_ treasurer?, plus user info
  def create_entity_from_struct(campaign_id, committee_id, basic_entity, login, token)
    @user = validate(campaign_id, login, token)
    if @user.nil?
      raise "bad login"
    end
    unless @user.active_campaigns.include?(campaign_id)
      raise "bad login"
    end
    logger.debug basic_entity.to_s
    logger.debug basic_entity.class
    logger.debug basic_entity["name"]
    @committee = Committee.find(committee_id)
    @campaign = Campaign.find(campaign_id)
    @entity_hash = {:campaign_id=>campaign_id, :name=>basic_entity["name"], :type=>basic_entity["type"], :first_name=>basic_entity["first_name"], :last_name=>basic_entity["last_name"], :occupation=>basic_entity["occupation"], :employer=>basic_entity["employer"], :federal_ID=>basic_entity["federal_ID"], :state_ID=>basic_entity["state_ID"], :party=>basic_entity["party"],}
    unless basic_entity["phone"].to_s==""
      @entity_hash.update({:primary_phone=>"From Remote", :phones=>{"From Remote"=>to_numbers(basic_entity["phone"].to_s)}})
    else
      @entity_hash.update({:phones=>{}})
    end
    unless basic_entity["fax"].to_s==""
      @entity_hash.update({:primary_fax=>"From Remote", :faxes=>{"From Remote"=>to_numbers(basic_entity["fax"].to_s)}})
    else
      @entity_hash.update({:faxes=>{}})
    end
    unless basic_entity["email"].to_s==""
      email_hash = {:label=>"From Remote",:address=>basic_entity["email"].to_s}
    end
    @address_hash = {:line_1=>basic_entity["addr_line1"], :line_2=>basic_entity["addr_line2"], :city=>basic_entity["addr_city"], :state=>basic_entity["addr_state"], :zip=>basic_entity["addr_ZIP"], :zip_4=>basic_entity["addr_ZIP_4"], :label=>"Primary"}
    @address = Address.new(@address_hash)
    if basic_entity["type"]=="Person"
      @entity = Person.new(@entity_hash)
    elsif basic_entity["type"]=="Organization"
      @entity = Organization.new(@entity_hash)
    elsif basic_entity["type"]=="OutsideCommittee"
      @entity = OutsideCommittee.new(@entity_hash)
    else
      raise "type error"
    end
    @address.entity = @entity
    Entity.transaction do
      Address.transaction do
        unless @address.save
          logger.debug "ERROR!"
        end
        @entity.primary_address_id = @address.id
        unless @entity.save
          logger.debug "ERROR!"
        end
        @entity.mailing_address_id = @address.id
        unless @entity.save
          logger.debug "ERROR!"
        end
        if @entity.class==Person
          @household = Household.new(:campaign_id=>@campaign.id)
          @household.save
          @entity.household = @household
        end
        if email_hash
          email_hash.update(:entity_id=>@entity.id)
          email = EmailAddress.new(email_hash)
          email.save!
          @entity.primary_email = email
        end
        @entity.save!
        @treasurer_entity = TreasurerEntity.new({:entity_id=>@entity.id, :treasurer_id=>basic_entity["id"].to_i, :committee_id=>committee_id})
        @treasurer_entity.save!
        #@entity.addresses << @address
        return @entity.id
      end
    end
  end
  
  def update_entity_from_struct(manager_id, campaign_id, committee_id, basic_entity, login, token) 
    @user = validate(campaign_id, login, token)
    if @user.nil?
      raise "bad login"
    end
    unless @user.active_campaigns.include?(campaign_id)
      raise "bad login"
    end
    @entity = Entity.find(:first,:conditions=>["id=:id AND campaign_id = :campaign_id",{:id=>manager_id, :campaign_id=>campaign_id}]) # add more :conditions to this when we do user login/campaign stuff
    @entity_hash = {:name=>basic_entity["name"], :type=>basic_entity["type"], :first_name=>basic_entity["first_name"], :last_name=>basic_entity["last_name"],  :occupation=>basic_entity["occupation"], :employer=>basic_entity["employer"], :federal_ID=>basic_entity["federal_ID"], :state_ID=>basic_entity["state_ID"], :party=>basic_entity["party"]}
    @address_hash = {:label=>"From Remote "+Time.now.to_s, :line_1=>basic_entity["addr_line1"], :line_2=>basic_entity["addr_line2"], :city=>basic_entity["addr_city"], :state=>basic_entity["addr_state"], :zip=>basic_entity["addr_ZIP"], :zip_4=>basic_entity["addr_ZIP_4"]}
    unless @entity.nil?
      # what if we're changing addresses between two already in the database, and we risk throwing away address info....???
      # perhaps create a new address, and make it the primary, but keep the other one around....
      Entity.transaction do
        Address.transaction do
          @address = Address.new(@address_hash)
          @address.entity = @entity
          @entity.update_attributes(@entity_hash)
          unless @entity.primary_address.same_as(@address)
            @address.save!
            address_saved = true
            @entity.primary_address = @address
            @entity.save!
          end
          unless @entity.mailing_address.same_as(@address)
            unless address_saved 
              @address.save!
            end
            @entity.mailing_address = @address
            @entity.save!
          end
          label = "From Remote "+Time.now.to_s
          unless basic_entity["phone"] == "" or basic_entity["phone"].nil? or @entity.primary_phone_number == to_numbers(basic_entity["phone"])
            @entity.primary_phone = label
            @entity.phones[label] = basic_entity["phone"]
          end
          unless basic_entity["fax"] == "" or basic_entity["fax"].nil? or @entity.primary_fax_number == to_numbers(basic_entity["fax"])
            @entity.primary_fax = label
            @entity.faxes[label] = basic_entity["fax"]
          end
          unless basic_entity["email"] == "" or basic_entity["email"].nil? or @entity.primary_email_address == basic_entity["email"]
            email = EmailAddress.new(:label=>label, :address=>basic_entity["email"], :entity_id=>@entity.id)
            email.save!
            @entity.primary_email = email
          end
          @entity.save!
          if basic_entity["type"]=="Person"
            @entity.update_attribute(:type,"Person") 
          elsif basic_entity["type"]=="Organization"
            @entity.update_attribute(:type,"Organization") 
          elsif basic_entity["type"]=="OutsideCommittee"
            @entity.update_attribute(:type,"OutsideCommittee") 
          else
            raise "type error"
          end
          @treasurer_entity = TreasurerEntity.find(:first, :conditions=>["entity_id=:entity_id AND committee_id=:committee_id", {:entity_id=>@entity.id, :committee_id=>committee_id}])
          unless @treasurer_entity.nil?
            @treasurer_entity.update_attribute(:treasurer_id,basic_entity["id"])
          else
            @treasurer_entity = TreasurerEntity.new({:entity_id=>@entity.id, :treasurer_id=>basic_entity["id"].to_i, :committee_id=>committee_id})
            @treasurer_entity.save!
          end          
        end
      end
    else
      raise "Entity not found"
    end
    return @entity.id
  end
  
#  def add_entity_treasurer_id(manager_id, treasurer_id, login, token)
#    @entity = Entity.find(:first,:conditions=>["id=:id",{:id=>manager_id}]) # add more :conditions to this when we do user login/campaign stuff
#    # update the treasurer_id, however that gets set up
#    return @entity.id
#  end
  
end
