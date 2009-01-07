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

class EntitiesController < ApplicationController
  layout  'manager'
  require 'csv'
  
  before_filter :get_campaign
  
  before_filter :load_entity_and_check_campaign, :except=>[:list, :new, :create, :search, :advanced_search, :search_results, :upload_file, :save_file_and_redirect, :import_from_csv, :process_csv_data, :update_cart, :show_cart, :add_tag_to_cart, :autocomplete_for_sign_in, :load_new_entity_form]
  
  before_filter :strip_white_space, :only=>[:create, :update, :update_partial, :update_custom, :update_name, :update_address, :update_phones, :update_faxes, :update_website, :update_skills, :self_update, :add_address, :add_phone, :add_fax]
  #before_filter :check_campaign, :only=>[:list, :new, :create, :advanced_search, :upload_file, :save_file_and_redirect, :import_from_csv, :process_csv_data]
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update, :save_file_and_redirect, :process_csv_data, :update_cart, :request_delete ], :redirect_to => { :action => :list }

  def list
    cond = EZ::Where::Condition.new :entities
    cond.campaign_id == @campaign.id
    if @tag_name = params[:id]
      if @tag_name.length == 1
        letter = @tag_name+'%'
        person_cond = EZ::Where::Condition.new :entities do
          # person and last name
          sub :inner=>:and, :outer=>:or do
            type == 'Person'
            last_name.nocase =~ letter
          end
          # organization and name
          sub :inner=>:and, :outer=>:or do
            type === ['Organization','OutsideCommittee']
            name.nocase =~ letter
          end
        end
        cond.append person_cond
        # TODO: reorder using entity.sort_by_name
      else
        @tag = Tag.find_by_name_and_campaign_id(@tag_name, @campaign.id)
        if @tag
          @entities = Entity.paginate :per_page => 25, :order=>"last_name ASC, name ASC, first_name ASC", :include=>[:primary_address,:taggings,:primary_email], :page=>params[:page], :conditions=>["taggings.tag_id = :tag",{:tag=>@tag.id}]
          @count = @entities.total_entries
          return
        else
          flash[:warning] = "Tag '"+ @tag_name + "' does not exist. Here is the whole list."
          redirect_to :action=>"list", :params=>{:id=>nil}, :protocol=>@@protocol
        end
      end
    end
    @entities = Entity.paginate :per_page => 25, :order=>"last_name ASC, name ASC, first_name ASC", :conditions=>cond.to_sql, :include=>:primary_address, :page=>params[:page]
    @count = @entities.total_entries
  end

  def show
    if @mobile
      render :action=>"show_mobile", :layout=>"mobile"
      return
    else
      @can_edit = current_user.can_edit_entities?(@campaign)
      @can_edit_groups = current_user.edit_groups?(@campaign)
      @can_see_financial = current_user.can_see_financial?(@campaign)
      @recent_texts = @campaign.get_recent_texts
      @recent_events = @campaign.get_recent_events
      @rsvps = Rsvp.paginate :per_page => 5, :order=>"campaign_events.start_time DESC, updated_at DESC", :conditions=>["rsvps.entity_id=:entity", {:entity=>@entity.id}], :include=>:campaign_event, :page=>1
      @contact_events = ContactEvent.paginate :per_page => 5, :order=>"when_contact DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>1
      @volunteer_events = VolunteerEvent.paginate :per_page => 5, :order=>"start_time DESC, end_time DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>1
    end
  end

  def search
    if request.method==:post
      includes = [:primary_address]
      session[:search_params] = Hash.new
      session[:search_params][:entity] = Hash.new
      content = params[:search][:content].to_s.gsub(/[*]/,'%')
      if content == params[:search][:content]
        search = "%"+content+"%"
      else
        search = content
      end
      cond = EZ::Where::Condition.new :entities
      camp = @campaign.id
      cond.campaign_id == camp
      if search_type = params[:search][:type]
        if search_type == "Person"
          cond.type == search_type
        elsif search_type == "Organizations"
          cond.type === ["Organization", "OutsideCommittee"]
        end
      end
      if params[:search][:field]=="Name"
        session[:search_params][:entity][:name] = params[:search][:content]
        cond_search = EZ::Where::Condition.new :entities do
          name.nocase =~ search
        end
      elsif params[:search][:field]=="Address"
        session[:search_params][:entity][:address_any_field_flag] = "Includes"
        session[:search_params][:entity][:address_any_field] = params[:search][:content]
        cond_search = EZ::Where::Condition.new :addresses do
          any_of(:line_1, :line_2, :city, :state, :zip).nocase =~ search
        end
      elsif params[:search][:field]=="Phone"
        session[:search_params][:entity][:phone_number_flag] = "Includes"
        session[:search_params][:entity][:phone_number] = params[:search][:content]
        search = "%"+to_numbers(content)+"%"
        #logger.debug search
        cond_search = EZ::Where::Condition.new :entities do
          phones =~ search
        end
      elsif params[:search][:field]=="Email"
        session[:search_params][:entity][:email_address_flag] = "Includes"
        session[:search_params][:entity][:email_address] = params[:search][:content]
        search = "%"+params[:search][:content].to_s+"%"
        cond_search = EZ::Where::Condition.new :email_addresses do
          address.nocase =~ search
        end
        includes << :primary_email
      else
        cond_search = EZ::Where::Condition.new
      end

      cond.append cond_search
      session[:includes] = includes
      session[:search_cond] = cond
    else
      cond = session[:search_cond]
    end
    @count = Entity.count('id',:include=>includes, :conditions=>cond.to_sql)

    if @count == 1
      @entity = Entity.find(:first,:include=>includes, :conditions=>cond.to_sql)
      redirect_to :action=>"show", :id=>@entity.id, :protocol=>@@protocol
      return
    end
