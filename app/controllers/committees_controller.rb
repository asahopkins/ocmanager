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

class CommitteesController < ApplicationController
  
  layout 'manager'
  before_filter :get_campaign
  
  before_filter :load_committee_and_check_campaign, :except=>[:list, :new, :create]
  before_filter :check_campaign, :only=>[:list, :new, :create]
  
  
#  def index
#    list
#    render :action => 'list'
#  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @committee_pages, @committees = paginate :committees, :per_page => 10, :conditions=>['campaign_id = :campaign', {:campaign=>@campaign.id}], :order=>"name"
  end

  def show
#    @committee = Committee.find(params[:id])
  end

  def new
    @committee = Committee.new
  end

  def create
    @committee = Committee.new(params[:committee])
    @committee.campaign = @campaign
    if @committee.save
      flash[:notice] = 'Committee was successfully created.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      render :action => 'new', :params=>{:campaign_id=>@campaign.id}
    end
  end

  def edit
#    @committee = Committee.find(params[:id])
  end

  def update
#    @committee = Committee.find(params[:id])
    if @committee.update_attributes(params[:committee])
      flash[:notice] = 'Committee was successfully updated.'
      redirect_to :action => 'show', :id => @committee, :protocol=>@@protocol
    else
      render :action => 'edit'
    end
  end

  def destroy
    Committee.find(params[:id]).destroy
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  end
  
  protected
  
  def load_committee_and_check_campaign
    @committee = Committee.find(params[:id])
    # @campaign = @committee.campaign
    if current_user.active_campaigns.include?(@campaign.id) and @campaign.id == @committee.campaign_id
      unless params[:entity].nil?
        params[:entity][:updated_by]=current_user.id
      end
    else
      @committee = nil
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
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
