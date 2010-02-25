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
require 'pdf/writer'

class ExportCallSheetsWorker < BackgrounDRb::Rails
  
  attr_reader :progress
  @job_ctrl = true
  
  def number_to_phone(number)
    number.to_s.gsub(/([0-9]{3})([0-9]{3})([0-9]{4})/,"(\\1) \\2#{"-"}\\3")
  end

  def number_with_precision(number, precision=3)
    sprintf("%01.#{precision}f", number)
  end

  def number_with_delimiter(number, delimiter=",")
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end

  def number_to_currency(number, options = {})
    options = options.stringify_keys
    precision, unit, separator, delimiter = options.delete("precision") { 2 }, options.delete("unit") { "$" }, options.delete("separator") { "." }, options.delete("delimiter") { "," }
    separator = "" unless precision > 0
    begin
      parts = number_with_precision(number, precision).split('.')
      unit + number_with_delimiter(parts[0], delimiter) + separator + parts[1].to_s
    rescue
      number
    end
  end

  def cut_to_length(string, length)
    length = length.to_i
    if string.length > length
      return string[0..length-4]+"..."
    else
      return string
    end
  end

  def do_work(args)
    #args: filename, entity_id_array, file_path_prefix, campaign_id
    @progress = 0
    filename = args[:filename]
    file_path = args[:file_path_prefix].to_s + args[:campaign_id].to_s + "/" + filename
    entity_id_array = args[:entity_id_array]
    entities = Entity.find(entity_id_array)
    
    file_record = ExportedFile.new(:filename=>filename, :campaign_id=>args[:campaign_id], :num_entries=>entities.length,:downloaded=>false)
    
    if file_record.save
      @paper = 'Letter'
      pdf = PDF::Writer.new( :paper => @paper )

      @font_tr = "Times-Roman"
      @font_hel = "Helvetica"
      @font_8=8
      @font_10=10
      @font_12=12
      @font_14=14
      @font_18=18
      @font_24=24
      @font_36=36

      pdf.select_font(@font_hel)
      pdf.margins_pt(36)

      pages = entities.length
      count = 1
      entities.each do |entity|
        start = count

        name_x = pdf.absolute_left_margin
        name_y = pdf.absolute_top_margin-@font_36
        pdf.add_text(name_x,name_y,entity.mailing_name, @font_36)

        # Address
        address_x = pdf.absolute_left_margin
        address_0_y = name_y-10-@font_36
        pdf.add_text(address_x,address_0_y,"<b>#{entity.primary_address.label}</b>", @font_14)
        address_1_y = address_0_y-5-@font_14
        pdf.add_text(address_x,address_1_y,entity.primary_address.line_1.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_14)
        address_2_y = address_1_y-@font_14
        if entity.primary_address.line_2.to_s != ""
          pdf.add_text(address_x,address_2_y,entity.primary_address.line_2.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_14)
          address_3_y = address_2_y-@font_14
          pdf.add_text(address_x,address_3_y,"#{entity.primary_address.city.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.primary_address.state} #{entity.primary_address.zip}", @font_14)
        else
          pdf.add_text(address_x,address_2_y,"#{entity.primary_address.city.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.primary_address.state} #{entity.primary_address.zip}", @font_14)    
        end

        # Phone #
        phone_x = pdf.in2pts 4.25
        phone_0_y = address_0_y
        pdf.add_text(phone_x,phone_0_y,"<b>Phone:</b>", @font_14)
        phone_1_y = phone_0_y-5-@font_14
        pdf.add_text(phone_x,phone_1_y,"<b>#{entity.primary_phone}:</b> "+number_to_phone(entity.primary_phone_number), @font_14)
        if entity.phones.length > 1
          other_phones = entity.phones.dup
          other_phones.delete(entity.primary_phone)
          phone_2 = other_phones.to_a[0]
          phone_2_y = phone_1_y-@font_14
          pdf.add_text(phone_x,phone_2_y,"<b>#{phone_2[0]}:</b> "+number_to_phone(phone_2[1]), @font_14)
          if entity.phones.length > 2
            phone_3 = other_phones.to_a[1]
            phone_3_y = phone_2_y-@font_14
            pdf.add_text(phone_x,phone_3_y,"<b>#{phone_3[0]}:</b> "+number_to_phone(phone_3[1]), @font_14)
          end
        end

        # Email address
        email_x = pdf.in2pts 4.25
        email_0_y = phone_0_y-75
        pdf.add_text(email_x,email_0_y,"<b>Email:</b>", @font_14)
        email_1_y = email_0_y-5-@font_14
        if entity.primary_email and entity.primary_email_address
          pdf.add_text(email_x,email_1_y,"<b>#{entity.primary_email.label if entity.primary_email}:</b> "+entity.primary_email_address.to_s, @font_14)
        end
        if entity.email_addresses.length > 1
          other_emails = entity.email_addresses.dup
          other_emails.delete(entity.primary_email)
          email_2 = other_emails[0]
          email_2_y = email_1_y-@font_14
          pdf.add_text(email_x,email_2_y,"<b>#{email_2.label}:</b> "+email_2.address, @font_14)
          if entity.email_addresses.length > 2
            email_3 = other_emails[1]
            email_3_y = email_2_y-@font_14
            pdf.add_text(email_x,email_3_y,"<b>#{email_3.label}:</b> "+email_3.address, @font_14)
          end
        end

        # Household
        hh = entity.household
        hh_members = hh.people.dup
        hh_members.delete(entity)
        hh_members = hh_members[0,3]
        household_x = pdf.absolute_left_margin
        household_0_y = address_0_y-75
        pdf.add_text(household_x,household_0_y,"<b>Household:</b>", @font_14)
        household_y = household_0_y-5-@font_14
        pdf.add_text(household_x,household_y,entity.name, @font_14)
        hh_members.each do |member|
          household_y = household_y-@font_14-1
          pdf.add_text(household_x,household_y,member.name, @font_14)    
        end

        contrib_history_start = 502
        # Contribution history table
        pdf.move_to(pdf.absolute_left_margin, contrib_history_start+23).line_to(pdf.absolute_right_margin, contrib_history_start+23)
        pdf.add_text(36,502,"<b>Contributions</b>", @font_18)  
        pdf.move_to(pdf.absolute_left_margin, contrib_history_start-12).line_to(pdf.absolute_right_margin, contrib_history_start-12)
        pdf.add_text(36,contrib_history_start-29,"<b>Recent contributions</b>", @font_14)
        pdf.add_text(36,contrib_history_start-47,"<b>Date</b>", @font_14)
        pdf.add_text(105,contrib_history_start-47,"<b>Recipient</b>", @font_14)
        pdf.add_text(380,contrib_history_start-47,"<b>Amount</b>", @font_14)
        pdf.add_text(450,contrib_history_start-47,"<b>Event</b>", @font_14) #Event/Letter/Script/Email
        pdf.move_to(pdf.absolute_left_margin, contrib_history_start-55).line_to(pdf.absolute_right_margin, contrib_history_start-55)
        contribs = entity.recent_contributions(5)
        first_contrib_row = contrib_history_start-72
        row_count = 0
        contribs.each do |contribution|
          pdf.add_text(36,first_contrib_row-row_count*15,contribution.date.strftime("%m/%d/%Y"), @font_12)
          pdf.add_text(105,first_contrib_row-row_count*15,cut_to_length(contribution.recipient_name,45), @font_12)
          pdf.add_text(380,first_contrib_row-row_count*15,number_to_currency(contribution.amount), @font_12)
          if contribution.campaign_event
            pdf.add_text(450,first_contrib_row-row_count*15,cut_to_length(contribution.campaign_event.name, 20), @font_12)
            # elsif contribution.contact_text
          end
          row_count +=1
        end

        # contribution totals: top 5 recipients
        recipient_top = contrib_history_start - 159
        pdf.move_to(pdf.absolute_left_margin, recipient_top+17).line_to(pdf.absolute_right_margin, recipient_top+17)
        pdf.add_text(36,recipient_top,"<b>Contribution totals</b>", @font_14)
        pdf.add_text(36,recipient_top-18,"<b>Recipient</b>", @font_14)
        pdf.add_text(380,recipient_top-18,"<b>Total</b>", @font_14)
        pdf.move_to(pdf.absolute_left_margin, recipient_top-26).line_to(pdf.absolute_right_margin, recipient_top-26)
        recipients = entity.top_recent_recipients(5)
        row_count = 0
        recipients.each do |recipient|
          pdf.add_text(36,recipient_top-43-row_count*15,cut_to_length(recipient[0], 45), @font_12)
          pdf.add_text(380,recipient_top-43-row_count*15,number_to_currency(recipient[1]), @font_12)
          row_count+=1
        end

        # pledged contributions?

        # Event status (past and future) (next 3 and past 3?)
        start_events = contrib_history_start-295
        pdf.move_to(pdf.absolute_left_margin, start_events+23).line_to(pdf.absolute_right_margin, start_events+23)
        pdf.add_text(36,start_events,"<b>Events</b>", @font_18)  
        pdf.move_to(pdf.absolute_left_margin, start_events-12).line_to(pdf.absolute_right_margin, start_events-12)
        pdf.add_text(36,start_events-29,"<b>Date</b>", @font_14)
        pdf.add_text(105,start_events-29,"<b>Event</b>", @font_14)
        pdf.add_text(300,start_events-29,"<b>Inv.</b>", @font_14)
        pdf.add_text(340,start_events-29,"<b>Resp.</b>", @font_14)
        pdf.add_text(380,start_events-29,"<b>Attend</b>", @font_14)
        pdf.add_text(430,start_events-29,"<b>Pledge</b>", @font_14)
        pdf.add_text(500,start_events-29,"<b>Contrib.</b>", @font_14)
        pdf.move_to(pdf.absolute_left_margin, start_events-37).line_to(pdf.absolute_right_margin, start_events-37)
        first_event_row = start_events-54
        row_count = 0
        entity.campaign_events.each do |event|
          pdf.add_text(36,first_event_row-row_count*15,event.start_time.strftime("%m/%d/%Y"), @font_12)
          pdf.add_text(105,first_event_row-row_count*15,cut_to_length(event.name,30), @font_12)
          pdf.add_text(300,first_event_row-row_count*15,entity.event_invitation(event).to_s, @font_12)
          pdf.add_text(340,first_event_row-row_count*15,entity.event_response(event).to_s, @font_12)
          pdf.add_text(380,first_event_row-row_count*15,entity.event_attendance(event).to_s, @font_12)
          pdf.add_text(430,first_event_row-row_count*15,number_to_currency(entity.pledge_value(event)), @font_12)
          pdf.add_text(500,first_event_row-row_count*15,number_to_currency(entity.event_contribution(event)), @font_12)
          row_count += 1
        end

        pdf.move_to(pdf.absolute_left_margin, first_event_row-70).line_to(pdf.absolute_right_margin, first_event_row-70)

        pdf.stroke

        pdf.new_page unless count == pages
        count += 1
      end
      @logger.info file_path

      File.open(file_path, "wb") { |f| f.write pdf.render }    
    else
      @logger.info "file record not created"
      # file record not created
    end
    @progress = 101
    terminate
    ActiveRecord::Base.connection.disconnect!
    # kill()
  end
  
end