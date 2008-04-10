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

class TreasurerEvent < ActionWebService::Struct
  member :id,                   :int
  member :limit_period_id,      :int
  member :when_occurred,        :datetime
  member :value,                :float
  member :created_at,           :datetime
  member :created_by,           :int
  member :updated_at,           :datetime
  member :updated_by,           :int
  member :URL,                  :string
  member :federal,              :boolean
  member :replaces,             :int
  member :replaced_by,          :int
  member :cancelled,            :int
  member :operating,            :boolean
  member :affiliate_transfer,   :boolean
  member :negated,              :boolean
end
