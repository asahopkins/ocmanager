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

class CustomFieldsController < ApplicationController
  layout  'manager'
  
  before_filter :get_campaign
  before_filter :check_campaign
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @custom_fields = CustomField.paginate :per_page => 50, :conditions=>['campaign_id=:campaign',{:campaign=>@campaign.id}], :order=>'display_order ASC', :page=>params[:page]
  end

#  def show
#    @custom_field = CustomField.find(params[:id])
#  end

  def new
    @custom_field = CustomField.new
    @num = 3
  end

  def create
    @custom_field = CustomField.new(params[:custom_field])
    #raise
    CustomField.transaction do
      @custom_field.campaign = @campaign
      @custom_field.select_options = []
      @custom_field.save!
      if @custom_field.field_type=="Select"
        # set array length = options_number?
        params[:select_field].delete("options_number")
        select_array = []
        key_array = params[:select_field].keys
        key_array.sort!
        key_array.each do |key|
          select_array[key.to_i] = params[:select_field][key][:options]
          #logger.debug key
          #logger.debug params[:select_field][key]
        end
        #logger.debug select_array
        @custom_field.select_options = select_array
        @custom_field.save!
      end
      flash[:notice] = 'Custom field was successfully created.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    end
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if @custom_field.field_type=="Select"
      @num = @custom_field.select_options.length
    else
      @num = nil
    end
  end

  def update
    @custom_field = CustomField.find(params[:id])
    CustomField.transaction do
      @custom_field.update_attributes(params[:custom_field])
      if @custom_field.field_type=="Select"
        if params[:select_field][:options_number].to_i < @custom_field.select_options.length
          @custom_field.select_options = @custom_field.select_options[0,params[:select_field][:options_number].to_i]
        end
        params[:select_field].delete("options_number")
        select_array = []
        key_array = params[:select_field].keys
        key_array.sort!
        key_array.each do |key|
          select_array[key.to_i] = params[:select_field][key][:options]
          #logger.debug key
          #logger.debug params[:select_field][key]
        end
        #logger.debug select_array
        @custom_field.select_options = select_array
        @custom_field.save!
      end
      flash[:notice] = 'Custom field was successfully updated.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    end
  end

  def select_fields
    unless params[:id].nil?
      @custom_field = CustomField.find(params[:id])
    end
    @num = params[:num].to_i
    render :partial=>'select_fields', :protocol=>@@protocol
  end

  def destroy
    CustomField.find(params[:id]).destroy
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  end
  
  def sort
    @campaign.custom_fields.each do |custom_field|
      custom_field.display_order = params['field_list'].index(custom_field.id.to_s) + 1
      custom_field.save
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
