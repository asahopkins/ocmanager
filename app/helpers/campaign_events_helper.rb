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

module CampaignEventsHelper
  
  def display_event_address(event)
    addr = ""
    unless event.nil?
      unless event.location_name.nil? or event.location_name==""
        addr += "#{h event.location_name}<br />"
      end
      unless event.addr_line1.nil? or event.addr_line1==""
        addr += "#{h event.addr_line1}<br />"
      end
      unless event.addr_line2.nil? or event.addr_line2==""
  		  addr+="#{h event.addr_line2}<br />"
  	  end
  		addr+="#{h event.addr_city}, #{h event.addr_state} #{h event.addr_zip}"
	  end
		return addr
  end
  
end
