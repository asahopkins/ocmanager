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

# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
require 'pdf/writer'

class AddTagsWorker < BackgrounDRb::Rails
  
  attr_reader :progress
  @job_ctrl = true
  

  def do_work(args)
    #args: user_id, tag_string, campaign_id
    @progress = 0
    user = User.find(args[:user_id])
    tag = args[:tag_string]
    @logger.debug "adding this tag: "+tag
    campaign_id = args[:campaign_id]
    entities = user.entities
    entities.each do |entity|
      new_tag = Tag.find_by_name_and_campaign_id(tag, campaign_id)
      existing_tags = []
      entity.tags.each do |exist_tag|
        existing_tags << exist_tag.id
      end
      if new_tag.nil? or !existing_tags.include?(new_tag.id)
        tags = entity.tag_list+ ", #{tag}"
        @logger.debug tags
        entity.tag_with(tags, campaign_id)
      end
    end
 
    @progress = 101
    terminate
    ActiveRecord::Base.connection.disconnect!
    # kill()
  end
  
end