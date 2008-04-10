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

class Cart
  include Reloadable
  attr_reader :items, :number
  
  def initialize
    self.empty!
  end
  
  #check campaigns
  
  def add(entity_or_array)
    if entity_or_array.class==Array
      id_array = []
      entity_or_array.each {|entity|
        if entity.kind_of? Entity
          id_array << entity.id.to_s
        elsif entity.kind_of? Integer or entity.kind_of? String
          id_array << entity.to_s      
        end
      }
      @items += id_array
    elsif entity_or_array.kind_of? Entity
      @items << entity_or_array.id.to_s
    elsif entity_or_array.kind_of? String or entity_or_array.kind_of? Integer
      @items << entity_or_array.to_s
    end
    @items.uniq!
    @number = @items.length
  end
    
  def remove(entity_or_array)
    if entity_or_array.class==Array
      id_array = []
      entity_or_array.each {|entity|
        if entity.kind_of? Entity
          id_array << entity.id.to_s
        elsif entity.kind_of? Integer or entity.kind_of? String
          id_array << entity.to_s
        end
      }
      @items = @items - id_array
    elsif entity_or_array.kind_of? Entity
      @items.delete(entity_or_array.id.to_s)
    elsif entity_or_array.kind_of? String or entity_or_array.kind_of? Integer
      @items.delete(entity_or_array.to_s)
    end
    @items.uniq!
    @number = @items.length
  end

  def intersect_with(array)
    id_array = []
    array.each {|entity|
      if entity.kind_of? Entity
        id_array << entity.id.to_s
      elsif entity.kind_of? Integer or entity.kind_of? String
        id_array << entity.to_s
      end
    }
    @items = @items & id_array
    @items.uniq!
    @number = @items.length
  end
  
  def empty!
    @items = []
    @number = 0
  end
  
end