#    logger.debug cond.to_sql.to_s
    if @mobile
      @entities = Entity.paginate :include=>includes, :per_page => 10, :order=>"last_name, name, first_name ASC", :conditions=>cond.to_sql, :page=>params[:page]
      render :action=>"search_mobile", :layout=>"mobile"
    else
      @entities = Entity.paginate :include=>includes, :per_page => 25, :order=>"last_name, name, first_name ASC", :conditions=>cond.to_sql, :page=>params[:page]
      render :action=>"search_results"
    end
  end

  def advanced_search

  end


  def search_results
    if request.method==:post
      session[:search_params] = Hash.new
      session[:search_params][:entity] = params[:entity]
      session[:search_params][:custom_field] = params[:custom_field]
      #logger.debug params[:entity]
      
      includes = [:primary_address]
      joins = ""
      # having = []
      # aggregate = []
      cond = EZ::Where::Condition.new :entities
      if params[:campaign_id]
        @campaign = Campaign.find(params[:campaign_id])
        if current_user.active_campaigns.include?(@campaign.id)
        else
          @campaign = nil
          render :partial=>"user/not_available"
        end
        camp = @campaign.id
        cond.campaign_id == camp
      else
        camp = current_user.current_campaign
        cond.campaign_id == camp
      end

      #type
      if params[:entity][:class] == "Person"
        cond.clause(:type)=="Person"
      elsif params[:entity][:class] == "Organization"
        cond.clause(:type)===["Organization","OutsideCommittee"]
      elsif params[:entity][:class] == "OutsideCommittee"
        cond.clause(:type)=="OutsideCommittee"
      elsif params[:entity][:class] == "Any"
        cond.clause(:type)===["Person","Organization","OutsideCommittee"]
      end

      #name
      if params[:entity][:title].to_s != ""
        search = params[:entity][:title].gsub(/[*]/,'%')
        search_2 = search+'.'
        cond_title = EZ::Where::Condition.new :entities, :inner=>:or do
          title.nocase =~ search
          title.nocase =~ search_2
        end
        cond.append cond_title
      end
      if params[:entity][:first_name].to_s != ""
        search = params[:entity][:first_name].gsub(/[*]/,'%')
        cond.first_name.nocase =~ search
      end
      if params[:entity][:middle_name].to_s != ""
        search = params[:entity][:middle_name].gsub(/[*]/,'%')
        cond.middle_name.nocase =~ search
      end
      if params[:entity][:last_name].to_s != ""
        search = params[:entity][:last_name].gsub(/[*]/,'%')
        cond.last_name.nocase =~ search
      end
      if params[:entity][:name].to_s != ""
        search = params[:entity][:name].gsub(/[*]/,'%')
        cond.name.nocase =~ search
      end
      
      #address
      if params[:entity][:address_which]=="All"
        address_table = :addresses_entities #addresses_entities
        includes << :addresses
      elsif params[:entity][:address_which]=="Primary"
        # entity.primary_address_id = address.id
        address_table = :addresses #addresses
      end
      
      
      address_cond = EZ::Where::Condition.new
      cond_line_1 = build_text_search(params[:entity][:address_line_1_flag], params[:entity][:address_line_1], 'line_1', address_table)
      address_cond.append cond_line_1
      # line_2
      cond_line_2 = build_text_search(params[:entity][:address_line_2_flag], params[:entity][:address_line_2], 'line_2', address_table)
      address_cond.append cond_line_2
      # city
      cond_city = build_text_search(params[:entity][:address_city_flag], params[:entity][:address_city], 'city', address_table)
      address_cond.append cond_city
      # state
      cond_state = build_text_search(params[:entity][:address_state_flag], params[:entity][:address_state], 'state', address_table)
      address_cond.append cond_state
      # zip
      cond_zip = build_text_search(params[:entity][:address_zip_flag], params[:entity][:address_zip], 'zip', address_table)
      address_cond.append cond_zip
      # any field
      if params[:entity][:address_any_field_flag] == "Includes"
        search = '%'+params[:entity][:address_any_field]+'%'
        cond_any = EZ::Where::Condition.new address_table do
          sub :inner=>:or do
            line_1.nocase =~ search
            line_2.nocase =~ search
            city.nocase =~ search
            state.nocase =~ search
            zip.nocase =~ search
          end
        end
        address_cond.append cond_any
      elsif params[:entity][:address_any_field_flag] == "Matches"
        search = params[:entity][:address_any_field]
        cond_any = EZ::Where::Condition.new address_table do
          sub :inner=>:or do
            line_1.nocase == search
            line_2.nocase == search
            city.nocase == search
            state.nocase == search
            zip.nocase == search
          end
        end
        address_cond.append cond_any
      end

      cond.append address_cond
      
      #phone
      if params[:entity][:phone_number_flag] == "Includes"
        search = '%'+to_numbers(params[:entity][:phone_number])+'%'
        cond_phone = EZ::Where::Condition.new :entities do
          phones =~ search
        end
        cond.append cond_phone
      elsif params[:entity][:phone_number_flag] == "Not"
        search = '%'+to_numbers(params[:entity][:phone_number])+'%'
        cond_phone = EZ::Where::Condition.new :entities do
          phones! =~ search
          phones! == :null
          phones! =~ "--- {}%"
        end
        cond.append cond_phone   
      end
      #fax
      if params[:entity][:fax_number_flag] == "Includes"
        search = '%'+to_numbers(params[:entity][:fax_number])+'%'
        cond_fax = EZ::Where::Condition.new :entities do
          faxes =~ search
        end
        cond.append cond_fax
      elsif params[:entity][:fax_number_flag] == "Not"
        search = '%'+to_numbers(params[:entity][:fax_number])+'%'
        cond_fax = EZ::Where::Condition.new :entities do
          faxes! =~ search
          faxes! == :null
          faxes! =~ "--- {}%"
        end
        cond.append cond_fax   
      end    
      #email
      if params[:entity][:email_address_flag] == "Includes"
        includes << :email_addresses
        search = '%'+params[:entity][:email_address]+'%'
        cond_email = EZ::Where::Condition.new :email_addresses do
          address.case_insensitive =~ search
        end
        cond.append cond_email
      elsif params[:entity][:email_address_flag] == "Not"
        includes << :email_addresses
        search = '%'+params[:entity][:email_address]+'%'
        cond_email = EZ::Where::Condition.new :email_addresses do
          address! =~ search
          address! == :null
        end
        cond.append cond_email   
      elsif params[:entity][:email_address_flag] == "Matches"
        includes << :email_addresses
        search = params[:entity][:email_address]
        if search==""
          cond_email = EZ::Where::Condition.new :email_addresses do
            address == :null
          end
          cond_email.append "email_addresses.address=''", :or
        else
          cond_email = EZ::Where::Condition.new :email_addresses do
            address == search
            address! == :null
          end
        end
        cond.append cond_email   
      end
      
      # bad emails
      if params[:entity][:email_valid_flag] == "Matches"
        includes << :email_addresses
        if params[:entity][:email_valid] == "true"
          search = false
        else
          search = true
        end
        cond_valid_email = EZ::Where::Condition.new :email_addresses
        cond_valid_email.clause(:invalid) == search
        cond.append cond_valid_email
      end
      
      #website
      cond_website = build_text_search(params[:entity][:website_flag], params[:entity][:website], 'website', :entities)
      cond.append cond_website
      
      # time to reach
      cond_time_to_reach = build_text_search(params[:entity][:time_to_reach_flag], params[:entity][:time_to_reach], 'time_to_reach', :entities)
      cond.append cond_time_to_reach

      #contact flags
      if params[:entity][:receive_phone_flag] == "Matches"
        if params[:entity][:receive_phone] == "true"
          search = true
        else
          search = false
        end
        cond_phone_flag = EZ::Where::Condition.new :entities
        cond_phone_flag.clause(:receive_phone) == search
        cond.append cond_phone_flag
      elsif params[:entity][:receive_phone_flag].to_s == "Not"
        if params[:entity][:receive_phone] == "true"
          search = false
        else
          search = true
        end
        cond_phone_flag = EZ::Where::Condition.new :entities do
          sub :inner=>:or do
            receive_phone == search
            receive_phone == :null
          end
        end
        cond.append cond_phone_flag   
      end
      if params[:entity][:receive_email_flag] == "Matches"
        if params[:entity][:receive_email] == "true"
          search = true
        else
          search = false
        end
        cond_email_flag = EZ::Where::Condition.new :entities
        cond_email_flag.clause(:receive_email) == search
        cond.append cond_email_flag
      elsif params[:entity][:receive_email_flag] == "Not"
        if params[:entity][:receive_email] == "true"
          search = false
        else
          search = true
        end
        cond_email_flag = EZ::Where::Condition.new :entities do
          sub :inner=>:or do
            receive_email == search
            receive_email == :null
          end
        end
        cond.append cond_email_flag   
      end

      
      #voter info
      # VOTER ID
      cond_voter_ID = build_text_search(params[:entity][:voter_ID_flag], params[:entity][:voter_ID], 'voter_ID', :entities)
      cond.append cond_voter_ID
      # PRECINCT
      cond_precinct = build_text_search(params[:entity][:precinct_flag], params[:entity][:precinct], 'precinct', :entities)
      cond.append cond_precinct
      # REGISTERED PARTY
      cond_regd_party = build_text_search(params[:entity][:regd_party_flag], params[:entity][:registered_party], 'registered_party', :entities)
      cond.append cond_regd_party

      #committee info
      
      # federal ID
      cond_federal_ID = build_text_search(params[:entity][:federal_ID_flag], params[:entity][:federal_ID], 'federal_ID', :entities)
      cond.append cond_federal_ID
      # state ID
      cond_state_ID = build_text_search(params[:entity][:state_ID_flag], params[:entity][:state_ID], 'state_ID', :entities)
      cond.append cond_state_ID
      # party or not
      if params[:entity][:party_flag] == "Matches"
        if params[:entity][:party] == "true"
          search = true
        else
          search = false
        end
        cond_party_flag = EZ::Where::Condition.new :entities
        cond_party_flag.clause(:party) == search
        cond.append cond_party_flag
      end
    
      
      #other info
      # referred by
      cond_referred_by = build_text_search(params[:entity][:referred_flag], params[:entity][:referred_by], 'referred_by', :entities)
      cond.append cond_referred_by
      # occupation
      cond_occupation = build_text_search(params[:entity][:occupation_flag], params[:entity][:occupation], 'occupation', :entities)
      cond.append cond_occupation
      # employer
      cond_employer = build_text_search(params[:entity][:employer_flag], params[:entity][:employer], 'employer', :entities)
      cond.append cond_employer
      # comments
      cond_comments = build_text_search(params[:entity][:comments_flag], params[:entity][:comments], 'comments', :entities)
      cond.append cond_comments
      # created_at
      if params[:entity][:created_after_flag] == "After"
        search = Date.civil(params[:entity]['created_after(1i)'].to_i, params[:entity]['created_after(2i)'].to_i, params[:entity]['created_after(3i)'].to_i).to_time
        cond_creation = EZ::Where::Condition.new :entities do
          created_at > search
        end
        cond.append cond_creation
      end
      # updated_at
      if params[:entity][:updated_after_flag] == "After"
        search = Date.civil(params[:entity]['updated_after(1i)'].to_i, params[:entity]['updated_after(2i)'].to_i, params[:entity]['updated_after(3i)'].to_i).to_time
        cond_ent_update = EZ::Where::Condition.new :entities do
          updated_at > search
          sub :table_name=>address_table, :outer=>:or do
            updated_at > search
          end
        end
        cond.append cond_ent_update
      end

      # delete requested
      if params[:entity][:delete_requested_flag] == "Matches"
        if params[:entity][:delete_requested] == "true"
          search = true
        else
          search = false # this doesn't really work because we want it to catch those with NULL as well
        end
        cond_delete_flag = EZ::Where::Condition.new :entities
        cond_delete_flag.clause(:delete_requested) == search
        cond.append cond_delete_flag
      end

      #tags
      if params[:entity][:tags_flag] == "Includes"
        search_tag = params[:entity][:tags]
        cond_taggings = EZ::Where::Condition.new :tags do
          name.nocase == search_tag
        end
        
