class Search < ActiveRecord::Base
  belongs_to :user
  belongs_to :campaign
  
  serialize :cond, Array
  serialize :includes, Array
  
end
