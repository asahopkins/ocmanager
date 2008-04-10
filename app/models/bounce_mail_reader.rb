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

require 'net/imap'

class BounceMailReader < ActionMailer::Base

  def receive(email)
    # logger.debug email.subject 
    # logger.debug email.to[0]
    
    return unless email.content_type == "multipart/report"
    bounce = BouncedDelivery.from_email(email)
    # logger.info bounce.status
    if bounce.original_message_id
      msg = ContactEvent.find_by_message_id(bounce.original_message_id)
      unless (msg.nil? or msg.status == bounce.status)
        msg.update_attribute(:status, bounce.status)
        if bounce.status == 'Failure'
          entity = msg.entity
          entity.mark_primary_email_as_invalid
        end
      end
    end
  end

  def self.check_mail(delete_flag = true)
    imap = Net::IMAP.new(SERVER_NAME)
    imap.authenticate('LOGIN', BOUNCE_ADDRESS, BOUNCE_PASSWORD) 
    imap.select('INBOX')
    imap.search(['ALL']).each do |message_id|
      logger.debug "message_id="+message_id.to_s
      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
      BounceMailReader.receive(msg)
      #Mark message as deleted and it will be removed from storage when user session is closed
      imap.store(message_id, "+FLAGS", [:Deleted]) if delete_flag
    end
    imap.expunge if delete_flag
  end


end

class BouncedDelivery
  attr_accessor :status_info, :original_message_id
  def self.from_email(email)
    returning(bounce = self.new) do
      status_part = email.parts.detect do |part|
        part.content_type == "message/delivery-status"
      end
      statuses = status_part.body.split(/\n/)
      bounce.status_info = statuses.inject({}) do |hash, line|
        key, value = line.split(/:/)
        hash[key] = value.strip rescue nil
        hash
      end
      original_message_part = email.parts.detect do |part|
        part.content_type == "message/rfc822"
      end
      if original_message_part
        parsed_msg = TMail::Mail.parse(original_message_part.body)
        bounce.original_message_id = parsed_msg.message_id
      end
    end
  end
  def status
    case status_info['Status' ]
    when /^5/
      'Failure'
    when /^4/
      'Temporary Failure'
    when /^2/
      'Success'
    end
  end
end