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

class VolunteerEventsController < ApplicationController
  layout 'manager'

  before_filter :get_campaign

#TODO: check entities against current_campaign

  def calendar
    @page_title = "Volunteer Calendar"
    # @campaign = Campaign.find(params[:campaign_id])
    @year = (params[:year] || Time.now.year).to_i
    @month = (params[:month] || Time.now.month).to_i
  end

  def list
    @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    
    @volunteer_events = VolunteerEvent.paginate :per_page => 5, :order=>"start_time DESC, end_time DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>params[:page]
    render :layout => false
  end

  def create
    @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    params[:volunteer_event]['start_time(1i)'] = params[:date]['time(1i)']
    params[:volunteer_event]['start_time(2i)'] = params[:date]['time(2i)']
    params[:volunteer_event]['start_time(3i)'] = params[:date]['time(3i)']
    params[:volunteer_event]['start_time(4i)'] = params[:date]['start_time(4i)']
    params[:volunteer_event]['start_time(5i)'] = params[:date]['start_time(5i)']
    params[:volunteer_event]['end_time(1i)'] = params[:date]['time(1i)']
    params[:volunteer_event]['end_time(2i)'] = params[:date]['time(2i)']
    params[:volunteer_event]['end_time(3i)'] = params[:date]['time(3i)']
    params[:volunteer_event]['end_time(4i)'] = params[:date]['end_time(4i)']
    params[:volunteer_event]['end_time(5i)'] = params[:date]['end_time(5i)']
    @new_event = VolunteerEvent.new(params[:volunteer_event])
    @new_event.duration = @new_event.generate_duration
    @new_event.save!
    @success = true
    @notice = "Volunteer session saved."
    @volunteer_events = VolunteerEvent.paginate :per_page => 5, :order=>"start_time DESC, end_time DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>params[:page]
    render_without_layout  
  end

  def update
    @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    @event = VolunteerEvent.find(params[:volunteer_event][:id])
    @event.duration = @event.generate_duration
    params[:volunteer_event]['start_time(1i)'] = params[:date]['time(1i)']
    params[:volunteer_event]['start_time(2i)'] = params[:date]['time(2i)']
    params[:volunteer_event]['start_time(3i)'] = params[:date]['time(3i)']
    params[:volunteer_event]['start_time(4i)'] = params[:date]['start_time(4i)']
    params[:volunteer_event]['start_time(5i)'] = params[:date]['start_time(5i)']
    params[:volunteer_event]['end_time(1i)'] = params[:date]['time(1i)']
    params[:volunteer_event]['end_time(2i)'] = params[:date]['time(2i)']
    params[:volunteer_event]['end_time(3i)'] = params[:date]['time(3i)']
    params[:volunteer_event]['end_time(4i)'] = params[:date]['end_time(4i)']
    params[:volunteer_event]['end_time(5i)'] = params[:date]['end_time(5i)']
    if @event.update_attributes(params[:volunteer_event])
      @event.update_attributes("duration"=>@event.generate_duration)
      @success = true
      @notice = "Volunteer session updated."
    else
      raise
    end
    @volunteer_events = VolunteerEvent.paginate :per_page => 5, :order=>"start_time DESC, end_time DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>params[:page]
    render_without_layout  
  end

  def destroy
    @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    @event = VolunteerEvent.find(params[:id])
    @event.destroy
    @success = true
    @notice = "Volunteer session deleted."
    @volunteer_events = VolunteerEvent.paginate :per_page => 5, :order=>"start_time DESC, end_time DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :page=>params[:page]
    render_without_layout  
  end
  
  def welcome # get
    # this just gives a plain page where the user can choose whether to sign in/up or out
    @page_title = "Welcome"
    render :layout=>'volunteer'
  end
  # 
  
  def sign_in_form # get
    # returns form for signing in or up
    if params[:id]
      @entity = @campaign.entities.find(params[:id])
    end
    @page_title = "Please Sign In"
    render :layout=>'volunteer'
  end
  
  def sign_in # post only
    # if there's an entity[:id] passed in
    if params[:entity][:id]
      @entity = Entity.find(params[:entity][:id])
    else # if we're creating a new person
      params[:entity].update({:campaign_id=>@campaign.id})
      #phone
      unless params[:phone][:number].to_s==""
        params[:entity][:primary_phone].to_s=="" ? params[:entity][:primary_phone]="Primary" : params[:entity][:primary_phone]
        phone_hash = {params[:entity][:primary_phone]=>to_numbers(params[:phone][:number])}
      else
        phone_hash = Hash.new
        params[:entity].delete(:primary_phone)
      end
      #email
      unless params[:email][:address].to_s==""
        params[:entity][:primary_email].to_s=="" ? params[:entity][:primary_email]="Primary" : params[:entity][:primary_email]
        email_hash = {params[:entity][:primary_email]=>params[:email][:address]}
      else
        email_hash = Hash.new
      end
      params[:entity].delete(:primary_email)
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
      Entity.transaction do
        @entity = Person.new(params[:entity])
        @household = Household.new(:campaign_id=>@campaign.id)
        @household.save!
        @entity.household = @household
        #name
        @entity.name = @entity.first_name+" "+@entity.last_name
        @entity.created_by = current_user.id
        #address
        @address = Address.new(params[:address])
        @address.entity = @entity

        @entity.phones = Hash.new
        @entity.phones.update(phone_hash)
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
        @entity.save!
      end      
    end
    
    # if signing in:
    if params[:sign_in_or_up] == "Sign In"
      unless @entity.current_volunteer_session
        # starts the volunteer session and redirects to welcome
        params[:volunteer_event][:entity_id] = @entity.id
        params[:volunteer_event][:start_time] = Time.now
        params[:volunteer_event][:comments] = "In progress..."
        event = VolunteerEvent.new(params[:volunteer_event])
        event.save!
      end
      flash[:notice] = "Thank you for volunteering, #{@entity.first_name}!  Remember to sign out when you're done."
    else
      flash[:notice] = "Thank you for your interest, #{@entity.first_name}.  We hope you'll volunteer soon."
    end

    redirect_to :action=>:welcome
  end
  
  def sign_out_form # get
    # returns form for signing out
    if params[:id]
      @entity = @campaign.entities.find(params[:id])
    end
    @page_title = "Thank you for volunteering"
    render :layout=>'volunteer'
  end
  
  def autocomplete_for_sign_out
    unless params[:entity][:id]
      first = "%"+params[:entity][:first_name]+"%"
      last = "%"+params[:entity][:last_name]+"%"
      cond_name = EZ::Where::Condition.new :entities do
        first_name.nocase =~ first
        last_name.nocase =~ last
      end
      cond_times = EZ::Where::Condition.new :volunteer_events do
        end_time == :null
        start_time! == :null
      end
      cond_name.append cond_times
      
      @entities = @campaign.entities.find(:all, :include=>[:primary_address, :volunteer_events], :conditions=>cond_name.to_sql)

      @entities.each do |entity|
        logger.debug entity.name
        logger.debug entity.current_volunteer_session.volunteer_task
      end
      if @entities.length <= 5 and @entities.length > 0# if there are 5 or fewer, put their info on the page
        render :update do |page|
          page.replace_html "is_this_you", :partial=>'entities/simple_show_list_for_sign_out'
        end
      else # clear the div
        render :update do |page|
          page.replace_html "is_this_you", "&nbsp;"
        end
      end
    else
      render :update do |page|
        page.replace_html "is_this_you", "&nbsp;"
      end
    end
  end
  
  def sign_out
    if params[:id] # from list_current
      vol_session = VolunteerEvent.find(params[:id])
      entity = vol_session.entity
    elsif params[:entity][:id] # from sign_out_form
      entity = Entity.find(params[:entity][:id])
      vol_session = entity.current_volunteer_session
    else
      raise
    end
    if params[:entity][:current_volunteer_task]
      vol_session.volunteer_task_id = params[:entity][:current_volunteer_task]
    end
    if params[:entity][:current_volunteer_duration]
      str = params[:entity][:current_volunteer_duration]
      arry = str.split(":")
      if arry.length == 2
        vol_session.duration = arry[0].to_i*60 + arry[1].to_i
        vol_session.end_time = vol_session.start_time + vol_session.duration.minutes
      else
        vol_session.end_time = Time.now
        vol_session.duration = vol_session.generate_duration      
      end
    else
      vol_session.end_time = Time.now
      vol_session.duration = vol_session.generate_duration      
    end    
    vol_session.comments = ""
    vol_session.save!
    if params[:return_to].to_s == "list" #TODO: use format selection to do this with AJAX
      flash[:notice] = "Session signed out for #{entity.name}."
      redirect_to :action=>"list_current"
    else # while this stays with HTML
      flash[:notice] = "Thank you so much for volunteering, #{entity.first_name}!"
      redirect_to :action=>"welcome"
    end
  end
  
  def list_current
    @entities = @campaign.entities.find(:all,:include=>:volunteer_events,:conditions=>"volunteer_events.end_time IS NULL AND volunteer_events.start_time IS NOT NULL")
    @tasks = @campaign.volunteer_tasks
  end
  
  
end
