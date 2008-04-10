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

class EmailAddress < ActiveRecord::Base
  belongs_to :entity

  validates_uniqueness_of :label, :scope=>:entity_id #TODO: catch this error
  def valid
    !invalid
  end
    
  def valid=(bool)
    unless bool == false or bool == "0" or bool == 'false'
      self.invalid = false
    else
      self.invalid = true
    end
  end
  
end
