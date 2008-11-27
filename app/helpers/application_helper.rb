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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # include Localization
  
  def plus_minus(plus, minus, open, klass="", label="", open_flag=false)
    output = "<span id=\""+plus+"\" class=\""+klass+"\""
    if open_flag
      output += "style=\"display:none;\""
    end
    output += "><a href=\"#\" onclick=\"Element.hide('"+plus+"'); Element.show('"+minus+"'); Effect.BlindDown('"+open+"',{duration: 0.15}); return false;\" style=\"text-decoration: none;\">"
    output += image_tag 'plus.gif'
    output += "&nbsp; "+label+"</a></span> <span id=\""+minus+"\"  class=\""+klass+"\" "
    unless open_flag
      output += "style=\"display:none;\""
    end
    output += "><a href=\"#\" onclick=\"Element.hide('"+minus+"'); Element.show('"+plus+"'); Effect.BlindUp('"+open+"',{duration: 0.15}); return false;\" style=\"text-decoration: none;\">"
    output += image_tag 'minus.gif'
  	output += "&nbsp; "+label+"</a></span>"
  end
  
  def link_to_email(email)
    unless email.nil?
      "<a href=\"mailto:"+h(email)+"\">"+h(email)+"</a>"
    else
      ""
    end
  end
  
  def display_yes_no(flag)
    if flag.nil? or flag==""
      return "&nbsp;"
    elsif flag.to_s=="true"
      return "Yes"
    else
      return "No"
    end
  end
  
  def display_duration(minutes)
    if minutes.nil?
      return "0:00"
    end
    hours = (minutes/60.floor)
    min = (minutes-hours*60).to_s
    if min.length==1
      min="0"+min
    end
    return hours.to_s+":"+min
  end
  
  def display_array(array)
    output = ""
    if array.nil?
      return output
    end
    array.each do |element|
      output += element+" | "
    end
    return output[0...-3]
  end

  def display_tags(campaign)
    output=""
    tags = campaign.tags.sort{|a,b| a.name <=> b.name}
    tags.each {|tag|
      unless tag.taggings.length==0
        output += link_to tag, :controller=>"entities", :action=>"list", :params=>{:id=>tag.name}
        output += ", "
      end
      }
    output = output[0...-2]
    return output
  end
  
  def display_address(address)
    addr = ""
    unless address.nil?
      unless address.line_1.nil? or address.line_1==""
        addr += "#{h address.line_1}<br />"
      end
      unless address.line_2.nil? or address.line_2==""
  		  addr+="#{h address.line_2}<br />"
  	  end
  		addr+="#{h address.city}, #{h address.state} #{h address.zip}"
  		unless address.zip_4.nil? or address.zip_4==""
  		  addr+="-#{h address.zip_4}"
  	  end
	  end
		return addr
  end
  
  def cut_to_length(string, length)
    length = length.to_i
    if string.length > length
      return string[0..length-4]+"..."
    else
      return string
    end
  end

  def to_where_statement(ary)
    return ary unless ary.is_a?(Array)

    statement, *values = ary
    if values.first.is_a?(Hash) and statement =~ /:\w+/
      manager_replace_named_bind_variables(statement, values.first)
    elsif statement.include?('?')
      manager_replace_bind_variables(statement, values)
    else
      statement % values.collect { |value| "'"+value.to_s+"'" }
    end
  end

  def manager_replace_bind_variables(statement, values) #:nodoc:
    bound = values.dup
    statement.gsub('?') { manager_quote_bound_value(bound.shift) }
  end

  def manager_replace_named_bind_variables(statement, bind_vars) #:nodoc:
    statement.gsub(/:(\w+)/) do
      match = $1.to_sym
      if bind_vars.include?(match)
        manager_quote_bound_value(bind_vars[match])
      else
        raise PreparedStatementInvalid, "missing value for :#{match} in #{statement}"
      end
    end
  end

  def manager_quote_bound_value(value) #:nodoc:
    if (value.respond_to?(:map) && !value.is_a?(String))
      value.map { |v| "'"+v.to_s+"'" }.join(',')
    else
      "'"+value.to_s+"'"
    end
  end
  
  def blockify_h1s(string)
    string.gsub!(/<h1>/,'<div class="h1_block"><h1>')
    string.gsub!(/<\/h1>/,'</h1></div>')
    return string
  end

end
