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

class Contribution < ActiveRecord::Base
  belongs_to :entity
  belongs_to :campaign_event
  belongs_to :recipient_committee, :class_name=>"OutsideCommittee", :foreign_key=>"recipient_committee_id"
  
  before_save :set_recipient
  
  def validate
    errors.add("amount","must be a positive number.") unless amount > 0
  end
  
  def set_recipient
    if self.recipient_committee_id and self.recipient_committee_id.to_i > 0
      rc = self.recipient_committee
      self.recipient = rc.name.to_s
    end
  end
  
  def recipient_name
    if recipient
      return recipient
    end
    if recipient_committee_id and recipient_committee_id > 0
      return recipient_committee.name
    else
      return recipient
    end
  end
  
end