#        tagged_entities = Entity.find_tagged_with(params[:entity][:tags])
#        unless tagged_entities.empty?
#          a = []
#          tagged_entities.each do |entity|
#            a << entity.id
#          end
#          cond_tags = EZ::Where::Condition.new :entities do
#            id === a
#          end
#        end
        includes << :tags
        cond.append cond_taggings
      end
      
      #followup_required
      if params[:entity][:followup_required_flag] == "Matches"
        if params[:entity][:followup_required] == "true"
          search = true
        else
          search = false
        end
        cond_followup_flag = EZ::Where::Condition.new :entities
        cond_followup_flag.clause(:followup_required) == search
        cond.append cond_followup_flag
      elsif params[:entity][:followup_required_flag].to_s == "Not"
        if params[:entity][:followup_required] == "true"
          search = false
        else
          search = true
        end
        cond_followup_flag = EZ::Where::Condition.new :entities do
          sub :inner=>:or do
            followup_required == search
            followup_required == :null
          end
        end
        cond.append cond_followup_flag   
      end
      
      # contact_text recipients
      if params[:entity][:received_text] != ""
        includes << :contact_events
        search = params[:entity][:received_text]
        cond_contact_event = EZ::Where::Condition.new :contact_events do
            contact_text_id == search
        end
        cond.append cond_contact_event   
      end

      #volunteer interests
      if params[:entity][:interests_flag] =="Includes_any"
        search = params[:entity][:volunteer_interests].to_a
        if search.size >= 1
          cond_interests = EZ::Where::Condition.new :volunteer_tasks do
            id === search
          end
          includes << :volunteer_interests
          cond.append cond_interests
        else
          flash[:warning] = "No volunteer interests were selected"
        end
      end
      
      #skills
      cond_skills = build_text_search(params[:entity][:skills_flag], params[:entity][:skills], 'skills', :entities)
      cond.append cond_skills
      
      #languages
      cond_languages = build_text_search(params[:entity][:language_flag], params[:entity][:languages], 'languages', :entities)
      cond.append cond_languages
            
      if current_user.can_see_financial?(@campaign)
        #contributions
        if params[:local_contribution][:flag].to_s != ""
          search = params[:local_contribution][:amount].to_f
          start_date = Date.new(params[:local_contribution]['start_date(1i)'].to_i, params[:local_contribution]['start_date(2i)'].to_i, params[:local_contribution]['start_date(3i)'].to_i).to_time
          end_date = Date.new(params[:local_contribution]['end_date(1i)'].to_i, params[:local_contribution]['end_date(2i)'].to_i, params[:local_contribution]['end_date(3i)'].to_i).to_time
          recip = params[:local_contribution][:recipient].to_s.upcase
          recip = "" if recip == "ANYONE"
          recip = "%"+recip+"%"
          if params[:local_contribution][:flag].to_s == "Total"
            contrib_entities = []
            # find all contributions between these dates, for this campaign
            contributions = Contribution.find(:all, :include=>:entity, :conditions=>["contributions.date > :start_date AND contributions.date < :end_date AND entities.campaign_id = :campaign AND UPPER(contributions.recipient) LIKE :recip",{:start_date=>start_date, :end_date=>end_date,:campaign=>@campaign.id, :recip=>recip}])
            # loop through them, making sums by entity
            tmp_hash = {}
            contributions.each do |contrib|
              tmp_hash[contrib.entity_id] = tmp_hash[contrib.entity_id].to_f + contrib.amount
              if tmp_hash[contrib.entity_id] >= search
                contrib_entities << contrib.entity_id
              end
            end
            contrib_entities.uniq!
            # search for those entity ids
            if contrib_entities.length > 0
              cond_contributions = EZ::Where::Condition.new :entities do
                id === contrib_entities
              end
            else
              cond_contributions = EZ::Where::Condition.new :entities do
                id == -1
              end              
            end
          elsif params[:local_contribution][:flag].to_s == "One"
            includes << :contributions
            cond_contributions = EZ::Where::Condition.new :contributions do
              amount >= search
              date >= start_date
              date <= end_date
              recipient.nocase =~ recip
            end
          elsif params[:local_contribution][:flag].to_s == "Less"
            contrib_entities = []
            # find all contributions between these dates, for this campaign
            contributions = Contribution.find(:all, :include=>:entity, :conditions=>["contributions.date > :start_date AND contributions.date < :end_date AND entities.campaign_id = :campaign AND UPPER(contributions.recipient) LIKE :recip",{:start_date=>start_date, :end_date=>end_date,:campaign=>@campaign.id, :recip=>recip}])
            # loop through them, making sums by entity
            tmp_hash = {}
            contributions.each do |contrib|
              tmp_hash[contrib.entity_id] = tmp_hash[contrib.entity_id].to_f + contrib.amount
            end
            @campaign.entities.each do |entity|
              if tmp_hash[entity.id].nil? or tmp_hash[entity.id] < search
                contrib_entities << entity.id
              end
            end
            # contrib_entities.uniq!
            # search for those entity ids
            if contrib_entities.length > 0
              cond_contributions = EZ::Where::Condition.new :entities do
                id === contrib_entities
              end
            else
              cond_contributions = EZ::Where::Condition.new :entities do
                id == -1
              end              
            end              
          end
          cond.append cond_contributions
        end
                
       # remote contributions (Treasurer)
        if params[:remote_contribution]
          if params[:remote_contribution][:flag].to_s != ""
            search = params[:remote_contribution][:value].to_f
            start_date = Date.new(params[:remote_contribution]['start_date(1i)'].to_i, params[:remote_contribution]['start_date(2i)'].to_i, params[:remote_contribution]['start_date(3i)'].to_i)
            end_date = Date.new(params[:remote_contribution]['end_date(1i)'].to_i, params[:remote_contribution]['end_date(2i)'].to_i, params[:remote_contribution]['end_date(3i)'].to_i)
            local_ids = []
            @campaign.committees.each do |committee|
              unless current_user.treasurer_info.nil? or current_user.treasurer_info[committee.id].nil?  or committee.treasurer_api_url.to_s == ""
                treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,committee.treasurer_api_url)
                ids = []
                if params[:remote_contribution][:flag].to_s == "Total"
                  ids = treasurer.get_entities_by_finances_and_date(current_user.treasurer_info[committee.id][0], current_user.treasurer_info[committee.id][1], committee.treasurer_id, start_date, end_date, search, false, true, true)
                elsif params[:remote_contribution][:flag].to_s == "One"
                  ids = treasurer.get_entities_by_finances_and_date(current_user.treasurer_info[committee.id][0], current_user.treasurer_info[committee.id][1], committee.treasurer_id, start_date, end_date, search, true, true, true)
                end
                unless ids.empty?
                  treasurer_entities = TreasurerEntity.find(:all, :conditions=>["committee_id = #{committee.id} AND treasurer_id IN (:remote_ids)",{:remote_ids=>ids}])
                  treasurer_entities.each do |te|
                    local_ids << te.entity_id
                  end
                end
              else
                #no search, doesn't have any treasurer login info
              end
            end
            if local_ids.length > 0
              cond_remote_contributions = EZ::Where::Condition.new :entities do
                id === local_ids
              end
            else
              cond_contributions = EZ::Where::Condition.new :entities do
                id == -1
              end                          
            end
            cond.append cond_remote_contributions
          end
        end
      end
      #custom_fields
      @campaign.custom_fields.each do |field|
        table_alias = "cfv_#{field.id}"
        table_alias_sym = table_alias.to_sym
        if params[:custom_field][:flag]
          if params[:custom_field][:flag][field.id.to_s].to_s == "Includes"
            search = '%'+params[:custom_field][field.id.to_s][:value].to_s+'%'
            cond_custom_field = EZ::Where::Condition.new table_alias_sym do
              custom_field_id == field.id
              value =~ search
            end
          elsif params[:custom_field][:flag][field.id.to_s].to_s == "Matches"
            if params[:custom_field][field.id.to_s][:value] == "true"
              search = true
            elsif params[:custom_field][field.id.to_s][:value] == "false"
              search = false
            else
              search = params[:custom_field][field.id.to_s][:value].to_s
            end
            if search == "" #this will miss entities that don't have the custom_field_value assigned at all
              cond_match_field = EZ::Where::Condition.new table_alias_sym do
                custom_field_id == field.id
              end
              cond_custom_field = EZ::Where::Condition.new table_alias_sym do
                value == :null
              end
              cond_custom_field.append "#{table_alias}.value = ''", :or
              cond_custom_field.append cond_match_field
            else
              cond_custom_field = EZ::Where::Condition.new table_alias_sym do
                custom_field_id == field.id
                value == search
              end
            end
            #cond.append cond_custom_field          
          elsif params[:custom_field][:flag][field.id.to_s].to_s == "Not"
            if params[:custom_field][field.id.to_s][:value] == "true" and field.field_type=="Bool"
              search = false
            elsif params[:custom_field][field.id.to_s][:value] == "false" and field.field_type=="Bool"
              search = true
            else
              search = '%'+params[:custom_field][field.id.to_s][:value].to_s+'%'
            end
            if search == '%%' # 'does not include ""; interpret as "not blank"'
              cond_custom_field = EZ::Where::Condition.new table_alias_sym do
                custom_field_id == field.id
                value! == :null
              end
              cond_custom_field.append "#{table_alias}.value != ''", :and
            elsif field.field_type=="Bool" and (search==true or search==false)
              cond_custom_field = EZ::Where::Condition.new table_alias_sym do
                custom_field_id == field.id
                sub :inner=>:or do
                  value == search
                  value == :null
                end
              end
            else
              cond_custom_field = EZ::Where::Condition.new table_alias_sym do
                custom_field_id == field.id
                value! =~ search
              end
            end
            #cond.append cond_custom_field          
  #        elsif params[:custom_field][:flag][field.id.to_s] == "Not_match"
  #          search = params[:custom_field][field.id.to_s][:value].to_s
  #          join << :custom_field_values
  #          if search == ""
  #            cond_custom_field = EZ::Where::Condition.new table_alias_sym do
  #              custom_field_id == field.id
  #              value! == :null
  #            end
  #            cond_custom_field.append "#{table_alias}.value != ''", :and
  #          else
  #            cond_custom_field = EZ::Where::Condition.new table_alias_sym do
  #              custom_field_id == field.id
  #              value! == search
  #            end
  #          end
  #          #cond.append cond_custom_field
          elsif params[:custom_field][:flag][field.id.to_s].to_s == "Greater_than"
            search = params[:custom_field][field.id.to_s][:value].to_f
            cond_custom_field = EZ::Where::Condition.new table_alias_sym do
              custom_field_id == field.id
              value >= search
            end
            #cond.append cond_custom_field       
          elsif params[:custom_field][:flag][field.id.to_s].to_s == "Less_than"
            search = params[:custom_field][field.id.to_s][:value].to_f
            cond_custom_field = EZ::Where::Condition.new table_alias_sym do
              custom_field_id == field.id
              value < search
              value! == :null
            end
            cond_custom_field.append "#{table_alias}.value != ''"
            #cond.append cond_custom_field       
          end
          unless params[:custom_field][:flag][field.id.to_s].to_s==""
            joins << " LEFT JOIN custom_field_values #{table_alias} ON #{table_alias}.entity_id = entities.id "
            #includes << :custom_field_values
  #          custom_field_conditions << cond_custom_field
  #          field_values = CustomFieldValue.find(:all,:conditions=>cond_custom_field.to_sql)
  #          entity_ids = []
  #          field_values.each do |field_value|
  #            entity_ids << field_value.entity_id
  #          end
  #          cond.id === entity_ids
            cond.append cond_custom_field
          end
        end
      end
      
      if params[:group_membership][:flag] == "Member"
        search = params[:group_membership][:id]
        includes << :group_memberships
        cond_group_membership = EZ::Where::Condition.new :group_memberships
        cond_group_membership.clause(:group_id) == search
        cond.append cond_group_membership
      end
      
      # VOLUNTEER HISTORY #
      if params[:volunteer_history][:flag].to_s != ""
        time = params[:volunteer_history][:hours].to_f
        start_date = Date.new(params[:volunteer_history]['start_date(1i)'].to_i, params[:volunteer_history]['start_date(2i)'].to_i, params[:volunteer_history]['start_date(3i)'].to_i).to_time
        end_date = Date.new(params[:volunteer_history]['end_date(1i)'].to_i, params[:volunteer_history]['end_date(2i)'].to_i, params[:volunteer_history]['end_date(3i)'].to_i).to_time
        end_date = end_date.tomorrow.midnight
        tasks = params[:volunteer_history][:tasks].to_a
        if tasks.include?("ANY_TASK")
          tasks = []
          @campaign.volunteer_tasks.each do |task|
            tasks << task.id
          end
        end
        if tasks.size >= 1
          volunteer_events = VolunteerEvent.find(:all, :include=>:entity, :conditions=>["volunteer_events.volunteer_task_id IN (:tasks) AND volunteer_events.start_time > :start_date AND volunteer_events.end_time < :end_date AND entities.campaign_id = :campaign",{:tasks=>tasks, :start_date=>start_date, :end_date=>end_date, :campaign=>@campaign.id}])
        else
          volunteer_events = []
          flash[:warning] = "No volunteer tasks were selected for the history."
        end
        all_possible_entity_ids = []
        volunteer_events.each do |event|
          all_possible_entity_ids << event.entity_id
        end
        all_possible_entity_ids.uniq!
        search_entity_ids = []
        all_possible_entity_ids.each do |entity_id|
          tot_time = 0
          entity_events = volunteer_events.find_all {|event| event.entity_id == entity_id}
          entity_events.each do |event|
            tot_time = tot_time + event.duration.to_f/60.0
            volunteer_events = volunteer_events - [event]
          end
          if tot_time >= time
            search_entity_ids << entity_id
          end
        end
        search_entity_ids.uniq!
        if search_entity_ids.length > 0
          cond_volunteer_history = EZ::Where::Condition.new :entities do
            id === search_entity_ids
          end
        else
          cond_volunteer_history = EZ::Where::Condition.new :entities do
            id == -1
          end
        end
        cond.append cond_volunteer_history
      end
      

      
      includes.uniq!
      session[:includes] = includes

      session[:search_cond] = cond
      logger.debug session[:search_cond].to_sql
      session[:joins] = joins

      @entities = Entity.paginate :per_page => 25, :order=>"entities.last_name, entities.name, entities.first_name ASC", :conditions=>cond.to_sql, :include=>includes, :joins=>joins, :page=>params[:page]
      @count = @entities.total_entries
      # @count = Entity.count('entities.id', :conditions=>cond.to_sql, :include=>includes, :joins=>joins)
      if @count == 1
        entity = Entity.find(:first, :order=>"entities.last_name, entities.name, entities.first_name ASC", :conditions=>cond.to_sql, :include=>includes, :joins=>joins)
        redirect_to :action=>"show", :id=>entity.id, :protocol=>@@protocol
        return
      end
      
    else
      if params[:campaign_id]
        @campaign = Campaign.find(params[:campaign_id])
        if current_user.active_campaigns.include?(@campaign.id)
        else
          @campaign = nil
          render :partial=>"user/not_available"
        end
      end
      includes = session[:includes]
      session[:search_cond] ||= EZ::Where::Condition.new
      logger.debug session[:search_cond].to_sql
      cond = session[:search_cond]
      # group_clause = session[:group_clause]
      joins = session[:joins]
      # aggregate = session[:aggregate]
      
      @entities = Entity.paginate :per_page => 25, :order=>"entities.last_name, entities.name, entities.first_name ASC", :conditions=>cond.to_sql, :include=>includes, :joins=>joins, :page=>params[:page]
      @count = @entities.total_entries
      if @count == 1
        entity = Entity.find(:first, :order=>"entities.last_name, entities.name, entities.first_name ASC", :conditions=>cond.to_sql, :include=>includes, :joins=>joins)
        redirect_to :action=>"show", :id=>entity.id, :protocol=>@@protocol
        return
      end
    end
  end



  def new
    @entity = Entity.new
  end

  def load_new_entity_form
    @entity = Entity.new
    if params[:style] == "full"
      render :partial=>"full_new_entity"
    else
      render :partial=>"quick_new_entity"      
    end
  end

  def create
    params[:entity].update({:campaign_id=>@campaign.id})
    temp_params = params.dup
    params, phone_hash, fax_hash, email_hash = process_entity_params(temp_params)
    
    #tags
    @tags = params[:entity][:tags]
    params[:entity].delete(:tags)

    interests = Array.new
    #logger.debug interests.to_s
    #logger.debug interests.nil?
    #volunteer interests
    unless params[:entity][:volunteer_interests].nil?
      params[:entity][:volunteer_interests].each do |task_id|
        #logger.debug interests.to_s
        #logger.debug interests.nil?
        #logger.debug task_id
        interests << VolunteerTask.find(task_id.to_i)
      end
      params[:entity].delete(:volunteer_interests)
    end
    
    #logger.debug params[:entity][:type]
    
    Entity.transaction do
      if params[:entity][:type]=="Person"
        @entity = Person.new(params[:entity])
        @household = Household.new(:campaign_id=>@campaign.id)
        @household.save!
        @entity.household = @household
        #name
        @entity.name = @entity.first_name+" "+@entity.last_name
      elsif params[:entity][:type]=="Organization"
        @entity = Organization.new(params[:entity])
      elsif params[:entity][:type]=="OutsideCommittee"
         @entity = OutsideCommittee.new(params[:entity])
      end
      @entity.created_by = current_user.id
      #address
      @address = Address.new(params[:address])
      @address.entity = @entity


      @entity.phones = Hash.new
      @entity.faxes = Hash.new
      # @entity.emails = Hash.new
      @entity.phones.update(phone_hash)
      @entity.faxes.update(fax_hash)
      # @entity.emails.update(email_hash)
      @entity.save!
      #save address
      @address.save!

      if email_hash.to_a.first
        email_address = EmailAddress.new(:label=>email_hash.to_a.first[0], :address=>email_hash.to_a.first[1], :entity_id=>@entity.id)
        email_address.save!
      end
      @entity.primary_email = email_address

      #add address as primary, mailing
      @entity.primary_address = @address
      @entity.mailing_address = @address
      @entity.volunteer_interests = interests
      #tags
      unless @tags.nil?
        expire_fragment(:controller => "campaigns", :action => "tags", :action_suffix => @campaign.id)
        @entity.tag_with(@tags, @campaign.id)
      end

      #treasurer

      # groups
      unless params[:group].nil?
        group_ids = params[:group].keys
        group_ids.each do |group_id|
          if params[:group][group_id][:role].to_s != ""
            group = Group.find(group_id)
            unless @entity.add_to_group(group, params[:group][group_id][:role].to_s)
              raise "failed to add to group"
            end
          end
        end
      end

      #custom_fields
      unless params[:custom_field].nil?
        field_ids = params[:custom_field].keys
        field_ids.each { |field_id|
          field = CustomField.find(field_id)
          if field.field_type=="Num" and params[:custom_field][field_id.to_s][:value].to_s != ""
            params[:custom_field][field_id.to_s][:value] = params[:custom_field][field_id.to_s][:value].to_f.to_s
          elsif field.field_type=="Bool"
            #params[:entity][field_id.to_s][:value] = params[:entity][field_id.to_s][:value].to_f.to_s
          elsif field.field_type=="Select"
            #params[:entity][field_id.to_s][:value] = params[:entity][field_id.to_s][:value].to_f.to_s
          end
          unless params[:custom_field][field_id.to_s][:value].to_s == ""
            field_value = CustomFieldValue.new(:custom_field_id=>field_id,:entity_id=>@entity.id, :value=>params[:custom_field][field_id.to_s][:value])
            field_value.save!
          end
        }
      end
      
      @entity.save!
      flash[:notice] = 'Entity was successfully created.'
      redirect_to :action => 'show', :id=>@entity.id, :protocol=>@@protocol
    end
  end
  
  def autocomplete_for_sign_in # for volunteer sign in
    #find entities that match
    unless params[:entity][:id]
      first = "%"+params[:entity][:first_name]+"%"
      last = "%"+params[:entity][:last_name]+"%"
      cond_name = EZ::Where::Condition.new :entities do
        first_name.nocase =~ first
        last_name.nocase =~ last
      end
      @entities = @campaign.entities.find(:all, :include=>:primary_address, :conditions=>cond_name.to_sql)
      if @entities.length <= 5  and @entities.length > 0# if there are 5 or fewer, put their info on the page
        render :update do |page|
          page.replace_html "sign_in_right_half", :partial=>'simple_show_list_for_sign_in'
        end
      else # clear the div
        render :update do |page|
          page.replace_html "sign_in_right_half", "&nbsp;"
        end
      end
    else
      render :update do |page|
        page.replace_html "sign_in_right_half", "&nbsp;"
      end
    end
  end
  
  # TODO: refactor these next two into one function
  def simple_show_for_sign_in
    @entity = Entity.find(params[:id])
    render :update do |page|
      page.replace_html "sign_in_right_half", "&nbsp;"
      page.replace_html "sign_in_left_half", :partial=>'simple_show_for_sign_in'
    end
  end

  def simple_show_for_sign_out
    @entity = Entity.find(params[:id])
    @vol_session = @entity.current_volunteer_session
    render :update do |page|
      page.replace_html "entity_name", :partial=>'simple_show_for_sign_out'
      page.replace_html "is_this_you", "&nbsp;"
    end
  end

  def edit
    @entity = Entity.find(params[:id])
  end
  
  def simple_self_edit
    @entity = Entity.find(params[:id])
    @address = @entity.primary_address
    render :layout=>'volunteer'  
  end
  
  def self_update
    params[:entity].update({:campaign_id=>@campaign.id})
    primary_phone = params[:entity][:primary_phone_number]
    primary_email = params[:entity][:primary_email_address]
    temp_params = params.dup
    params, phone_hash, fax_hash, email_hash = process_entity_params(temp_params)
    interests = Array.new
    #volunteer interests
    unless params[:entity][:volunteer_interests].nil?
      params[:entity][:volunteer_interests].each do |task_id|
        if task_id[1].to_s == "1"
          interests << VolunteerTask.find(task_id[0].to_i)
        end
      end
      params[:entity].delete(:volunteer_interests)
    end
    @address = @entity.primary_address
    Entity.transaction do
      @entity.update_attributes(params[:entity])
      # name
      @entity.name = @entity.first_name+" "+@entity.last_name
      # address
      if (@address.label != params[:address][:label] and @address.label[0..8] != "From Remo") or (@address.label[0..8] == "From Remo" and @address.line_1 != params[:address][:line_1])
        #make new address, set it as primary
        @address = Address.new(params[:address])
        @address.save!
      else
        @address.update_attributes(params[:address])
      end
      #phones
      @entity.phones[params[:entity][:primary_phone]]=to_numbers(primary_phone)
      if primary_email.to_s == ""
        # delete primary email if it exists
        @entity.remove_primary_email
      else
        email = @entity.primary_email
        if email.nil?
          email = EmailAddress.new(:label=>"Primary",:address=>email_hash.to_a.first[1],:entity_id=>@entity.id)
        else
          email.update_attributes(:address=>email_hash.to_a.first[1], :invalid=>false)
        end
        email.save!
        @entity.primary_email = email
      end
      @entity.primary_address = @address
      @entity.mailing_address = @address
      @entity.volunteer_interests = interests
      @entity.save!
    end      
    
    redirect_to :controller=>"volunteer_events", :action=>"sign_in_form", :id=>@entity.id
  end

  def update
    @entity = Entity.find(params[:id])
    if @entity.update_attributes(params[:entity])
      flash[:notice] = 'Entity was successfully updated.'
      redirect_to :action => 'show', :id => @entity, :protocol=>@@protocol
    else
      render :action => 'edit'
    end
  end

  def update_partial
    if params[:entity][:website].to_s==""
      params[:entity][:website]=nil
    end
    if params[:entity][:receive_phone].to_s==""
      params[:entity][:receive_phone]=nil
    end
    if params[:entity][:receive_email].to_s==""
      params[:entity][:receive_email]=nil
    end
    unless params[:entity][:tags].nil?
      @entity.tag_with(params[:entity][:tags], @campaign.id)
      #@entity.save
      expire_fragment(:controller => "campaigns", :action => "tags", :action_suffix => @campaign.id)
      params[:entity].delete(:tags)
    end
    if @entity.update_attributes(params[:entity])
      #flash[:notice] = 'Entity was successfully updated.'
      render :partial => params[:partial], :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
    else
      flash[:warning] = 'There was an error saving the new values.'
      render :partial => params[:partial], :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
    end
  end

  def update_custom
    field_ids = params[:entity].keys
    field_ids = field_ids-["updated_by"]
    field_ids.each {|field_id|
      field_value = @entity.custom_field_values.find(:first,:conditions=>["custom_field_id=#{field_id}"])
      field = CustomField.find(field_id)
      if field.field_type=="Num" and params[:entity][field_id.to_s][:value].to_s != ""
        params[:entity][field_id.to_s][:value] = params[:entity][field_id.to_s][:value].to_f.to_s
      elsif field.field_type=="Bool"
        #params[:entity][field_id.to_s][:value] = params[:entity][field_id.to_s][:value].to_f.to_s
      elsif field.field_type=="Select"
        #params[:entity][field_id.to_s][:value] = params[:entity][field_id.to_s][:value].to_f.to_s
      end
      if field_value.nil? and params[:entity][field_id.to_s][:value].to_s != ""
         field_value = CustomFieldValue.new(:custom_field_id=>field_id,:entity_id=>@entity.id, :value=>params[:entity][field_id.to_s][:value])
         field_value.save!
      elsif !field_value.nil?
        field_value.update_attributes(params[:entity][field_id.to_s])
      end
      }
    @entity.update_attributes({:updated_by=>current_user.id})
    render :partial => params[:partial], :locals=>{:entity=>@entity, :can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_name
    if params[:entity][:class] == @entity.class.to_s
      logger.debug "no change in entity type"
    else
      @entity.update_attribute('type',params[:entity][:class])
    end
    id = @entity.id
    @entity = Entity.find(id)
    if params[:entity][:class]=="Person"
      params[:entity][:name] = params[:entity][:first_name]+" "+params[:entity][:last_name]
    end
    params[:entity].delete(:class)
    @entity.update_attributes(params[:entity])
    render :partial=>"name", :locals=>{:entity=>@entity, :can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_address
    @address = Address.find(params[:address_id])
    #primary
    if params[:address][:primary]=="1"
      @entity.primary_address = @address
    end
    #mailing
    if params[:address][:mailing]=="1"
      @entity.mailing_address = @address
    end
    params[:address].delete(:primary)
    params[:address].delete(:mailing)
    Entity.transaction do
      @address.update_attributes(params[:address])
      @entity.save!
    end
    render :partial=>"addresses", :locals=>{:entity=>@entity, :can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def delete_address
    @address = Address.find(params[:address_id])
    if @address==@entity.primary_address
      primary=true
    end
    if @address==@entity.mailing_address
      mailing=true
    end
    Entity.transaction do
      @address.destroy
      if primary
        @entity.primary_address = @entity.addresses.first
      end
      if mailing
        @entity.mailing_address = @entity.addresses.first
      end
      @entity.save!
    end
    render :partial=>"addresses", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def add_address
    #primary
    if params[:address][:primary]=="1"
      primary = true
    end
    #mailing
    if params[:address][:mailing]=="1"
      mailing = true
    end
    params[:address].delete(:primary)
    params[:address].delete(:mailing)
    Entity.transaction do
      @address = Address.new(params[:address])
      @address.entity = @entity
      @address.save!
      if primary
        @entity.primary_address = @address
      end
      if mailing
        @entity.mailing_address = @address
      end
      @entity.save!
    end
    render :partial=>"addresses", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  rescue
    render :partial=>"addresses", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_phones
    prev_label = params[:entity][:previous_label]
    new_label = params[:entity][:label]
    if prev_label != new_label
      @entity.phones.delete(prev_label)
    end
    @entity.phones[new_label]=to_numbers(params[:entity][:number])
    if params[:entity][:primary]=="1" or @entity.primary_phone == prev_label
      @entity.primary_phone = new_label
    end
    @entity.save  
    render :partial=>"phones", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def add_phone
    new_label = params[:entity][:label]
    @entity.phones[new_label]=to_numbers(params[:entity][:number])
    if params[:entity][:primary]=="1" or @entity.primary_phone.nil? or @entity.primary_phone.to_s==""
      @entity.primary_phone = new_label
    end
    @entity.save  
    render :partial=>"phones", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end
  
  def delete_phone
    @entity.phones.delete(params[:phone])
    if @entity.primary_phone == params[:phone]
      if @entity.phones.empty?
        @entity.primary_phone = nil
      else
        @entity.primary_phone = @entity.phones.keys.first
      end
    end
    @entity.save
    render :partial=>"phones", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_faxes
    prev_label = params[:entity][:previous_label]
    new_label = params[:entity][:label]
    if prev_label != new_label
      @entity.faxes.delete(prev_label)
    end
    @entity.faxes[new_label]=to_numbers(params[:entity][:number])
    if params[:entity][:primary]=="1" or @entity.primary_fax == prev_label
      @entity.primary_fax = new_label
    end
    @entity.save  
    render :partial=>"faxes", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def add_fax
    new_label = params[:entity][:label]
    @entity.faxes[new_label]=to_numbers(params[:entity][:number])
    if params[:entity][:primary]=="1" or @entity.primary_fax.nil? or @entity.primary_fax.to_s==""
      @entity.primary_fax = new_label
    end
    @entity.save  
    render :partial=>"faxes", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end
  
  def delete_fax
    @entity.faxes.delete(params[:fax])
    if @entity.primary_fax == params[:fax]
      if @entity.faxes.empty?
        @entity.primary_fax = nil
      else
        @entity.primary_fax = @entity.faxes.keys.first
      end
    end
    @entity.save
    render :partial=>"faxes", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_website
    unless params[:entity][:website].to_s == ""
      @entity.website = params[:entity][:website]
      @entity.save
    end
    render :partial=>"website", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def update_skills
    interests = Array.new
    # @entity.volunteer_interests = interests
    # logger.debug "test"
    if params[:entity][:volunteer_interests]
      params[:entity][:volunteer_interests].each {|task_id|
        interests << VolunteerTask.find(task_id)
      }
      interests.uniq!
      @entity.volunteer_interests = interests
      params[:entity].delete(:volunteer_interests)
    end
    if @entity.update_attributes(params[:entity])
      #flash[:notice] = 'Entity was successfully updated.'
      render :partial=>"skills_and_interests", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
    else
      flash[:warning] = 'There was an error saving the new values.'
      render :partial=>"skills_and_interests", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)} #, :protocol=>@@protocol
    end    
  end

  def load_treasurer_summaries
			#     @campaign.committees.each do |committee|
			#       logger.debug committee.treasurer_api_url
			#       unless current_user.treasurer_info.nil? or current_user.treasurer_info[committee.id].nil? 
			#     		treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,committee.treasurer_api_url)
			#     		treasurer_entity = TreasurerEntity.find(:first,:conditions=>["entity_id=:entity AND committee_id=:committee",{:entity=>@entity.id,:committee=>committee.id}])
			#     		unless treasurer_entity.nil?
			#     		  logger.debug current_user.treasurer_info[committee.id][0]
			#     		  logger.debug current_user.treasurer_info[committee.id][1]
			#     		  logger.debug committee.treasurer_id
			#     		  logger.debug treasurer_entity.treasurer_id
			#     			summary = treasurer.get_financial_summary_by_id(current_user.treasurer_info[committee.id][0], current_user.treasurer_info[committee.id][1],committee.treasurer_id,treasurer_entity.treasurer_id)
			#     			logger.debug summary
			#   			end
			# end
			#     end
    render :partial=>'treasurer_summary'#, :protocol=>@@protocol
  end

  def update_contribution #including deletion
    @contrib = Contribution.find(params[:contribution_id])
    if params[:contribution][:recipient_committee_id].to_s != ""
      params[:contribution].delete(:recipient)
    end
    if params[:contribution][:campaign_event_id] and params[:contribution][:campaign_event_id].to_s != ""
      event = CampaignEvent.find(params[:contribution][:campaign_event_id])
      if event
        if event.recipient_committee_id.nil? or event.recipient_committee_id.to_s == params[:contribution][:recipient_committee_id].to_s
        else
          params[:contribution].delete(:campaign_event_id)
          flash[:contrib_warning] = "Event didn't match the recipient committee; contribution not attached to event."
        end
      end
    end
    unless params[:delete_contribution]=="1"
      params[:contribution][:amount] = params[:contribution][:amount].to_f
      if params[:contribution][:amount] <= 0
        flash[:contrib_warning] = 'Error saving contribution.  Amount must be a positive number.'
        @recent_events = @campaign.get_recent_events
        render :partial=>'other_contributions'#, :protocol=>@@protocol
        return
      end
      @contrib.update_attributes(params[:contribution])
    else
      @contrib.destroy
    end
    @recent_events = @campaign.get_recent_events
    render :partial=>'other_contributions'#, :protocol=>@@protocol
  end
  
  def create_contribution
    params[:contribution][:amount] = params[:contribution][:amount].to_f
    if params[:contribution][:amount] <= 0
      flash[:contrib_warning] = 'Error saving contribution.  Amount must be a positive number.'
      @recent_events = @campaign.get_recent_events
      render :partial=>'other_contributions'#, :protocol=>@@protocol
      return
    end
    if params[:contribution][:recipient_committee_id].to_s != ""
      params[:contribution].delete(:recipient)
    end
    if params[:contribution][:campaign_event_id] and params[:contribution][:campaign_event_id].to_s != ""
      event = CampaignEvent.find(params[:contribution][:campaign_event_id])
      if event
        if event.recipient_committee_id.nil? or event.recipient_committee_id.to_s == params[:contribution][:recipient_committee_id].to_s
        else
          params[:contribution].delete(:campaign_event_id)
          flash[:contrib_warning] = "Event didn't match the recipient committee; contribution not attached to event."
        end
      end
    end
    @contrib = Contribution.new(params[:contribution])
    @contrib.entity_id = @entity.id
    if @contrib.save
      flash[:contrib_notice] = 'New contribution saved' 
    else
      flash[:contrib_warning] = 'Error saving contribution'
    end
    @recent_events = @campaign.get_recent_events
    render :partial=>'other_contributions'#, :protocol=>@@protocol
  end
  
  def add_to_household
    @page_entity = Entity.find(params[:page_entity_id])
    @household = Household.find(params[:household_id])
    old_household = Household.find(@entity.household_id)
    unless @household == old_household
      @entity.household = @household
      if @entity.save
        if !old_household.nil? and old_household.people.empty?
          old_household.destroy
        end
      end
    end
    @entity = @page_entity
    render :partial=>"household_box", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end
  
  def remove_from_household
    @page_entity = Entity.find(params[:page_entity_id])
    @new_household = Household.new(:campaign_id=>@campaign.id)
    if @new_household.save
      @entity.household = @new_household
      @entity.save
    end
    @entity = @page_entity
    render :partial=>"household_box", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def household_search
    @household = Household.find(params[:household_id])
    content = params[:search][:name].to_s.gsub(/[*]/,'%')
    if content == params[:search][:name]
      search = "%"+content+"%"
    else
      search = content
    end
    cond = EZ::Where::Condition.new :entities
    @campaign = Campaign.find(params[:campaign_id])
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
    camp = @campaign.id
    cond.campaign_id == camp
    cond.name.nocase =~ search
    cond.type == "Person"
    @entities = Entity.find(:all,:conditions=>cond.to_sql,:limit=>8)
    render :partial=>"household_search_results", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  # # this shouldn't be used any more
  # def add_tag_to_cart
  #   @cart = find_cart
  #   @tag = params[:entity][:tag].to_s.strip
  #   unless @tag == ""
  #     @entities = Entity.find(@cart.items)
  #     @entities.each do |entity|
  #       new_tag = Tag.find_by_name_and_campaign_id(@tag, @campaign.id)
  #       if new_tag.nil? or !entity.tags.include?(new_tag)
  #         tags = entity.tag_list+ ", #{@tag}"
  #         logger.debug tags
  #         entity.tag_with(tags, @campaign.id)
  #       end
  #     end
  #     render :update do |page|
  #       page.replace_html 'flash_notice', "MyPeople tagged with: #{@tag}"
  #     end
  #     return
  #   else
  #     render :update do |page|
  #       page.replace_html 'flash_notice', "Can't tag with an empty tag name."
  #     end
  #     return
  #   end
  # end
    
  
  def upload_file
    # empty
   #  @campaign = Campaign.find(params[:campaign_id])
  end
  
  def save_file_and_redirect
    # @campaign = Campaign.find(params[:campaign_id])
    filename = params[:csv_file].original_filename
    filename = filename.gsub(/^.*(\\|\/)/, '')
    filename = filename.gsub(/[^\w\.\-]/,'_')
    logger.debug filename
    logger.debug params[:csv_file].original_filename
    logger.debug params[:csv_file].content_type
    File.open("#{RAILS_ROOT}/public/csv_files/#{filename}", "wb") { |f| f.write(params[:csv_file].read) }
    redirect_to :controller=>"entities", :action=>"import_from_csv", :params=>{:campaign_id=>@campaign.id, :filename=>filename}, :protocol=>@@protocol
  end
  
  def import_from_csv
    # @campaign = Campaign.find(params[:campaign_id])
    @filename = params[:filename]
    @errors = params[:errors] unless params[:errors].nil?
#    file = File.open("#{RAILS_ROOT}/public/csv_files/#{@filename}", "r")
    @rows = CSV.readlines("#{RAILS_ROOT}/public/csv_files/#{@filename}")
#    CSV.open("#{RAILS_ROOT}/public/csv_files/#{@filename}",'rb') do |row|
#      logger.debug row.class
#    end
    @tags = @campaign.tags
    @tasks = @campaign.volunteer_tasks
    @custom_fields = @campaign.custom_fields
  end
  
  def process_csv_data
    # @campaign = Campaign.find(params[:campaign_id])
    @filename = params[:filename]
    @rows = CSV.readlines("#{RAILS_ROOT}/public/csv_files/#{@filename}")
    @row_length = @rows[0].length
    logger.debug @row_length
    @tags = @campaign.tags
    current_year = Time.now.year.to_i 
		start_year = current_year-4
		end_year = current_year+1
		years = start_year..end_year
    @tasks = @campaign.volunteer_tasks
    @custom_fields = @campaign.custom_fields
    field_array = []
    errors = []
    #logger.debug params[:field_match]
    #logger.debug params[:field_match][0.to_s]
    (0...@row_length).each { |entry|
      #logger.debug entry
      field_array[entry] = params[:field_match][entry.to_s]
    }
    logger.debug field_array
    unless field_array.include?("name") or field_array.include?("last_name") or field_array.include?("first_name")
      errors << "no_name"
      raise
    end
    if params[:ignore_first_line]=="1"
      @rows = @rows[1...@rows.length]
    end
    save_counter = 0
    Entity.transaction do
    Address.transaction do
      @rows.each {|row|
        #logger.debug row
        if params[:type]=="Person"
          @entity = Person.new(:campaign_id=>@campaign.id)
        elsif params[:type]=="Organization"
          @entity = Organization.new(:campaign_id=>@campaign.id)
        elsif params[:type]=="OutsideCommittee"
           @entity = OutsideCommittee.new(:campaign_id=>@campaign.id)
        end
        @entity.phones = Hash.new
        @entity.faxes = Hash.new
        @entity.emails = Hash.new
        @home_address = nil
        @work_address = nil
        (0...@row_length).each { |entry|
          logger.debug entry.to_s
          unless row[entry].to_s==""
            logger.debug row[entry].to_s
            case field_array[entry]
            when "ignore"
              logger.debug "ignore"
            when "name"
              logger.debug "name"
              @entity.name = row[entry]
            when "title"
              logger.debug "title"
              @entity.title = row[entry]
            when "first_name"
              logger.debug "first_name"
              @entity.first_name = row[entry]
            when "legal_first_name"
              logger.debug "legal_first_name"
              @entity.nickname = @entity.first_name
              @entity.first_name = row[entry]
            when "middle_name"
              logger.debug "middle_name"
              @entity.middle_name = row[entry] 
            when "last_name"
              logger.debug "last_name"
              @entity.last_name = row[entry]
            when "name_suffix"
              logger.debug "name_suffix"
              @entity.name_suffix = row[entry]
            when "home_addr_1"
              logger.debug "home_addr_1"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:line_1=>row[entry],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.line_1 = row[entry]
              end
            when "home_addr_2"
              logger.debug "home_addr_2"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:line_2=>row[entry],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.line_2 = row[entry]
              end
#            when "home_addr_st_num"
#              logger.debug "home_addr_st_num"
#            when "home_addr_st_num_frac"
#              logger.debug "home_addr_st_num_frac"
#            when "home_addr_st_name"
#              logger.debug "home_addr_st_name"
#            when "home_addr_apt_num"
#              logger.debug "home_addr_apt_num"
            when "home_addr_city"
              logger.debug "home_addr_city"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:city=>row[entry],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.city = row[entry]
              end
            when "home_addr_state"
              logger.debug "home_addr_state"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:state=>row[entry],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.state = row[entry]
              end
            when "home_addr_zip"
              logger.debug "home_addr_zip"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:zip=>to_numbers(row[entry].to_s)[0..4],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.zip = row[entry][0..4]
              end
            when "home_addr_zip_4"
              logger.debug "home_addr_zip_4"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:zip_4=>to_numbers(row[entry].to_s)[0..3],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.zip_4 = row[entry][0..3]
              end
            when "home_addr_zip_9"
              logger.debug "home_addr_zip_9"
              if @home_address.nil?
                logger.debug "creating home address"
                @home_address = Address.new(:zip=>to_numbers(row[entry])[0..4],:zip_4=>to_numbers(row[entry].to_s)[5..8],:label=>"Home")
                @entity.addresses << @home_address
              else
                @home_address.zip = to_numbers(row[entry])[0..4]
                @home_address.zip_4 = to_numbers(row[entry])[5..8]
              end
            when "work_addr_1"
               if @work_address.nil? and !row[entry].nil?
                 logger.debug "creating work address"
                 @work_address = Address.new(:line_1=>row[entry],:label=>"Work")
                 @entity.addresses << @work_address
               else
                 @work_address.line_1 = row[entry]
               end
            when "work_addr_2"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:line_2=>row[entry],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.line_2 = row[entry]
              end
            when "work_addr_city"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:city=>row[entry],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.city = row[entry]
              end
            when "work_addr_state"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:state=>row[entry],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.state = row[entry]
              end
            when "work_addr_zip"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:zip=>to_numbers(row[entry].to_s)[0..4],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.zip = row[entry][0..4]
              end
            when "work_addr_zip_4"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:zip_4=>to_numbers(row[entry].to_s)[0..3],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.zip_4 = row[entry][0..3]
              end
            when "work_addr_zip_9"
              if @work_address.nil?
                logger.debug "creating work address"
                @work_address = Address.new(:zip=>to_numbers(row[entry])[0..4],:zip_4=>to_numbers(row[entry].to_s)[5..8],:label=>"Work")
                @entity.addresses << @work_address
              else
                @work_address.zip = to_numbers(row[entry])[0..4]
                @work_address.zip_4 = to_numbers(row[entry])[5..8]
              end
            when "home_phone"
              @entity.phones.merge!({"Home"=>to_numbers(row[entry].to_s)})
              @entity.primary_phone = "Home"
            when "work_phone"
              @entity.phones.merge!({"Work"=>to_numbers(row[entry].to_s)})
            when "cell_phone"
              @entity.phones.merge!({"Mobile"=>to_numbers(row[entry].to_s)})
            when "fax"
              @entity.faxes={"Primary"=>to_numbers(row[entry].to_s)}
              @entity.primary_fax = "Primary"
            when "email"
              if row[entry].to_s != ""
                @email = EmailAddress.new(:label=>"Primary",:address=>row[entry].to_s)
                @entity.email_addresses << @email
              end
            when "work_email"
              if row[entry].to_s != ""
                @work_email = EmailAddress.new(:label=>"Work/Secondary",:address=>row[entry].to_s)
                @entity.email_addresses << @work_email
              end
            when "registered_party"
              logger.debug "registered_party"
              @entity.registered_party = row[entry].to_s
            when "precinct"
              logger.debug "precinct"
              @entity.precinct = row[entry].to_s
            when "voter_id"
              logger.debug "voter_ID"
              @entity.voter_ID = row[entry].to_s
            when "federal_id"
              @entity.federal_ID = row[entry].to_s
            when "state_id"
              @entity.state_ID = row[entry].to_s
            when "party"
              unless !row[entry] or row[entry].nil? or row[entry]=="0" or row[entry]="f"
                 @entity.party = true
               else 
                 @entity.party = false
               end
            when "receive_email"
              logger.debug "receive_email"
              unless !row[entry] or row[entry].nil? or row[entry].to_s=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                @entity.receive_email = true
              else 
                if !row[entry] or row[entry].to_s=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                  @entity.receive_email = false
                end
              end
            when "receive_phone"
              logger.debug "receive_phone"
              unless !row[entry] or row[entry].nil? or row[entry].to_s=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                @entity.receive_phone = true
              else 
                if !row[entry] or row[entry]=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                  @entity.receive_phone = false
                end
              end
            when "employer"
              logger.debug "employer"
              @entity.employer = row[entry]
            when "occupation"
              logger.debug "occupation"
              @entity.occupation = row[entry]
            when "languages"
              logger.debug "languages"
              @entity.languages = row[entry]
            when "skills"
              logger.debug "skills"
              @entity.skills = row[entry]
            when "time_to_reach"
              logger.debug "time_to_reach"
              @entity.time_to_reach = row[entry]
            when "comments"
              logger.debug "comments"
              @entity.comments = row[entry]
            when "delete_requested"
              logger.debug "delete_requested"
              unless !row[entry] or row[entry].nil? or row[entry].to_s=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                @entity.delete_requested = true
              else 
                if !row[entry] or row[entry].to_s=="0" or row[entry].to_s=="f" or row[entry].to_s=="No"
                  @entity.delete_requested = false
                end
              end
            end
          end
        }
        logger.debug "about to build name"
        if @entity.class==Person
          if @entity.name.nil? or @entity.name.to_s==""
            unless (@entity.first_name.nil? or @entity.last_name.nil?)
              @entity.name = @entity.first_name.to_s+" "+@entity.last_name.to_s
              unless @entity.name_suffix.to_s==""
                @entity.name+=" "+@entity.name_suffix.to_s
              end
            else 
              if @entity.last_name.nil?
                @entity.name = @entity.first_name.to_s+" ?"
              elsif @entity.first_name.nil?
                @entity.name = "? "+@entity.last_name.to_s
              end
            end
          else
            if @entity.first_name.to_s=="" and @entity.last_name.to_s==""
              split_array = @entity.name.split(' ', 2)
              @entity.first_name = split_array[0]
              @entity.last_name = split_array[1]
            end              
          end
        end
        if @entity.primary_phone.nil?
          unless @entity.phones.empty?
            @entity.primary_phone = @entity.phones.to_a[0][0]
          end
        end
        # if @entity.primary_email.nil?
        #   unless @entity.emails.empty?
        #     @entity.primary_email = @entity.emails.to_a[0][0]
        #   end
        # end
        if @entity.class==Person
          @household = Household.new(:campaign_id=>@campaign.id)
          @household.save
          @entity.household = @household
        end
        @entity.created_by = current_user.id
        unless @home_address.nil?
          @home_address.save! 
          @entity.addresses << @home_address
          @entity.primary_address = @home_address
          @entity.mailing_address = @home_address
        end
        unless @work_address.nil?
          @work_address.save! 
          @entity.addresses << @work_address
          if @home_address.nil?
            @entity.primary_address = @work_address
            @entity.mailing_address = @work_address
          end
        end
        unless @email.nil?
          @email.save!
          @entity.email_addresses << @email
          @entity.primary_email = @email
          # @entity.save!
        end
        unless @work_email.nil?
          @work_email.save!
          @entity.email_addresses << @work_email
          if @email.nil?
            @entity.primary_email = @work_email
          end      
          # @entity.save!
        end
        logger.debug "about to save"
        if @entity.save
          save_counter+=1
          logger.debug "entries saved:" + save_counter.to_s
          logger.debug @entity.attributes.to_s unless @entity.nil?
          @entity.addresses.each {|address|
            logger.debug address.attributes.to_s
          }
        else
          # errors << entry
          logger.debug "save failed"
          raise "Error in entry "+@entity.name.to_s
        end
        tags = ''
        (0...@row_length).each { |entry|
          unless row[entry].to_s==""
            case field_array[entry]
            when /task_(.*)/
              unless row[entry].to_s=="No" or row[entry].to_s=="0"
                task_id = $1.to_i
                logger.debug task_id
                task = VolunteerTask.find(task_id)
                @entity.volunteer_interests << task
                @entity.save!
              end
            when /custom_(.*)/
              logger.debug "custom #$1"
              field_id = $1.to_i
              #field = CustomField.find(field_id)
              cfv = CustomFieldValue.new(:custom_field_id=>field_id, :entity_id=>@entity.id, :value=>row[entry].to_s)
              cfv.save!
            when /tag_(.*)/
              tag_id = $1.to_i
              tag = Tag.find(tag_id)
              tags+="\"#{tag.name}\", "
              logger.debug tag.name
            when /contrib_(.*)/
              logger.debug "contrib #$1"
              @contrib = Contribution.new(:recipient=>@campaign.name,:date=>Time.local($1.to_i) ,:amount=>row[entry].to_f,:entity_id=>@entity.id)
              @contrib.save!
              #@entity.contributions<<@contrib
              #@entity.save!
            end
          end
        }
        logger.debug "tags: "+tags
        @entity.tag_with(tags, @campaign.id)
        @entity.save!
      }    
    end
    end
    if errors.length==0
      redirect_to :controller=>"entities", :action=>"list", :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      logger.debug "else clause"
      redirect_to :controller=>"entities", :action=>"import_from_csv", :params=>{:campaign_id=>@campaign.id, :filename=>params[:filename], :errors=>errors}, :protocol=>@@protocol
    end
#  rescue
#    logger.debug "rescue clause"
#    redirect_to :controller=>"entities", :action=>"import_from_csv", :params=>{:id=>@campaign.id, :filename=>params[:filename], :errors=>errors}, :protocol=>@@protocol
  end

  def request_delete
    if params[:delete] == "true"
      if @entity.update_attributes({:delete_requested=>true})
        render :partial=>"request_delete",:locals=>{:delete=>false}, :protocol=>@@protocol
      else
        flash[:warning] = "unable to set 'delete requested' to true"
        redirect_to :action=>'show',:id=>@entity.id, :protocol=>@@protocol
      end      
    else
      if @entity.update_attributes({:delete_requested=>false})
        render :partial=>"request_delete",:locals=>{:delete=>true}, :protocol=>@@protocol
      else
        flash[:warning] = "unable to set 'delete requested' to false"
        redirect_to :action=>'show',:id=>@entity.id, :protocol=>@@protocol
      end      
    end
  end

  def destroy
    @ent = Entity.find(params[:id])

    # notify Treasurer of deletion if it has TreasurerEntities
    # Treasurer should then remove its Manager_ID (and reset manager_update flags correctly)
    treasurer_entities = @ent.treasurer_entities
    if treasurer_entities
      treasurer_entities.each do |te|
        committee = te.committee
        treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,committee.treasurer_api_url)
        begin
          acknowledged = treasurer.notify_of_deletion(current_user.treasurer_info[committee.id][0], current_user.treasurer_info[committee.id][1],committee.treasurer_id,te.treasurer_id)
        rescue
        end
      end
    end

    campaign_id = @ent.campaign_id
    @ent.volunteer_interests = []
    @ent.destroy
    redirect_to :action => 'list',:params=>{:campaign_id=>campaign_id}, :protocol=>@@protocol
  end

