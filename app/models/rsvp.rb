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

class Rsvp < ActiveRecord::Base
  include DRbUndumped
  belongs_to :entity
  belongs_to :campaign_event
  # TODO: write a validation so that there cannot be two rsvps for the same event+entity
  before_save :check_response
  
  def check_response
    unless ["Yes", "No", "Maybe", nil].include? self.response
      self.response = nil
    end
  end
  
  def Rsvp.sort_by_response(a,b)
    order = {"Yes"=>0, "Maybe"=>1, "No"=>2, nil=>3}
    if a and b
      return order[a.response]<=>order[b.response]
    elsif a
      return -1
    elsif b
      return 1
    else
      return 0
    end
  end
  
  def Rsvp.sort_by_attendance(a,b)
    order = {true=>0, false=>1}
    if a and b
      order[a.attended?]<=>order[b.attended?]
    elsif a
      return -1
    elsif b
      return 1
    else
      return 0
    end
  end

  def Rsvp.sort_by_invitation(a,b)
    order = {true=>0, false=>1}
    if a and b
      order[a.invited?]<=>order[b.invited?]
    elsif a
      return -1
    elsif b
      return 1
    else
      return 0
    end
      
  end

end
