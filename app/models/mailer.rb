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

class Mailer < ActionMailer::Base
  include DRbUndumped

  def message(message, stylesheet, address, casual_name = "CASUALNAME", sent_at = Time.now)
    logger.debug "in mailer"
    recipients      address
    subject         message.subject
    from            message.sender
    # content_type    "multipart/alternative"

    campaign_name = message.campaign.name

    @body["message"] = message
    @body["address"] = address
    @body["campaign_name"] = campaign_name
    @body["casual_name"] = casual_name
    @body["stylesheet"] = stylesheet

    # part :content_type => "text/html", :body => render_message("message", :message=>message, :stylesheet=>stylesheet, :address=>address, :campaign_name=>campaign_name, :casual_name=>casual_name)
    
    # part "text/plain" do |p|
      # p.body = render_message("message_plain", :message=>message, :address=>address, :campaign_name=>campaign_name, :casual_name=>casual_name)
      # p.transfer_encoding = "base64"
    # end
    
     # @subject    = message.subject
    # logger.debug "in mailer 2"
#    @body["message"] = message
#    logger.debug "in mailer 3"
#    @body["stylesheet"] = stylesheet
    #logger.debug "in mailer 4"
    # @recipients = address
    # logger.debug "in mailer 5"
    # @from       = message.sender
    # logger.debug "in mailer 6"
    # @sent_on    = sent_at
    # logger.debug "in mailer 7"
    #@bcc        = addresses
    # @content_type = "multipart/alternative"
    # logger.debug "in mailer 8"
    # part :content_type=>"text/plain", :body=>render_message("message_plain", {:message=>message, :address=>address, :campaign_name=>campaign_name, :casual_name=>casual_name})
    #  # logger.debug "in mailer 9"
    #  part :content_type=>"text/html", :body=>render_message("message", {:text=>message.formatted_text, :stylesheet=>stylesheet, :address=>address, :campaign_name=>campaign_name, :casual_name=>casual_name})
     # logger.debug "in mailer 10"      
  end

  def plaintext_message(message, address, casual_name = "CASUALNAME", sent_at = Time.now)
    campaign_name = message.campaign.name
    @subject    = message.subject
    @recipients = address
    @from       = message.sender
    @sent_on    = sent_at
    @body["message"] = message
    @body["address"] = address
    @body["campaign_name"] = campaign_name
    @body["casual_name"] = casual_name
   end

  #  def perform_delivery_sendmail(mail)
  #    sendmail_args = sendmail_settings[:arguments]
  #    sendmail_args += " -f \"#{mail['return-path']}\"" if mail['return-path']
  #    IO.popen("#{sendmail_settings[:location]} #{sendmail_args}","w+") do |sm|
  #      sm.print(mail.encoded.gsub(/\r/, ''))
  #      sm.flush
  #    end
  #  end
  # 
  # def perform_delivery_sendmail(mail)
  #   mail.ready_to_send
  #   IO.popen("/usr/sbin/sendmail -i -t -f #{BOUNCE_ADDRESS}","w+") do |sm| 
  #     sm.print(mail.encoded.gsub(/\r/, ''))
  #     sm.flush
  #   end
  # end
     
end
