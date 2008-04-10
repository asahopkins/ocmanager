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

class VolunteerEvent < ActiveRecord::Base
  belongs_to :entity
  belongs_to :volunteer_task
  
  def generate_duration
    if end_time
      start_time = self.start_time
      end_time = self.end_time
      distance_in_minutes = ((end_time - start_time)/60).round
      if distance_in_minutes >= 0
        return distance_in_minutes
      else
        return 0
      end
    else
      return 0
    end
  end
  
  def current_duration
    if end_time
      return duration
    else
      return ((Time.now - start_time)/60).round
    end
  end
  
end
