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

module EntitiesHelper
  
  def display_name(entity)
    if entity.class==Person
      name = ""
      unless entity.title.nil? or entity.title.to_s==""
        name += entity.title+" "
      end
      unless entity.first_name.nil? or entity.first_name.to_s==""
        name += " "+entity.first_name+" "
      end
      unless entity.nickname.nil? or entity.nickname.to_s=="" or entity.nickname==entity.first_name
        name += " \""+entity.nickname+"\""
      end
      unless entity.middle_name.nil? or entity.middle_name.to_s==""
        if entity.middle_name.length==1
          name += " "+entity.middle_name+". "
        else
          name += " "+entity.middle_name+" "
        end
      end
      unless entity.last_name.nil? or entity.last_name.to_s==""
        name += " "+entity.last_name+" "
      end
      unless entity.name_suffix.nil? or entity.name_suffix.to_s==""
        name += " "+entity.name_suffix+" "
      end      
      # remove extra spaces
      name = name.gsub(/\s+/,' ')
      if name.strip == ""
        name = entity.name
      end
    else
      name = entity.name
    end
    #logger.debug name
    return h(name)
  end
  
  def display_tags(entity)
    output=""
    entity.tags.each {|tag|
      output += link_to tag, :controller=>"entities", :action=>"list", :params=>{:id=>tag.name}
      output += ", "
      }
    output = output[0...-2]
    return output
  end

  def edit_tags(entity)
    output=""
    entity.tags.each { |tag|
      output += "\""+tag.name+"\""
      output += ", "
      }
    output = output[0...-2]
    return output
  end

end
