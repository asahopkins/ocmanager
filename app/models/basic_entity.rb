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

class BasicEntity < ActionWebService::Struct
  member :id,         :int
  member :type,       :string
  member :name,       :string
  member :first_name, :string
  member :last_name,  :string
  member :addr_line1, :string
  member :addr_line2, :string
  member :addr_city,  :string
  member :addr_state, :string
  member :addr_ZIP,   :string
  member :addr_ZIP_4, :string
  member :phone,      :string
  member :fax,        :string
  member :email,      :string
  member :occupation, :string
  member :employer,   :string
  member :federal_ID, :string
  member :state_ID,   :string
  member :party,      :bool
  
end