private

  def build_text_search(flag, param, column, table)
    #logger.debug flag
    #logger.debug param
    #logger.debug column
    cond = EZ::Where::Condition.new table
    if flag == "Includes"
      search = '%'+param+'%'
      cond.create_clause(column.to_sym, :=~, search, true)
    elsif flag == "In List"
      search = param.to_s
      if search==""
        cond.create_clause(column.to_sym, '==', :null)
        cond.append "#{table.to_s}.#{column}=''", :or
      else
        search_array = search.split(',')
        search_array.each do |term|
          term.strip!
        end
        cond.create_clause(column.to_sym, '===', search_array, true)
      end
    elsif flag == "Not List"
      search = param.to_s
      neg_col = column+"!"
      if search==""
        cond.create_clause(neg_col.to_sym, '==', :null)
        cond += "#{table.to_s}.#{column}!=''"
      else
        search_array = search.split(',')
        search_array.each do |term| 
          term.strip!
        end
        cond.create_clause(neg_col.to_sym, '===', search_array, true)
        cond2 = EZ::Where::Condition.new table
        cond2.create_clause(column.to_sym, '==', :null)
        cond |= cond2
        cond |= "#{table.to_s}.#{column}=''"
      end
    elsif flag == "Matches"
      search = param.to_s.gsub(/[*]/,'%')
      if search==""
        cond.create_clause(column.to_sym, '==', :null)
        cond.append "#{table.to_s}.#{column}=''", :or
      else
        cond.create_clause(column.to_sym, '==', search, true)
      end
    elsif flag == "Not"
      search = param.to_s
      neg_col = column+"!"
      #logger.debug neg_col
      if search==""
        cond.create_clause(neg_col.to_sym, '==', :null)
        cond.append "#{table.to_s}.#{column}!=''", :and
      else
        search = '%'+param+'%'
        cond.create_clause(neg_col.to_sym, :=~, search, true)
        cond.create_clause(neg_col.to_sym, '==', :null)
       end 
    end
    #logger.debug "sql = " + cond.to_sql.to_s
    return cond
  end

  protected
  
  def load_entity_and_check_campaign
    @entity = Entity.find(params[:id])
    # @campaign = @entity.campaign
    if current_user.active_campaigns.include?(@campaign.id) and @campaign.id == @entity.campaign_id
      unless params[:entity].nil?
        params[:entity][:updated_by]=current_user.id
      end
    else
      @entity = nil
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
  def check_campaign
    # unless params[:campaign_id]
    #   params[:campaign_id] = current_user.active_campaigns.first
    # end
    # @campaign = Campaign.find(params[:campaign_id])    
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
end
