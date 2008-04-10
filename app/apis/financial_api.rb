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
class FinancialApi < ActionWebService::API::Base
  api_method :get_financial_summary_by_id,
    :expects=>[{:login=>:string},
               {:token=>:string},
               {:committee_id=>:integer},
               {:id=>:integer}],
    :returns=>[FinancialSummary]
               
  api_method :notify_of_deletion,
    :expects=>[{:login=>:string},
               {:token=>:string},
               {:committee_id=>:integer},
               {:id=>:integer}],
    :returns=>[{:ack=>:bool}]

  api_method :get_entities_by_finances_and_date,
    :expects=>[{:login=>:string},
               {:token=>:string},
               {:committee_id=>:integer},
               {:start_date=>:date},
               {:end_date=>:date},
               {:value=>:float},
               {:single=>:boolean},  #true: single event; false: total in period (default false)
               {:contribution=>:boolean}, #true: contribution; false: expense (default true)
               {:exceeds=>:boolean}], # true: exceeds value; false: less than value (default true)
    :returns=>[{:entities=>[:integer]}]
      
  api_method :get_transaction_values_by_date,
    :expects=>[{:login=>:string},
               {:token=>:string},
               {:committee_id=>:integer},
               {:entity_id=>:integer},
               {:start_date=>:date},
               {:end_date=>:date},
               {:latest=>:boolean},  #true: single event; false: total in period (default false)
               {:contribution=>:boolean}], #true: contribution; false: expense (default true)
    :returns=>[{:value=>:float}]
    
    api_method :get_transactions_by_entity_id_and_date,
      :expects=>[{:login=>:string},
                 {:token=>:string},
                 {:committee_id=>:integer},
                 {:entity_id=>:integer},
                 {:contribution=>:boolean}, #true: contribution; false: expense (default true)
                 {:start_date=>:datetime}, # default 100 years ago
                 {:end_date=>:datetime}], # default Time.now
      :returns=>[:events=>[TreasurerEvent]]
end
