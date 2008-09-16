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

class ExportLabelsWorker < BackgrounDRb::Rails
  
  attr_reader :progress
  

  def cell_x(col)
    [@col1_x, @col2_x, @col3_x][col] + @cell_pad_x
  end

  def cell_y(row, line)
    @marg_y + ((@labels_per_col - row) * @cell_y) - @cell_pad_y - (line * @cell_line_y)
  end

  def add_label(row, col, entity, pdf)
    if entity.class == Household
      if entity.people.length > 2
        first = entity.people[0]
        unless first.mailing_address
          first = entity.people[1]
        end
        if first.mailing_address
          last_name = first.last_name.gsub(/ñ/,"n").gsub(/Ñ/,"N")
        	pdf.add_text_wrap(cell_x(col), cell_y(row, 0), @cell_x, "The "+last_name+" Family", @font_size)
          pdf.add_text_wrap(cell_x(col), cell_y(row, 1), @cell_x, first.mailing_address.line_1.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
        	unless first.mailing_address.line_2.to_s == ""
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, first.mailing_address.line_2.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 3), @cell_x, "#{first.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{first.mailing_address.state.to_s} #{first.mailing_address.zip.to_s}", @font_size)
        	else
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, "#{first.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{first.mailing_address.state.to_s} #{first.mailing_address.zip.to_s}", @font_size)
        	end
        end
      elsif entity.people.length == 2
        first = entity.people[0]
        second = entity.people[1]
        unless first.mailing_address
          first = entity.people[1]
        end
        if first.mailing_address
          name = ""
          if first.last_name == second.last_name
            name << first.first_name << " and " << second.first_name << " " << first.last_name
          else
            name << first.mailing_name << " and " << second.mailing_name
          end
        	pdf.add_text_wrap(cell_x(col), cell_y(row, 0), @cell_x, name.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
          pdf.add_text_wrap(cell_x(col), cell_y(row, 1), @cell_x, first.mailing_address.line_1.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
        	unless first.mailing_address.line_2.to_s == ""
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, first.mailing_address.line_2.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 3), @cell_x, "#{first.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{first.mailing_address.state.to_s} #{first.mailing_address.zip.to_s}", @font_size)
        	else
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, "#{first.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{first.mailing_address.state.to_s} #{first.mailing_address.zip.to_s}", @font_size)
        	end
        end
      else # one person
        entity = entity.people.first
        if entity and entity.mailing_address
        	pdf.add_text_wrap(cell_x(col), cell_y(row, 0), @cell_x, entity.mailing_name.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
          pdf.add_text_wrap(cell_x(col), cell_y(row, 1), @cell_x, entity.mailing_address.line_1.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
        	unless entity.mailing_address.line_2.to_s == ""
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, entity.mailing_address.line_2.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 3), @cell_x, "#{entity.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.mailing_address.state.to_s} #{entity.mailing_address.zip.to_s}", @font_size)
        	else
            	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, "#{entity.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.mailing_address.state.to_s} #{entity.mailing_address.zip.to_s}", @font_size)
        	end
        end
      end
    else # organization or individual
      if entity and entity.mailing_address
      	pdf.add_text_wrap(cell_x(col), cell_y(row, 0), @cell_x, entity.mailing_name.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
        pdf.add_text_wrap(cell_x(col), cell_y(row, 1), @cell_x, entity.mailing_address.line_1.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
      	unless entity.mailing_address.line_2.to_s == ""
          	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, entity.mailing_address.line_2.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N"), @font_size)
          	pdf.add_text_wrap(cell_x(col), cell_y(row, 3), @cell_x, "#{entity.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.mailing_address.state.to_s} #{entity.mailing_address.zip.to_s}", @font_size)
      	else
          	pdf.add_text_wrap(cell_x(col), cell_y(row, 2), @cell_x, "#{entity.mailing_address.city.to_s.gsub(/ñ/,"n").gsub(/Ñ/,"N")}, #{entity.mailing_address.state.to_s} #{entity.mailing_address.zip.to_s}", @font_size)
      	end
      end
    end
  end
  
  def do_work(args)
    #args: filename, text_id, join_households, entity_id_array, campaign_id, file_path_prefix
    @progress = 0
    sort_field = args[:sort_field]
    filename = args[:filename]
    file_path = args[:file_path_prefix].to_s + args[:campaign_id].to_s + "/" + filename
    join_households = args[:join_households]
    text = ContactText.find(args[:text_id]) unless args[:text_id] == "mypeople"
    unless text.nil?
      if text.campaign_event_id and text.campaign_event_id.to_i > 0
        @event = CampaignEvent.find(text.campaign_event_id)
      end
    end
    entity_id_array = args[:entity_id_array]
    entities = Entity.find(entity_id_array)
    
    if join_households
      households = []
      organizations = []
      entities.each do |entity|
        if entity.mailing_address and entity.mailing_address.line_1.to_s != "" and entity.mailing_address.city.to_s != "" and entity.mailing_address.state.to_s != "" and entity.mailing_address.zip.to_s != ""
          if entity.class == Person
            households << entity.household
          else
            organizations << entity
          end
        end
      end
      households.uniq!
      organizations.uniq!
      entities = organizations.dup
      households.each do |hh|
        hh.people.each do |person|
          entities << person
        end
      end
      if sort_field == "name"
        households = households.sort_by { |h| [h.last_name, h.id] }
        organizations = organizations.sort_by {|o| [o.class.to_s, o.name] }
        entities = organizations + households
      elsif sort_field == "zip"
        households = households.sort_by { |h| [h.zip_code.to_s, h.last_name, h.id] }
        organizations = organizations.sort_by {|o| [o.zip_code.to_s, o.class.to_s, o.name] }
        entities = organizations + households
        entities = entities.sort_by {|entity| [entity.zip_code.to_s]}
      end
    else
      temp = []
      organizations = []
      entities.each do |entity|
        if entity.mailing_address and entity.mailing_address.line_1.to_s != "" and entity.mailing_address.city.to_s != "" and entity.mailing_address.state.to_s != "" and entity.mailing_address.zip.to_s != ""
          temp << entity
        end
      end
      temp.uniq!
      entities = temp
      if sort_field == "name"
        entities = entities.sort_by {|entity| [entity.class.to_s, entity.household_last_name.to_s, entity.household_id]}
      elsif sort_field == "zip"
        entities = entities.sort_by {|entity| [entity.zip_code.to_s, entity.class.to_s, entity.household_last_name.to_s, entity.household_id]}
      end
    end
    unless text.nil?
      already_recorded = text.recipients
      missed_contact_events = []
      entities.each do |entity|
       # begin
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
       # rescue
       #   missed_contact_events << entity
       # end
      end
    end
    
    num_labels = entities.length

    file_record = ExportedFile.new(:filename=>filename, :campaign_id=>args[:campaign_id], :num_entries=>num_labels,:downloaded=>false)
    
    if file_record.save
      @paper = 'Letter'
      pdf = PDF::Writer.new( :paper => @paper )

      @font = "Times-Roman"
      @font_size = 12

      @cols = 3
      @labels_per_page = 30
      @labels_per_col = 10

      # margins: .5in top & bottom, 0.19 in left and right
      # table column widths: 2.63in | 0.13in | 2.63in | 0.13in | 2.63in
      # table rows: 1in height

      @marg_x = pdf.in2pts 0.19
      @marg_y = pdf.in2pts 0.5

      @cell_y = pdf.in2pts 1
      @cell_x = pdf.in2pts 2.63

      @col_pad_x = pdf.in2pts 0.19

      @col1_x = @marg_x 
      @col2_x = @col1_x + @cell_x + @col_pad_x
      @col3_x = @col2_x + @cell_x + @col_pad_x

      @cell_pad_x = pdf.in2pts 0.13
      @cell_pad_y = pdf.in2pts 0.25
      @cell_line_y = @font_size + 2

      pdf.compressed = true if RAILS_ENV != 'development'

      pdf.select_font(@font)

      pages = num_labels / @labels_per_page
      pages += 1 if (num_labels % @labels_per_page) > 0

      0.upto(pages - 1) do |page|
        start = page * @labels_per_page
        address_page = entities[start..start+@labels_per_page]

        0.upto(@labels_per_col - 1) do |row|
          add_label(row, 0, address_page[row*@cols], pdf)
          add_label(row, 1, address_page[row*@cols+1], pdf)
          add_label(row, 2, address_page[row*@cols+2], pdf)
        end

        @progress = ((page+1)*100.0/pages).round
        # sleep 30
        pdf.new_page unless page + 1 == pages
      end

      @logger.info file_path

      File.open(file_path, "wb") { |f| f.write pdf.render }    
    else
      # TODO: notify the user that the file didn't save correctly
    end
    terminate
    # kill()
  end
  
end
