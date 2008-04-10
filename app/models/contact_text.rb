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

class ContactText < ActiveRecord::Base
  include DRbUndumped
  belongs_to :campaign
  has_many :contact_events
  has_many :recipients, :through=>:contact_events, :source => :entity
  #has_many :recipients, :through=>:contact_events, :class_name=>"Entity"
  
  belongs_to :campaign_event
  
  before_save :remove_angle_quotes
  
  def remove_angle_quotes
    self.text = self.text.gsub(/`/,"")  
  end
  
  def invitation?
    if campaign_event
      true
    else
      false
    end
  end
  
  alias invitation invitation?
  
end
