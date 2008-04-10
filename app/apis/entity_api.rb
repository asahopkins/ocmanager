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
class EntityApi < ActionWebService::API::Base
  
  api_method :find_entity_by_id, 
              :expects=>[{:id=>:integer},
                         {:campaign_id=>:integer},
                         {:login=>:string},
                         {:token=>:string}], 
              :returns=>[BasicEntity]
  
  api_method :find_entities_by_name, # or part of a name
              :expects=>[{:value=>:string},
                         {:limit=>:int},
                         [:string], # types (person, organization, committee)
                         {:campaign_id=>:int},
                         {:login=>:string},
                         {:token=>:string}], 
              :returns=>[[BasicEntity]]
                
  api_method :create_entity_from_struct,
              :expects=>[{:campaign_id=>:int},
                         {:committee_id=>:int},
                         {:basic_entity=>BasicEntity},
                         {:login=>:string},
                         {:token=>:string}],
              :returns=>[{:manager_id=>:int}]

  api_method :update_entity_from_struct,
              :expects=>[{:manager_id=>:int},
                        {:campaign_id=>:int},
                        {:committee_id=>:int},
                        {:basic_entity=>BasicEntity},
                        {:login=>:string},
                        {:token=>:string}],
              :returns=>[{:manager_id=>:int}]


#  api_method :add_entity_treasurer_id,
#              :expects=>[{:manager_id=>:int},
#                         {:treasurer_id=>:int},
#                         {:login=>:string},
#                         {:token=>:string}],
#              :returns=>[{:manager_id=>:int}]
  
end
