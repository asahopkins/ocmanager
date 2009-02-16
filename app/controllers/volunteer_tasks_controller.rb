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

class VolunteerTasksController < ApplicationController
  layout 'manager'
  
  before_filter :get_campaign
  before_filter :check_campaign
  
  def index
    list
    render :action => 'list', :params=>{:campaign_id=>@campaign.id}
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @volunteer_tasks = VolunteerTask.paginate :per_page => 50, :conditions=>['campaign_id=:campaign',{:campaign=>@campaign.id}], :order=>'display_order ASC', :page=>params[:page]
  end

#  def show
#    @volunteer_task = VolunteerTask.find(params[:id])
#  end

  def new
    @volunteer_task = VolunteerTask.new
  end

  def create
    @volunteer_task = VolunteerTask.new(params[:volunteer_task])
    @volunteer_task.campaign = @campaign
    if @volunteer_task.save
      flash[:notice] = 'Volunteer task was successfully created.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      render :action => 'new', :params=>{:campaign_id=>@campaign.id}
    end
  end

  def edit
    @volunteer_task = VolunteerTask.find(params[:id])
  end

  def update
    @volunteer_task = VolunteerTask.find(params[:id])
    if @volunteer_task.update_attributes(params[:volunteer_task])
      flash[:notice] = 'Volunteer task was successfully updated.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      render :action => 'edit', :params=>{:campaign_id=>@campaign.id}
    end
  end

  def destroy
    VolunteerTask.find(params[:id]).destroy
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}
  end
  
  def sort
    @campaign.volunteer_tasks.each do |task|
      task.display_order = params['task_list'].index(task.id.to_s) + 1
      task.save
    end
    render :nothing => true
  end
  
  protected
  
  def check_campaign
    # unless params[:campaign_id]
    #   params[:campaign_id] = current_user.active_campaigns.first
    # end
    # @campaign = Campaign.find(params[:campaign_id])
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
end
