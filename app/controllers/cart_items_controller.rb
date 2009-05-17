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

class CartItemsController < ApplicationController
  layout 'manager'

  before_filter :get_campaign

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :destroy_all ],
         :redirect_to => { :action => :list }

  def list
    @page_title = "MyPeople"
    # @mypeople = CartItem.find(:all, :include=>:entity, :conditions=>['user_id=:user',{:user=>current_user.id}], :order=>"entities.last_name ASC, entities.name ASC, entities.first_name ASC")
    # @cart_items = paginate_collection @mypeople, :per_page => 25, :page=>params[:page]
    @cart_items = CartItem.paginate :include=>:entity, :conditions=>['user_id=:user',{:user=>current_user.id}], :order=>"entities.last_name ASC, entities.name ASC, entities.first_name ASC", :per_page => 25, :page=>params[:page]
    @groups = @campaign.groups
    @campaign_events = @campaign.campaign_events
  end

  def create
    CartItem.add(params[:entity_id].to_i, current_user.id)
    @entity = Entity.find(params[:entity_id])
    @in_mypeople = [@entity.id]
  #rescue
  end

  def destroy
    if params[:id]
      @cart_item_id = params[:id]
      ci = CartItem.find(@cart_item_id)
    elsif params[:entity_id]
      ci = current_user.cart_items.find_by_entity_id(params[:entity_id])
      # @cart_item_id = ci.id
      @entity = Entity.find(params[:entity_id])
      @in_mypeople = []
    end
    if ci
      ci.destroy
    end
  end

  def destroy_all
    current_user.empty_cart
  end
  
  def update_cart
    if params[:tag_name]
      tag = Tag.find_by_name_and_campaign_id(params[:tag_name],@campaign.id)
      unless tag.nil?
        entity_ids = []
        tag.taggings.each do |tagging|
          entity_ids << tagging.taggable_id.to_i
        end
        if params[:cart] == "Add"
          CartItem.add(entity_ids, current_user.id) #TODO: background?
        elsif params[:cart] == "Intersect"
          CartItem.intersect_with(entity_ids, current_user.id) #TODO: background?
        elsif params[:cart] == "Remove"
          CartItem.remove(entity_ids, current_user.id) #TODO: background?
        end
      end
    elsif params[:cart] == "Add_Attendees"
      event = CampaignEvent.find(params[:campaign_event_id])
      ents = event.attended
      CartItem.add(ents, current_user.id)
    elsif params[:cart] == "Add_Invitees"
      event = CampaignEvent.find(params[:campaign_event_id])
      ents = event.invited
      CartItem.add(ents, current_user.id)
    elsif params[:cart] == "Add_by_rsvp_response"
      event = CampaignEvent.find(params[:campaign_event_id])
      if params[:response] == "None"
        ents = event.all_entities
        rsvps = event.rsvps.find(:all,:conditions=>["response IS NOT NULL"])
        rsvps.each{|rsvp| ents.delete(rsvp.entity) }
      else
        rsvps = event.rsvps.find(:all,:conditions=>["response = :resp",{:resp=>params[:response]}])
        ents = []
        rsvps.each {|rsvp| ents << rsvp.entity}
      end
      CartItem.add(ents, current_user.id)
    elsif params[:cart] == "Add_by_event_contribution"
      event = CampaignEvent.find(params[:campaign_event_id])
      threshold = to_numbers(params[:contribution][:threshold]).to_i
      ents = event.contributors(threshold)
      CartItem.add(ents, current_user.id)
    elsif params[:cart] == "Add_by_event_pledge"
      event = CampaignEvent.find(params[:campaign_event_id])
      threshold = to_numbers(params[:pledge][:threshold]).to_i
      ents = event.pledged_contributors(threshold)
      CartItem.add(ents, current_user.id)
    elsif params[:cart] == "Empty"
      current_user.empty_cart
    else 
      # logger.debug "from search"
      search = Search.find(session[:search_id])
      includes = search.includes
      cond = search.cond
      # group_clause = session[:group_clause]
      joins = search.joins
      # aggregate = session[:aggregate]

      entities = Entity.find(:all, :conditions=>cond, :include=>includes, :joins=>joins)
      entity_ids = []
      entities.each do |entity|
        entity_ids << entity.id
      end
      entities = nil
      if params[:cart] == "Add"
        CartItem.add(entity_ids, current_user.id) #TODO: background?
      elsif params[:cart] == "Intersect"
        CartItem.intersect_with(entity_ids, current_user.id) #TODO: background?
      elsif params[:cart] == "Remove"
        CartItem.remove(entity_ids, current_user.id) #TODO: background?
      end
      GC.start
    end
    #@reload_cart = params[:reload_cart]
    render :update do |page|
      page.replace_html 'cart_items_number', current_user.cart_items.count
      page.visual_effect :highlight, 'cart_list'
    end
  end
    
  def add_tag
    @tag = params[:entity][:tag].to_s.strip
    unless @tag == ""
      @entities = current_user.entities
      @entities.each do |entity|
        new_tag = Tag.find_by_name_and_campaign_id(@tag, @campaign.id)
        if new_tag.nil? or !entity.tags.include?(new_tag)
          tags = entity.tag_list+ ", #{@tag}"
          logger.debug tags
          entity.tag_with(tags, @campaign.id)
        end
      end
      expire_fragment(:controller => "campaigns", :action => "tags", :action_suffix => @campaign.id)
      render :update do |page|
        page.replace_html 'flash_notice', "MyPeople tagged with: #{@tag}"
      end
      return
    else
      render :update do |page|
        page.replace_html 'flash_notice', "Can't tag with an empty tag name."
      end
      return
    end
  end
  
  # FIXME: I don't think this is actually used
  def cart_labels
    # households?
    @rails_pdf_name = "MyPeople_address_labels.pdf"
    @entities = current_user.entities
    @entities.each do |entity|
      if entity.primary_address.nil? or entity.primary_address.line_1.nil? or entity.primary_address.line_1.to_s == ""
        @entities.delete(entity)
      end
    end
    render :layout=>false
  end

  def cart_phone_list
    if params[:script_id]
      @script = ContactText.find(params[:script_id])
    end
    @entities = current_user.entities
    @entities.each do |entity|
      if entity.primary_phone.nil? or entity.primary_phone == ""
        @entities.delete(entity)
      end
    end
    render :layout=>false
  end
  
  def call_sheets
    
    entity_id_array = []
    current_user.entities.each do |entity|
      entity_id_array << entity.id
    end
    if params[:labels] and params[:labels][:filename] and (params[:labels][:filename] != "Please enter a file name")
      filename = params[:labels][:filename][0..28]
      if filename[-4..-1] != ".pdf"
        filename = filename+".pdf"
      end
    else
      filename = "call_sheets_"+Time.now.strftime("%m_%d_%Y_%H_%M")+".pdf"
    end
    filename.gsub!(/[\s\/:]+/,"_")
    
    key_name = "export_key_"+filename
    MiddleMan.new_worker(:class=>:export_call_sheets_worker, :args=>{:entity_id_array=>entity_id_array, :filename=>filename, :file_path_prefix=>@@file_path_prefix, :campaign_id=>@campaign.id}, :job_key=>key_name.to_sym)
    flash[:notice] = "Call sheets are being prepared now."
    
    redirect_to :action=>"list", :protocol=>@@protocol
  end
  
end
