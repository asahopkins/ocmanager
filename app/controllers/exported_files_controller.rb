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

class ExportedFilesController < ApplicationController
  layout 'manager'

  before_filter :get_campaign
  before_filter :check_campaign,:only=>[:index,:list,:get]

  def index
    list
    render :action => 'list'
  end

  def list
    @page_title = "Exported Files"
    @files = ExportedFile.paginate :per_page => 25, :conditions=>["campaign_id=:campaign",{:campaign=>@campaign.id}], :order=>"created_at DESC", :page=>params[:page]
    for file in @files
      key_name = "export_key_"+file.filename
      @progress = Hash.new
      if MiddleMan[key_name.to_sym]
        @progress[file.id] = MiddleMan[key_name.to_sym].progress
        if @progress[file.id] == 101
    		  MiddleMan.delete_worker(key_name.to_sym)
    		  @progress[file.id] = nil
  		  end
    	end
    end
  end

  def get
    file_object = ExportedFile.find(params[:id])
    file_path = @@file_path_prefix + @campaign.id.to_s + "/" + file_object.filename
    logger.debug "path = "+file_path
    # check for existence of file
    if File.file?(file_path) and File.readable?(file_path)
      send_file file_path
      file_object.update_attribute(:downloaded, true)
      return
    else
      render :text=>"Didn't find the file you requested."
      # file didn't exist or there was some other error; render error page
    end
  end
  
  def destroy
    file_object = ExportedFile.find(params[:id])
    name = file_object.filename
    file_path = @@file_path_prefix + @campaign.id.to_s + "/" + name
    file_object.destroy
    begin
      File.delete(file_path)
      flash[:notice] = "File: '"+name+"' has been deleted."
    rescue
      flash[:warning] = "The file '"+name+"' appears to already have been deleted."
    end
    redirect_to :action=>"list"
  end
  
  protected
  
  def check_campaign
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end

  

end
