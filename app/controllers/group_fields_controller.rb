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

class GroupFieldsController < ApplicationController
  layout 'manager'
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @group_fields = GroupField.paginate :per_page => 10, :page=>params[:page]
  end

  def show
    @group_field = GroupField.find(params[:id])
  end

  def new
    @group_field = GroupField.new
  end

  def create
    @group_field = GroupField.new(params[:group_field])
    if @group_field.save
      flash[:notice] = 'GroupField was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @group_field = GroupField.find(params[:id])
  end

  def update
    @group_field = GroupField.find(params[:id])
    if @group_field.update_attributes(params[:group_field])
      flash[:notice] = 'GroupField was successfully updated.'
      redirect_to :action => 'show', :id => @group_field
    else
      render :action => 'edit'
    end
  end

  def destroy
    GroupField.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
