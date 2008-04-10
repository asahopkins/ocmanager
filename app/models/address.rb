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

class Address < ActiveRecord::Base
  belongs_to :entity
  has_one :entity_primary, :class_name=>"Entity", :foreign_key=>"primary_address_id"
  has_one :entity_mailing, :class_name=>"Entity", :foreign_key=>"mailing_address_id"
  
  validates_uniqueness_of :label, :scope=>:entity_id

  def same_as(other_address)
    if line_1.to_s == other_address.line_1.to_s and line_2.to_s == other_address.line_2.to_s
      if city.to_s == other_address.city.to_s and state.to_s == other_address.state.to_s
        if zip.to_s == other_address.zip.to_s and zip_4.to_s == other_address.zip_4.to_s
          return true
        end
      end
    end
    return false
  end

end
