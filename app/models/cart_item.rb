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

class CartItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :entity

  validates_presence_of :entity_id
  validates_presence_of :user_id
  
  def CartItem.add(entities, user_id)
    if entities.is_a?(Array)
      if entities.first.is_a?(Entity)
        for entity in entities do
          cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entity.id, :user_id=>user_id}])
          if cart_item.nil?
            cart_item = CartItem.new(:entity_id=>entity.id, :user_id=>user_id)
            cart_item.save!
          end
        end
      elsif entities.first.is_a?(Integer)
        for entity in entities do
          cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entity, :user_id=>user_id}])
          if cart_item.nil?
            cart_item = CartItem.new(:entity_id=>entity, :user_id=>user_id)
            cart_item.save!
          end
        end
      end
    elsif entities.is_a?(Integer)
      cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entities, :user_id=>user_id}])
      if cart_item.nil?
        cart_item = CartItem.new(:entity_id=>entities, :user_id=>user_id)
        cart_item.save!
      end
    elsif entities.is_a?(Entity)
      cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entities.id, :user_id=>user_id}])
      if cart_item.nil?
        cart_item = CartItem.new(:entity_id=>entities.id, :user_id=>user_id)
        cart_item.save!
      end
    end
  end
  
  def CartItem.intersect_with(entities, user_id)
    user = User.find(user_id)
    if entities.first.is_a?(Entity)
      entity_id_array = []
      for entity in entities do
        entity_id_array << entity.id
      end
      overlap_items = CartItem.find(:all, :conditions=>['entity_id IN (:entities) AND user_id=:user_id',{:entities=>entity_id_array, :user_id=>user_id}])
      nonoverlap_items = user.cart_items - overlap_items
      nonoverlap_items.each do |item|
        item.destroy
      end      
    elsif entities.first.is_a?(Integer)  
      overlap_items = CartItem.find(:all, :conditions=>['entity_id IN (:entities) AND user_id=:user_id',{:entities=>entities, :user_id=>user_id}])
      nonoverlap_items = user.cart_items - overlap_items
      nonoverlap_items.each do |item|
        item.destroy
      end
    end
  end
  
  def CartItem.remove(entities, user_id)
    if entities.is_a?(Array)
      if entities.first.is_a?(Entity)
        for entity in entities do
          cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entity.id, :user_id=>user_id}])
          unless cart_item.nil?
            cart_item.destroy
          end
        end
      elsif entities.first.is_a?(Integer)
        cart_items = CartItem.find(:all, :conditions=>['entity_id IN (:entity_ids) AND user_id=:user_id',{:entity_ids=>entities, :user_id=>user_id}])
        for cart_item in cart_items do
          unless cart_item.nil?
            cart_item.destroy
          end
        end
      end
    elsif entities.is_a?(Integer)
      cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entities, :user_id=>user_id}])
      unless cart_item.nil?
        cart_item.destroy
      end
    elsif entities.is_a?(Entity)
      cart_item = CartItem.find(:first, :conditions=>['entity_id=:entity_id AND user_id=:user_id',{:entity_id=>entities.id, :user_id=>user_id}])
      unless cart_item.nil?
        cart_item.destroy
      end
    end
  end
  
end
