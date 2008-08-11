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

class EmailsController < ApplicationController

  before_filter :get_campaign
  before_filter :strip_white_space
  
  def update
    email = EmailAddress.find(params[:id])
    @entity = email.entity
    email.update_attributes(params[:email])
    email.valid = params[:email][:valid]
    email.save
    if params[:entity] and params[:entity][:primary_email].to_s == "1"
      @entity.primary_email = email
      @entity.save!
    end
    render :partial=>"entities/emails", :locals=>{:can_edit=>session[:user].can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end

  def create
    @entity = Entity.find(params[:entity_id])
    params[:email][:entity_id] = @entity.id
    email = EmailAddress.new(params[:email])
    email.save!
    if params[:entity] and params[:entity][:primary_email].to_s == "1"
      @entity.primary_email = email
      @entity.save
    end
    render :partial=>"entities/emails", :locals=>{:can_edit=>session[:user].can_edit_entities?(@campaign)}#, :protocol=>@@protocol    
  end

  def destroy
    email = EmailAddress.find(params[:id])
    @entity = email.entity
    id = email.id
    email.destroy
    if @entity.primary_email_id == id
      if @entity.email_addresses.length == 0
        @entity.primary_email_id = nil
      else
        @entity.primary_email_id = @entity.email_addresses.first.id
      end
      @entity.save!
    end
    render :partial=>"entities/emails", :locals=>{:can_edit=>session[:user].can_edit_entities?(@campaign)}#, :protocol=>@@protocol
  end
    
end
