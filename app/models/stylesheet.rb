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

class Stylesheet < ActiveRecord::Base
  include DRbUndumped
  has_many :emails
  belongs_to :campaign
  
  def color_web(tag, color)
    if color=="red"
      start = 0
    elsif color=="green"
      start = 2
    elsif color=="blue"
      start = 4
    end
    case tag
    when "p"
      return self.p_color[start,2].hex
    when "h1"
      return self.h1_color[start,2].hex
    when "h2"
      return self.h2_color[start,2].hex
    when "h3"
      return self.h3_color[start,2].hex
    when "h4"
      return self.h4_color[start,2].hex
    when "h5"
      return self.h5_color[start,2].hex
    when "a"
      return self.a_color[start,2].hex
    when "hr"
      return self.hr_color[start,2].hex
    when "side_bg"
      return self.side_bg[start,2].hex
    when "title_bg"
      return self.title_bg[start,2].hex
    when "body_bg"
      return self.body_bg[start,2].hex
    end      
  end
      
  
end
