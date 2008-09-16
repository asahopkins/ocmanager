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

# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
require 'csv'

class ExportCsvWorker < BackgrounDRb::Rails
  
  attr_reader :progress
  
  @job_ctrl = true
  
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
  
  def do_work(args)
    @logger.debug args.to_s
    @progress = 0
    text = ContactText.find(args[:text_id]) unless args[:text_id] == "mypeople"
    campaign = Campaign.find(args[:campaign_id])
    entity_id_array = args[:entity_id_array]
    entities = Entity.find(entity_id_array)
    filename = args[:filename]
    file_path = args[:file_path_prefix].to_s + args[:campaign_id].to_s + "/" + filename
    delete_blank_addresses = args[:delete_blank_addresses].to_i
    second_phone = args[:second_phone].to_i
    total_financial = args[:total_financial_box].to_i
    total_timeframe = args[:total_financial_timeframe]
    total_financial_committee = args[:total_financial_committee]
    
    latest_financial_box = args[:latest_financial_box].to_i
    latest_financial_committee = args[:latest_financial_committee]
    annual_financial_box = args[:annual_financial_box].to_i
    annual_financial_years = args[:annual_financial_years].to_i
    volunteer_box = args[:volunteer_box].to_i
    volunteer_timeframe = args[:volunteer_timeframe]
    volunteer_num = args[:volunteer_num].to_i
    user = User.find(args[:user_id])
    
    temp = []
    if delete_blank_addresses != 0
      # entities.each do |entity|
      #   @logger.debug entity.name
      # end
      @logger.debug "removing entities with blank addresses"
      entities.each do |entity|
        @logger.debug entity.name        
        # @logger.debug entity.mailing_address.nil?
        # unless entity.mailing_address.nil?
          # @logger.debug entity.mailing_address.line_1.to_s == ""
          # @logger.debug entity.mailing_address.city.to_s == ""
          # @logger.debug entity.mailing_address.state.to_s == ""
          # @logger.debug entity.mailing_address.zip.to_s == ""
        # end
        unless (entity.mailing_address.nil? or entity.mailing_address.line_1.to_s == "" or entity.mailing_address.city.to_s == "" or entity.mailing_address.state.to_s == "" or entity.mailing_address.zip.to_s == "")
          @logger.debug "adding "+entity.name
          temp << entity
        end
      end
      entities = temp
    end
        
    # sort entities
    # leave grouped by household
    entities = entities.sort_by {|entity| [entity.class.to_s, entity.household_last_name.to_s, entity.household_id]}
    @logger.debug "entities are now sorted"
    # entities.each do |entity|
    #   @logger.debug entity.name
    # end

    if entities.length > 0
      if text.nil?
        file_data = "Mail merge file for MyPeople, created for #{user.name} on #{Time.now.strftime('%m/%d/%Y')}:\n"
      else
        already_recorded = text.recipients
        file_data = "Mail merge file for letter #{text.label}, created for #{user.name} on #{Time.now.strftime('%m/%d/%Y')}:\n"
        if text.campaign_event_id and text.campaign_event_id.to_i > 0
          @event = CampaignEvent.find(text.campaign_event_id)
        end
      end
      labels = ["Household ID", "Title", "First name", "Middle name", "Last name", "Suffix", "Full name", "Address line 1", "Address line 2", "City", "State", "ZIP", "ZIP+4", "Primary Phone", "Number", "Primary Email", "Address"]
      row_size = labels.length
      #@logger.debug params[:mail_merge][:total_financial_box]
      #@logger.debug params[:mail_merge][:latest_financial_box]
      if second_phone == 1
        labels << "Secondary Phone" << "Number"
        row_size += 2
      end
      if total_financial == 1
        labels << "Total contributions in the last #{total_timeframe}"
        row_size += 1
        total_committee = OutsideCommittee.find(total_financial_committee)
        if total_timeframe == "day"
          start_date = Time.now - 1.day
        elsif total_timeframe == "week"
          start_date = Time.now - 1.week      
        elsif total_timeframe == "month"
          start_date = Time.now - 1.month
        elsif total_timeframe == "year"
          start_date = Time.now - 1.year
        else
          start_date = Time.now - 1.year
        end
        start_date = start_date.to_date
        end_date = DateTime.now
        @logger.debug start_date.to_s
        @logger.debug end_date.to_s
      end
      if latest_financial_box == 1
        labels << "Latest contribution"
        row_size += 1
        latest_committee = OutsideCommittee.find(latest_financial_committee)
      end
      if annual_financial_box == 1
        this_year = DateTime.now.year
        year = this_year - annual_financial_years + 1
        annual_financial_years.times do
          labels << year.to_s + " contributions"
          year += 1          
          row_size += 1
        end
      end
      if volunteer_box == 1
        labels << "Vol. hours in the last "+volunteer_num.to_s+ " " + volunteer_timeframe
        row_size += 1
      end
      @logger.debug labels
      CSV.generate_row(labels, row_size, file_data)
      committees = campaign.committees
      entities.each do |entity|
        fields = [entity.household_id.to_s, entity.title, entity.first_name, entity.middle_name, entity.last_name, entity.name_suffix, entity.mailing_name]
        if entity.mailing_address
          fields = fields + [entity.mailing_address.line_1.to_s, entity.mailing_address.line_2.to_s, entity.mailing_address.city.to_s, entity.mailing_address.state.to_s, entity.mailing_address.zip.to_s, entity.mailing_address.zip.to_s+"-"+entity.mailing_address.zip_4.to_s]
        else
          fields = fields + [nil, nil, nil, nil, nil, nil]
        end
        fields << entity.primary_phone.to_s << number_to_phone(entity.primary_phone_number.to_s)
        #email
        if entity.primary_email
          fields << entity.primary_email.label << entity.primary_email.address
        else
          fields << nil << nil
        end
        if second_phone == 1
          if entity.phones.class == Hash and entity.phones.length >= 2
            other_phones = entity.phones.dup
            other_phones.delete(entity.primary_phone)
            other_phones.to_a.first
            fields << other_phones.to_a.first[0] << number_to_phone(other_phones.to_a.first[1])
          else
            fields << nil << nil
          end
        end
        if total_financial == 1
          contribs_array = entity.contribs_by_date(total_committee.id,false,start_date,end_date)
          value = 0
          unless contribs_array.nil? or contribs_array.length == 0
            contribs_array.each do |contrib|
              value += contrib.amount
            end
          end
          fields << value
        end
        if latest_financial_box == 1
          contrib = entity.contribs_by_date(latest_committee.id,true)
          value = 0
          unless contrib.nil?
              value += contrib.amount
          end
          fields << value
        end    
        if annual_financial_box == 1
          year = this_year - annual_financial_years + 1
          annual_financial_years.times do
            annual_start_date = Date.civil(year).to_time
            annual_end_date = Date.civil(year+1).to_time - 1.second
            year_value = 0
            value = 0
            contributions = entity.contributions.find(:all, :conditions=>["date BETWEEN :start AND :end",{:start=>annual_start_date, :end=>annual_end_date}])
            contributions.each do |contrib|
              year_value += contrib.amount
            end
            fields << year_value
            year += 1          
          end
        end
        if volunteer_box == 1
          vol_end_date = DateTime.now
          if volunteer_timeframe == "days"
            vol_start_date = volunteer_num.days.ago
          elsif volunteer_timeframe == "weeks"
            vol_start_date = volunteer_num.weeks.ago
          elsif volunteer_timeframe == "months"
            vol_start_date = volunteer_num.months.ago
          elsif volunteer_timeframe == "years"
            vol_start_date = volunteer_num.years.ago
          end
          fields << entity.total_volunteer_minutes(vol_start_date,vol_end_date).to_f/60.to_f
        end
        CSV.generate_row(fields, row_size, file_data)
      end
      unless text.nil?     
        missed_contact_events = []
        entities.each do |entity|
          if already_recorded.empty? or !already_recorded.include?(entity)
            contact_event = ContactEvent.new(:entity_id=>entity.id, :contact_text_id=>text.id, :when_contact=>Time.now, :initiated_by=>"Campaign", :interaction=>false, :form=>"Letter", :campaign_id=>text.campaign_id)
            contact_event.save!
          end
          
          if @event # this letter is an event invitation
            rsvp = entity.event_rsvp(@event)
            if rsvp
              rsvp.update_attribute(:invited, true)
            else
              rsvp = Rsvp.new(:entity_id=>entity.id, :campaign_event_id=>@event.id, :invited=>true)
              rsvp.save!
            end
          end
        end
      end
      
      file_record = ExportedFile.new(:filename=>filename, :campaign_id=>campaign.id, :num_entries=>entities.length,:downloaded=>false,:created_by=>user.id)

      if file_record.save
        @logger.info file_path
        File.open(file_path, "wb") { |f| f.write file_data }    
      end
    end
    terminate
    # kill()
  end
  
end
