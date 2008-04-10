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

class Role < ActiveRecord::Base
  has_many :campaign_user_roles
  has_and_belongs_to_many :prohibitions
  has_and_belongs_to_many :prohibited_controllers
  has_and_belongs_to_many :prohibited_actions
  belongs_to :campaign
  
  def Role.load_roles
    Role.transaction do
      logger.debug "in load_roles"
      @superuser = Role.find(:first,:conditions=>["name = 'Super User'"])
      @manager = Role.find(:first,:conditions=>["name = 'Manager'"])
      @edit_all = Role.find(:first,:conditions=>["name = 'Edit All'"])
      @edit_groups = Role.find(:first,:conditions=>["name = 'Edit Groups'"])
      @dataentry = Role.find(:first,:conditions=>["name = 'Data Entry'"])
      @readonly = Role.find(:first,:conditions=>["name = 'Read Only'"])
      @sign_in = Role.find(:first,:conditions=>["name = 'Sign In'"])
      @inactive = Role.find(:first,:conditions=>["name = 'Inactive'"])
      if @superuser.nil?
        @superuser = Role.new(:name=>"Super User",:rank=>"1")
        @superuser.save!
      end
      logger.debug "done with superuser"
      if @manager.nil? 
        @manager = Role.new(:name=>"Manager",:rank=>"2")
        @manager.save!
      end
      logger.debug "done with manager"
      if @edit_all.nil? 
        @edit_all = Role.new(:name=>"Edit All",:rank=>"3")
        @edit_all.save!
      end
      logger.debug "done with edit all"
      if @edit_groups.nil? 
        @edit_groups = Role.new(:name=>"Edit Groups",:rank=>"4")
        @edit_groups.save!
      end
      logger.debug "done with edit groups"
      if @dataentry.nil? 
        @dataentry = Role.new(:name=>"Data Entry",:rank=>"5")
        @dataentry.save!
      end
      logger.debug "done with dataentry"
      if @readonly.nil? 
        @readonly = Role.new(:name=>"Read Only",:rank=>"6")
        @readonly.save!
      end
      logger.debug "done with readonly"
      if @sign_in.nil? 
        @sign_in = Role.new(:name=>"Sign In",:rank=>"7")
        @sign_in.save!
      end
      logger.debug "done with sign in"
      if @inactive.nil? 
        @inactive = Role.new(:name=>"Inactive",:rank=>"8")
        @inactive.save!
      end
      logger.debug "end of load_roles"
    end    
  end
  
  def Role.superuser_id
    r = Role.find(:first,:conditions=>["name = 'Super User'"])
    return r.id
  end
  
  def Role.manager_id
    r = Role.find(:first,:conditions=>["name = 'Manager'"])
    return r.id
  end

  def Role.edit_all_id
    r = Role.find(:first,:conditions=>["name = 'Edit All'"])
    return r.id
  end

  def Role.edit_groups_id
    r = Role.find(:first,:conditions=>["name = 'Edit Groups'"])
    return r.id
  end

  def Role.dataentry_id
    r = Role.find(:first,:conditions=>["name = 'Data Entry'"])
    return r.id
  end

  def Role.readonly_id
    r = Role.find(:first,:conditions=>["name = 'Read Only'"])
    return r.id
  end

  def Role.sign_in_id
    r = Role.find(:first,:conditions=>["name = 'Sign In'"])
    return r.id
  end

  def Role.inactive_id
    r = Role.find(:first,:conditions=>["name = 'Inactive'"])
    return r.id
  end

end
