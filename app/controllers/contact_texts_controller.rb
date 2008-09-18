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

class ContactTextsController < ApplicationController

  layout 'contact_texts'
  
  before_filter :get_campaign
  
  before_filter :load_text_and_check_campaign, :except=>[:list, :compose, :create_or_update, :generate_email_preview, :send_or_save_email, :labels, :load_sent_emails, :load_draft_emails, :load_draft_letters, :load_sent_letters, :load_scripts, :download_mail_file, :prepare_labels]
  before_filter :check_campaign, :only=>[:list, :compose, :create_or_update, :send_or_save_email, :load_sent_emails, :load_draft_emails, :load_draft_letters, :load_sent_letters, :load_scripts, :labels, :download_mail_file]
  
  #TODO: this doesn't seem to actually catch anything
  verify :method => :post, :only => [ :destroy_email ],
         :redirect_to => { :controller=>:campaigns, :action => :start_here }

  def list
    @draft_email_pages, @draft_emails = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Email\' AND (complete = :false OR complete IS NULL)', {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
    @sent_email_pages, @sent_emails = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Email\' AND complete = :true', {:campaign=>@campaign.id, :true=>true}], :order=>'updated_at DESC'
    @draft_letter_pages, @draft_letters = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Letter\' AND (complete = :false OR complete IS NULL)', {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
    @sent_letter_pages, @sent_letters = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Letter\' AND complete = :true', {:campaign=>@campaign.id, :true=>true}], :order=>'updated_at DESC'
    @script_pages, @scripts = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Script\'', {:campaign=>@campaign.id}], :order=>'updated_at DESC'
  end
  
  def load_draft_emails
    @draft_email_pages, @draft_emails = paginate :contact_texts, :per_page => 5, :conditions=>["campaign_id = :campaign AND type='Email' AND (complete = :false OR complete IS NULL)", {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
    render :partial=>"draft_emails_table"
  end

  def load_sent_emails
    @sent_email_pages, @sent_emails = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Email\' AND complete = :true', {:campaign=>@campaign.id, :true=>true}], :order=>'updated_at DESC'
    render :partial=>"sent_emails_table"
  end

  def load_draft_letters
    @draft_letter_pages, @draft_letters = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Letter\' AND (complete = :false OR complete IS NULL)', {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
    render :partial=>"draft_letters_table"
  end

  def load_sent_letters
    @sent_letter_pages, @sent_letters = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Letter\' AND complete = :true', {:campaign=>@campaign.id, :true=>true}], :order=>'updated_at DESC'
    render :partial=>"sent_letters_table"
  end

  def load_scripts
    @script_pages, @scripts = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type="Script"', {:campaign=>@campaign.id}], :order=>'updated_at DESC'
    render :partial=>"scripts_table"
  end
  
  def compose
    @recent_events = @campaign.get_recent_events
    if params[:type]
      @type = params[:type]
    elsif params[:contact_text] and params[:contact_text][:type]
      @type = params[:contact_text][:type]
    end
    if @type == "Email"
      if params[:id] and params[:id] != "new"
        @message = Email.find(params[:id])
        if @message.stylesheet.nil?
          @stylesheet = Stylesheet.new()
          @message.stylesheet = @stylesheet
        else
          @stylesheet = @message.stylesheet
        end
        @id = @message.id        
      elsif params[:based_on]
        old_message = Email.find(params[:based_on])
        @stylesheet = old_message.stylesheet
        @message = old_message
        @message.id = nil
        @message.complete = false
        @id = "new"
      else
        @message = Email.new()
        @stylesheet = Stylesheet.new(:name=>"default")
        @message.stylesheet = @stylesheet
        @id = "new"
        @message.text = "Headline\n=======\n\ntext"
      end
      @stylesheets = @campaign.stylesheets.find(:all, :order=>"updated_at DESC")
      @stylesheets.sort! { |b, a| a.emails.length <=> b.emails.length}        
      @message.text.gsub!(/`/,"")
      render(:action=>"contact_texts/compose_email") and return
    elsif @type == "PlainEmail"
      if params[:id] and params[:id] != "new"
        @message = Email.find(params[:id])
        @id = @message.id        
      elsif params[:based_on]
        old_message = Email.find(params[:based_on])
        @message = old_message.dup
        @message.id = nil
        @message.complete = false
        @id = "new"
      else
        @message = Email.new()
        @id = "new"
        @message.text = "Headline\n=======\n\ntext"
      end
      @message.text.gsub!(/`/,"")
      render(:action=>"contact_texts/compose_plaintext_email") and return
    elsif @type == "Letter"
      if params[:id] and params[:id] != "new"
        @contact_text = Letter.find(params[:id])
      else 
        @contact_text = Letter.new()
      end
    elsif @type == "Script"
      if params[:id] and params[:id] != "new"
        @contact_text = Script.find(params[:id])
      else 
        @contact_text = Script.new()
      end
    end    
  end
  
  def create_or_update
    unless params[:contact_text][:invitation] == "true"
      params[:contact_text].delete(:campaign_event_id)
    end
    params[:contact_text].delete(:invitation)
    if params[:id]
      @text = ContactText.find(params[:id])
      if session[:user].active_campaigns.include?(@campaign.id) and @text.campaign_id == @campaign.id
        unless params[:entity].nil?
          params[:contact_text][:updated_by]=session[:user].id
        end
      else
        @text = nil
        @campaign = nil
        render :partial=>"user/not_available"
        return
      end
      unless @text.update_attributes(params[:contact_text])
        raise
      end
    else
      params[:contact_text][:campaign_id] = @campaign.id
      if params[:contact_text][:type]=="Letter"
        @text = Letter.new(params[:contact_text])
        flash[:notice] = 'Letter was successfully created.'
      elsif params[:contact_text][:type]=="Script"
        @text = Script.new(params[:contact_text])
        flash[:notice] = 'Script was successfully created.'
      end
    end
    @text.text.gsub!(/`/,"")
    @text.save!
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  rescue
    flash[:notice] = nil
    flash[:warning] = 'Error saving contact text.'
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  end

  def show # for letters and scripts
    if @text.class==Email
      @message = @text
      @stylesheet = @text.stylesheet
      @show_only = true
      if @stylesheet
        render "contact_texts/compose_email"
      else
        render "contact_texts/compose_plaintext_email"        
      end
      return    
    else
    end
  end
  
  def destroy_email
    ContactText.find(params[:id]).destroy
    @draft_email_pages, @draft_emails = paginate :contact_texts, :per_page => 5, :conditions=>['campaign_id = :campaign AND type=\'Email\' AND (complete = :false OR complete IS NULL)', {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
    # redirect_to :action => 'list', :protocol=>@@protocol
  end
  
  def show_recipient_list
    @recipients = @text.recipients 
    # TODO: this sort will fail if there are multiple kind of entities represented
    @recipients = @recipients.sort {|a,b| [a.last_name.to_s,a.name.to_s,a.first_name.to_s] <=> [b.last_name.to_s,b.name.to_s,b.first_name.to_s] }
    @entity_pages, @entities = paginate_collection @recipients, :per_page=>25, :page=>params[:page]
  end
  
  def generate_email_preview
    params[:contact_text].delete(:invitation)
    @message = Email.new(params[:contact_text])
    if params[:contact_text][:stylesheet_id] == ""
      
      params[:stylesheet] = make_web_color(params[:stylesheet],:p_color_red,:p_color_green,:p_color_blue,:p_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:a_color_red,:a_color_green,:a_color_blue,:a_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:h1_color_red,:h1_color_green,:h1_color_blue,:h1_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:h2_color_red,:h2_color_green,:h2_color_blue,:h2_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:h3_color_red,:h3_color_green,:h3_color_blue,:h3_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:h4_color_red,:h4_color_green,:h4_color_blue,:h4_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:h5_color_red,:h5_color_green,:h5_color_blue,:h5_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:hr_color_red,:hr_color_green,:hr_color_blue,:hr_color)
      params[:stylesheet] = make_web_color(params[:stylesheet],:side_bg_red,:side_bg_green,:side_bg_blue,:side_bg)
      params[:stylesheet] = make_web_color(params[:stylesheet],:title_bg_red,:title_bg_green,:title_bg_blue,:title_bg)
      params[:stylesheet] = make_web_color(params[:stylesheet],:body_bg_red,:body_bg_green,:body_bg_blue,:body_bg)
      params[:stylesheet][:hr_width] = params[:stylesheet][:hr_width].to_i.to_s
      @stylesheet = Stylesheet.new(params[:stylesheet])
    else
      @stylesheet = Stylesheet.find(params[:contact_text][:stylesheet_id])
    end
    @message.stylesheet = @stylesheet
    @message.text.gsub!(/`/,"")
    render :partial=>"email_preview"
  end

  def preview_email
    @text.text.gsub!(/`/,"")
  end
  
  def send_test_email
    addresses = params[:contact_text][:addresses]
    if @text.stylesheet
      email = Mailer.create_message(@text, @text.stylesheet, addresses)
    else
      email = Mailer.create_plaintext_message(@text, addresses)      
    end
    logger.debug "message created"
    Mailer.deliver(email)
    logger.debug "message delivered"
    render_text "Test message sent."
  rescue
    render_text "<b>Error sending text message.</b>"
  end
  
  def send_email_to_cart
    @stylesheet = @text.stylesheet
    entities = current_user.entities
    # addresses = []
    sent_entities = []
    entities.each do |entity|
      if entity.receive_email? or entity.receive_email.nil?
        if entity.primary_email_address.to_s.strip != ""
          # addresses << entity.primary_email_address
          if entity.primary_email.valid
            sent_entities << entity.id
          end
        end
      end
    end
    sent_entities.uniq!
    unless sent_entities.empty?
      key_name = "bulk_email_key_"+@text.id.to_s
      #  logger.debug key_name
      #  logger.debug addresses
      #  logger.debug addresses.first.class
      if @stylesheet
        MiddleMan.new_worker(:class=>:bulk_email_worker, :args=>{:text_id=>@text.id, :sent_entity_ids=>sent_entities, :stylesheet_id=>@stylesheet.id}, :job_key=>key_name.to_sym)
      else
        MiddleMan.new_worker(:class=>:bulk_email_worker, :args=>{:text_id=>@text.id, :sent_entity_ids=>sent_entities, :stylesheet_id=>nil}, :job_key=>key_name.to_sym)        
      end
      flash[:notice] = "Message is being sent now."
    else
      flash[:warning] = "Error: No email addresses to send your message to."
    end
    redirect_to :action=>"list", :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
#  rescue
#    flash[:warning] = "There was an error. Email not sent."
#    redirect_to :action=>"list", :params=>{:campaign_id=>@campaign.id}
  end
  
  def check_email_progress
    key_name = "bulk_email_key_"+params[:id]
    unless MiddleMan[key_name.to_sym].progress == 101
      @draft_email_pages, @draft_emails = paginate :contact_texts, :per_page => 5, :conditions=>["campaign_id = :campaign AND type='Email' AND (complete = :false OR complete IS NULL)", {:campaign=>@campaign.id, :false=>false}], :order=>'updated_at DESC'
      render :update do |page|
        page.replace_html "draft_emails", render(:partial=>"draft_emails_table")
      end
    else
      MiddleMan.delete_worker(key_name.to_sym)
      render :update do |page|
        page.redirect_to :action=>'list', :protocol=>@@protocol
      end
    end
  end

  def send_or_save_email
    unless params[:contact_text][:invitation] == "true"
      params[:contact_text].delete(:campaign_event_id)
    end
    params[:contact_text].delete(:invitation)
    plain = true if (params[:contact_text][:plaintext] and params[:contact_text][:plaintext] == "true")
    params[:contact_text].delete(:plaintext)
    if plain
      ContactText.transaction do
        if params[:contact_text][:id] == "new"
          logger.debug "new message"
          @message = Email.new(params[:contact_text])
          @message.label = @message.subject
        else
          logger.debug "editting an existing message"
          @message = Email.find(params[:contact_text][:id])
          logger.debug "message found"
          unless @message.update_attributes(params[:contact_text])
            raise
          end
          @message.label = @message.subject          
        end
        @message.stylesheet = nil
        @message.save!
        flash[:notice] = "Message saved successfully."
        redirect_to :action=>"list", :params=>{:campaign_id=>@campaign.id}
      end
    else
      ContactText.transaction do
        Stylesheet.transaction do
          if params[:contact_text][:id] == "new"
            logger.debug "new message"
            @message = Email.new(params[:contact_text])
            @message.label = @message.subject
            if params[:contact_text][:stylesheet_id] == ""
              params[:stylesheet] = make_web_color(params[:stylesheet],:p_color_red,:p_color_green,:p_color_blue,:p_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:a_color_red,:a_color_green,:a_color_blue,:a_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h1_color_red,:h1_color_green,:h1_color_blue,:h1_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h2_color_red,:h2_color_green,:h2_color_blue,:h2_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h3_color_red,:h3_color_green,:h3_color_blue,:h3_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h4_color_red,:h4_color_green,:h4_color_blue,:h4_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h5_color_red,:h5_color_green,:h5_color_blue,:h5_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:hr_color_red,:hr_color_green,:hr_color_blue,:hr_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:side_bg_red,:side_bg_green,:side_bg_blue,:side_bg)
              params[:stylesheet] = make_web_color(params[:stylesheet],:title_bg_red,:title_bg_green,:title_bg_blue,:title_bg)
              params[:stylesheet] = make_web_color(params[:stylesheet],:body_bg_red,:body_bg_green,:body_bg_blue,:body_bg)
              params[:stylesheet][:hr_width] = params[:stylesheet][:hr_width].to_i.to_s
              @stylesheet = Stylesheet.new(params[:stylesheet])
              @stylesheet.campaign_id = @campaign.id
              @stylesheet.save!
            else
              @stylesheet = Stylesheet.find(params[:contact_text][:stylesheet_id])
            end
            @message.save!
          else
            logger.debug "editting an existing message"
            @message = Email.find(params[:contact_text][:id])
            logger.debug "message found"
            unless @message.update_attributes(params[:contact_text])
              raise
            end
            @message.label = @message.subject
            if params[:contact_text][:stylesheet_id] == ""
              params[:stylesheet] = make_web_color(params[:stylesheet],:p_color_red,:p_color_green,:p_color_blue,:p_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:a_color_red,:a_color_green,:a_color_blue,:a_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h1_color_red,:h1_color_green,:h1_color_blue,:h1_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h2_color_red,:h2_color_green,:h2_color_blue,:h2_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h3_color_red,:h3_color_green,:h3_color_blue,:h3_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h4_color_red,:h4_color_green,:h4_color_blue,:h4_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:h5_color_red,:h5_color_green,:h5_color_blue,:h5_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:hr_color_red,:hr_color_green,:hr_color_blue,:hr_color)
              params[:stylesheet] = make_web_color(params[:stylesheet],:side_bg_red,:side_bg_green,:side_bg_blue,:side_bg)
              params[:stylesheet] = make_web_color(params[:stylesheet],:title_bg_red,:title_bg_green,:title_bg_blue,:title_bg)
              params[:stylesheet] = make_web_color(params[:stylesheet],:body_bg_red,:body_bg_green,:body_bg_blue,:body_bg)
              params[:stylesheet][:hr_width] = params[:stylesheet][:hr_width].to_i.to_s
              @stylesheet = Stylesheet.new(params[:stylesheet])
              @stylesheet.campaign_id = @campaign.id
              @stylesheet.save!
            else
              @stylesheet = Stylesheet.find(params[:contact_text][:stylesheet_id])
            end
          end
          @message.stylesheet = @stylesheet
          @message.formatted_text = BlueCloth.new(@message.text.to_s).to_html.gsub(/<h1>/,'<div class="h1_block"><h1>').gsub(/<\/h1>/,'</h1></div>')
          @message.save! 
          flash[:notice] = "Message saved successfully."
          redirect_to :action=>"list", :params=>{:campaign_id=>@campaign.id}
        end
      end
    end
#  rescue
#    logger.debug "in rescue clause"
#    flash[:warning] = "Message send or save failed."
#    redirect_to :action=>"new", :params=>{:id=>params[:contact_text][:id], :type => "Email"}
  end

  def prepare_labels
    unless params[:id] == "mypeople"
      @text_id = params[:id]
    else
      @text_id = "mypeople"
    end
  end

  def labels
    if params[:labels] and params[:labels][:join_households].to_i == 1
      @join_households = true
    else
      @join_households = false
    end
    
    if params[:labels] and params[:labels][:sort_field] == "Zip"
      sort_field = "zip"
    else
      sort_field = "name"
    end

    entity_id_array = []
    current_user.entities.each do |entity|
      entity_id_array << entity.id
    end
    if params[:labels] and params[:labels][:filename] and (params[:labels][:filename] != "Please enter a file name")
      filename = params[:labels][:filename][0..28]
      if filename[-4..-1] != ".pdf"
        filename = filename+".pdf"
      end
    else
      filename = "labels_"+Time.now.strftime("%m_%d_%Y_%H_%M")+".pdf"
    end
    filename.gsub!(/[\s\/:]+/,"_")
    
    key_name = "export_key_"+filename
    MiddleMan.new_worker(:class=>:export_labels_worker, :args=>{:text_id=>params[:id], :entity_id_array=>entity_id_array, :filename=>filename, :join_households=>@join_households, :sort_field=>sort_field, :campaign_id=>@campaign.id, :file_path_prefix=>@@file_path_prefix}, :job_key=>key_name.to_sym)
    flash[:notice] = "Labels are being prepared now."
    
    redirect_to :action=>"list", :protocol=>@@protocol
  end
  
  def mail_file
  
  end
  
  def download_mail_file
    entity_id_array = []
    current_user.entities.each do |entity|
      entity_id_array << entity.id
    end
    if params[:mail_merge] and params[:mail_merge][:filename] and (params[:mail_merge][:filename] != "Please enter a file name")
      filename = params[:mail_merge][:filename]
      if filename[-4..-1] != ".csv"
        filename = filename+".csv"
      end
    else
      filename = "mail_file_"+Time.now.strftime("%m_%d_%Y_%H_%M")+".csv"
    end
    filename.gsub!(/[\s\/:]+/,"_")
    
    key_name = "export_key_"+filename

    if params[:id]=="mypeople"
      MiddleMan.new_worker(:class=>:export_csv_worker, :args=>{
        :text_id=>params[:id], 
        :entity_id_array=>entity_id_array, 
        :filename=>filename,
        :campaign_id=>@campaign.id, 
        :file_path_prefix=>@@file_path_prefix, 
        :delete_blank_addresses=>0,
        :second_phone=>0,
        :total_financial_box=>0,
        :total_financial_timeframe=>"days",
        :total_financial_committee=>nil,
        :latest_financial_box=>0,
        :latest_financial_committee=>nil,
        :annual_financial_box=>0,
        :annual_financial_years=>nil,
        :volunteer_box=>0,
        :volunteer_timeframe=>"days",
        :volunteer_num=>1,
        :user_id=>current_user.id,
        :job_key=>key_name.to_sym})
        flash[:notice] = "Your mail merge file is being prepared now."
    elsif params[:mail_merge]
      MiddleMan.new_worker(:class=>:export_csv_worker, :args=>{
        :text_id=>params[:id], 
        :entity_id_array=>entity_id_array, 
        :filename=>filename,
        :campaign_id=>@campaign.id, 
        :file_path_prefix=>@@file_path_prefix, 
        :delete_blank_addresses=>params[:mail_merge][:delete_blank_addresses],
        :second_phone=>params[:mail_merge][:phone].to_i,
        :total_financial_box=>params[:mail_merge][:total_financial_box].to_i,
        :total_financial_timeframe=>params[:mail_merge][:total_financial_timeframe],
        :total_financial_committee=>params[:mail_merge][:total_financial_committee],
        :latest_financial_box=>params[:mail_merge][:latest_financial_box],
        :latest_financial_committee=>params[:mail_merge][:latest_financial_committee],
        :annual_financial_box=>params[:mail_merge][:annual_financial_box].to_i,
        :annual_financial_years=>params[:mail_merge][:annual_financial_years].to_i,
        :volunteer_box=>params[:mail_merge][:volunteer_box].to_i,
        :volunteer_timeframe=>params[:mail_merge][:volunteer_timeframe],
        :volunteer_num=>params[:mail_merge][:volunteer_num].to_i,
        :user_id=>current_user.id,
        :job_key=>key_name.to_sym})
      flash[:notice] = "Your mail merge file is being prepared now."
    else
      flash[:warning] = "There was an error.  Please email open.campaigns@gmail.com and tell Asa."      
    end
    
    redirect_to :action=>"list", :protocol=>@@protocol


    # 
    # 
    # @text = ContactText.find(params[:id]) unless params[:id] == "mypeople"
    # @entities = current_user.entities
    # temp = []
    # if params[:mail_merge] and params[:mail_merge][:delete_blank_addresses].to_i == 1
    #   @entities.each do |entity|
    #     logger.debug entity.name
    #   end
    #   logger.debug "removing entities with blank addresses"
    #   @entities.each do |entity|
    #     logger.debug entity.name        
    #     logger.debug entity.mailing_address.nil?
    #     unless entity.mailing_address.nil?
    #       logger.debug entity.mailing_address.line_1.to_s == ""
    #       logger.debug entity.mailing_address.city.to_s == ""
    #       logger.debug entity.mailing_address.state.to_s == ""
    #       logger.debug entity.mailing_address.zip.to_s == ""
    #     end
    #     unless (entity.mailing_address.nil? or entity.mailing_address.line_1.to_s == "" or entity.mailing_address.city.to_s == "" or entity.mailing_address.state.to_s == "" or entity.mailing_address.zip.to_s == "")
    #       logger.debug "adding "+entity.name
    #       temp << entity
    #     end
    #   end
    #   @entities = temp
    # end
    #     
    # # sort entities
    # # leave grouped by household
    # @entities = @entities.sort_by {|entity| [entity.class.to_s, entity.household_last_name.to_s, entity.household_id]}
    # 
    # @entities.each do |entity|
    #   logger.debug entity.name
    # end
    # 
    # if @entities.length > 0
    #   if @text.nil?
    #     file_data = "Mail merge file for MyPeople, created for #{session[:user].name} on #{Time.now.strftime('%m/%d/%Y')}:\n"
    #   else
    #     already_recorded = @text.recipients
    #     file_data = "Mail merge file for letter #{@text.label}, created for #{session[:user].name} on #{Time.now.strftime('%m/%d/%Y')}:\n"
    #   end
    #   labels = ["Household ID", "Title", "First name", "Middle name", "Last name", "Suffix", "Full name", "Address line 1", "Address line 2", "City", "State", "ZIP", "ZIP+4", "Primary Phone", "Number", "Primary Email", "Address"]
    #   row_size = labels.length
    #   #logger.debug params[:mail_merge][:total_financial_box]
    #   #logger.debug params[:mail_merge][:latest_financial_box]
    #   if params[:mail_merge] and params[:mail_merge][:phone].to_i == 1
    #     labels << "Secondary Phone" << "Number"
    #     row_size += 2
    #   end
    #   if params[:mail_merge] and params[:mail_merge][:total_financial_box].to_i == 1
    #     labels << "Total contributions in the last #{params[:mail_merge][:total_financial_timeframe]}"
    #     row_size += 1
    #     total_committee = Committee.find(params[:mail_merge][:total_financial_committee])
    #     if params[:mail_merge][:total_financial_timeframe] == "day"
    #       start_date = Time.now - 1.day
    #     elsif params[:mail_merge][:total_financial_timeframe] == "week"
    #       start_date = Time.now - 1.week      
    #     elsif params[:mail_merge][:total_financial_timeframe] == "month"
    #       start_date = Time.now - 1.month
    #     elsif params[:mail_merge][:total_financial_timeframe] == "year"
    #       start_date = Time.now - 1.year
    #     end
    #     start_date = start_date.to_date
    #     end_date = DateTime.now
    #   end
    #   if params[:mail_merge] and params[:mail_merge][:latest_financial_box].to_i == 1
    #     labels << "Latest contribution"
    #     row_size += 1
    #     latest_committee = Committee.find(params[:mail_merge][:latest_financial_committee])
    #   end
    #   if params[:mail_merge] and params[:mail_merge][:annual_financial_box].to_i == 1
    #     num_years = params[:mail_merge][:annual_financial_years].to_i
    #     this_year = DateTime.now.year
    #     year = this_year - num_years + 1
    #     num_years.times do
    #       labels << year.to_s + " contributions"
    #       year += 1          
    #       row_size += 1
    #     end
    #   end
    #   if params[:mail_merge] and params[:mail_merge][:volunteer_box].to_i == 1
    #     labels << "Vol. hours in the last "+params[:mail_merge][:volunteer_num].to_s+ " " + params[:mail_merge][:volunteer_timeframe]
    #     row_size += 1
    #   end
    #   logger.debug labels
    #   CSV.generate_row(labels, row_size, file_data)
    #   committees = @campaign.committees
    #   @entities.each do |entity|
    #     fields = [entity.household_id.to_s, entity.title, entity.first_name, entity.middle_name, entity.last_name, entity.name_suffix, entity.mailing_name]
    #     if entity.mailing_address
    #       fields = fields + [entity.mailing_address.line_1.to_s, entity.mailing_address.line_2.to_s, entity.mailing_address.city.to_s, entity.mailing_address.state.to_s, entity.mailing_address.zip.to_s, entity.mailing_address.zip.to_s+"-"+entity.mailing_address.zip_4.to_s]
    #     else
    #       fields = fields + [nil, nil, nil, nil, nil, nil]
    #     end
    #     fields << entity.primary_phone.to_s << number_to_phone(entity.primary_phone_number.to_s)
    #     #email
    #     if entity.primary_email
    #       fields << entity.primary_email.label << entity.primary_email.address
    #     else
    #       fields << nil << nil
    #     end
    #     if params[:mail_merge] and params[:mail_merge][:phone].to_i == 1
    #       if entity.phones.class == Hash and entity.phones.length >= 2
    #         other_phones = entity.phones.dup
    #         other_phones.delete(entity.primary_phone)
    #         other_phones.to_a.first
    #         fields << other_phones.to_a.first[0] << number_to_phone(other_phones.to_a.first[1])
    #       else
    #         fields << nil << nil
    #       end
    #     end
    #     if params[:mail_merge] and params[:mail_merge][:total_financial_box].to_i == 1
    #       value = nil
    #       unless session[:user].treasurer_info.nil? or session[:user].treasurer_info[total_committee.id].nil?  or total_committee.treasurer_api_url.to_s == ""
    #         treasurer_entity = TreasurerEntity.find(:first,:conditions=>["entity_id=:entity AND committee_id=:committee",{:entity=>entity.id,:committee=>total_committee.id}])
    #         unless treasurer_entity.nil?
    #           treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,total_committee.treasurer_api_url)
    #           value = treasurer.get_transaction_values_by_date(session[:user].treasurer_info[total_committee.id][0], session[:user].treasurer_info[total_committee.id][1], total_committee.treasurer_id, treasurer_entity.treasurer_id, start_date, end_date, false, true)
    #         end
    #       end
    #       fields << value
    #     end
    #     if params[:mail_merge] and params[:mail_merge][:latest_financial_box].to_i == 1
    #       value = nil
    #       unless session[:user].treasurer_info.nil? or session[:user].treasurer_info[latest_committee.id].nil?  or latest_committee.treasurer_api_url.to_s == ""
    #         treasurer_entity = TreasurerEntity.find(:first,:conditions=>["entity_id=:entity AND committee_id=:committee",{:entity=>entity.id,:committee=>latest_committee.id}])
    #         unless treasurer_entity.nil?
    #           treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,latest_committee.treasurer_api_url)
    #           value = treasurer.get_transaction_values_by_date(session[:user].treasurer_info[latest_committee.id][0], session[:user].treasurer_info[latest_committee.id][1], latest_committee.treasurer_id, treasurer_entity.treasurer_id, DateTime.now, DateTime.now, true, true)
    #         end
    #       end
    #       fields << value
    #     end    
    #     if params[:mail_merge] and params[:mail_merge][:annual_financial_box].to_i == 1
    #       year = this_year - num_years + 1
    #       num_years.times do
    #         start_date = Date.civil(year).to_time
    #         end_date = Date.civil(year+1).to_time - 1.second
    #         year_value = 0
    #         value = 0
    #         committees.each do |committee|
    #           treasurer_entity = TreasurerEntity.find(:first,:conditions=>["entity_id=:entity AND committee_id=:committee",{:entity=>entity.id,:committee=>committee.id}])
    #           unless session[:user].treasurer_info.nil? or session[:user].treasurer_info[committee.id].nil?  or committee.treasurer_api_url.to_s == "" or treasurer_entity.nil?
    #             treasurer = ActionWebService::Client::XmlRpc.new(FinancialApi,committee.treasurer_api_url)
    #             value = treasurer.get_transaction_values_by_date(session[:user].treasurer_info[committee.id][0], session[:user].treasurer_info[committee.id][1], committee.treasurer_id, treasurer_entity.treasurer_id, start_date, end_date, false, true)
    #             year_value += value
    #           end
    #         end
    #         contributions = entity.contributions.find(:all, :conditions=>["date BETWEEN :start AND :end",{:start=>start_date, :end=>end_date}])
    #         contributions.each do |contrib|
    #           year_value += contrib.amount
    #         end
    #         fields << year_value
    #         year += 1          
    #       end
    #     end
    #     if params[:mail_merge] and params[:mail_merge][:volunteer_box].to_i == 1
    #       num = params[:mail_merge][:volunteer_num].to_i
    #       vol_end_date = DateTime.now
    #       if params[:mail_merge][:volunteer_timeframe] == "days"
    #         vol_start_date = num.days.ago
    #       elsif params[:mail_merge][:volunteer_timeframe] == "weeks"
    #         vol_start_date = num.weeks.ago
    #       elsif params[:mail_merge][:volunteer_timeframe] == "months"
    #         vol_start_date = num.months.ago
    #       elsif params[:mail_merge][:volunteer_timeframe] == "years"
    #         vol_start_date = num.years.ago
    #       end
    #       fields << entity.total_volunteer_minutes(vol_start_date,vol_end_date).to_f/60.to_f
    #     end
    #     CSV.generate_row(fields, row_size, file_data)
    #   end
    #   #logger.debug file_data
    #   filename = "MyPeople_mail_merge_file.csv"
    #   unless @text.nil?     
    #     missed_contact_events = []
    #     @entities.each do |entity|
    #       # begin
    #         if already_recorded.empty? or !already_recorded.include?(entity)
    #           contact_event = ContactEvent.new(:entity_id=>entity.id, :contact_text_id=>@text.id, :when_contact=>Time.now, :initiated_by=>"Campaign", :interaction=>false, :form=>"Letter", :campaign_id=>@text.campaign_id)
    #           contact_event.save!
    #         end
    #       # rescue
    #       #   missed_contact_events << entity
    #       # end
    #     end
    #   end
    #   send_data(file_data,:filename=>filename)
    
      # if missed_contact_events and missed_contact_events.length > 0
      #   names = []
      #   missed_contact_events.each do |ent|
      #     names << ent.name
      #   end
      #   flash[:warning] = "Failed to record the mail merge export for "+ names.join (", ")
      # end      
    # end
  end
  
  def mark_as_sent
    @text.update_attribute("complete", true)
    redirect_to :action=>"list", :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  end
  
  protected
  
  def load_text_and_check_campaign
    @text = ContactText.find(params[:id])
    # @campaign = @text.campaign
    if current_user.active_campaigns.include?(@campaign.id) and @campaign.id == @text.campaign_id
      unless params[:entity].nil?
        params[:contact_text][:updated_by]=session[:user].id
      end
    else
      @text = nil
      @campaign = nil
      render :partial=>"user/not_available"
      return
    end
  end
  
  def check_campaign
    # unless params[:campaign_id]
    #   params[:campaign_id] = session[:user].active_campaigns.first
    # end
    # @campaign = Campaign.find(params[:campaign_id])
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
  

end
