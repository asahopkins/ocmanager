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

class ContributionsController < ApplicationController
  layout  'manager'
  require 'fastercsv'

  before_filter :get_campaign
  
  def import
    # display form
  end
  
  def process_import
    # process form
    data = params[:import][:data] # text
    if params[:import][:recipient_committee_id].to_s != ""
      recipient_name = nil
      recipient_id = params[:import][:recipient_committee_id].to_s
    else
      recipient_name = params[:import][:recipient]
      recipient_id = nil
    end
    matches_for_user_ok = []
    FasterCSV.parse(data) do |row|
      import_contributor_id = row[14].to_i
      first_name = row[16].to_s
      last_name = row[17].to_s
      addr_line1 = row[3].to_s
      addr_city = row[4].to_s
      phone = to_numbers(row[7].to_s)
      ent_type = row[15].to_s
      amount = to_numbers(row[10]).to_f/100.0
      # check for duplicate import_transaction_ids
      duplicate_flag = false
      dups = Contribution.find(:all,:conditions=>["import_transaction_id = :id",{:id=>row[11].to_s}])
      unless dups.empty?
        dups.each do |transaction|
          if (@campaign.id == transaction.entity.campaign_id and ((recipient_name.to_s.strip == transaction.recipient.to_s.strip) or (recipient_id.to_s.strip == transaction.recipient_committee_id.to_s) or (import_contributor_id.to_s.strip == transaction.entity.import_contributor_id.to_s.strip)))
            logger.info "DUPLICATE contribution -- skipped"
            duplicate_flag = true
          end
        end
      end
      unless duplicate_flag
        possible_match = @campaign.entities.find(:first,:conditions=>["import_contributor_id = :id",{:id=>import_contributor_id}])
        if possible_match
          #create contribution
          contrib = Contribution.new(:entity_id=>possible_match.id, :amount=>amount, :date=>row[1].to_time, :recipient=>recipient_name, :recipient_committee_id=>recipient_id,:import_transaction_id=>row[11].to_s)
          contrib.save!
        else
          possible_matches_1 = @campaign.entities.find(:all,:conditions=>["(first_name = :first OR nickname = :first) AND last_name = :last", {:first=>first_name, :last=>last_name}])
          if possible_matches_1.length > 1
            possible_matches_2 = @campaign.entities.find(:all,:conditions=>["(entities.first_name = :first OR entities.nickname = :first) AND entities.last_name = :last AND addresses.city = :city", {:first=>first_name, :last=>last_name, :city=>addr_city}],:include=>:primary_address)
            if possible_matches_2.length == 1
              matches_for_user_ok << {:entity=>possible_matches_2[0].id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}
            elsif possible_matches_2.length > 1
              possible_matches_3 = @campaign.entities.find(:all,:conditions=>["(entities.first_name = :first OR entities.nickname = :first) AND entities.last_name = :last AND addresses.city = :city AND entities.phones LIKE :phone", {:first=>first_name, :last=>last_name, :city=>addr_city, :phone=>'%'+phone+'%'}],:include=>:primary_address)
              if possible_matches_3.length == 1
                matches_for_user_ok << {:entity=>possible_matches_3[0].id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}
              elsif possible_matches_3.length > 1
                possible_match = @campaign.entities.find(:first,:conditions=>["(entities.first_name = :first OR entities.nickname = :first) AND entities.last_name = :last AND addresses.city = :city AND entities.phones LIKE :phone AND addresses.line_1 = :line_1 ", {:first=>first_name, :last=>last_name, :city=>addr_city, :phone=>'%'+phone+'%', :line_1=>addr_line1}],:include=>:primary_address)
                if possible_match.empty?
                  possible_match = possible_matches[0]
                end
                matches_for_user_ok << {:entity=>possible_match.id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}                  
              elsif possible_matches_3.length == 0
                matches_for_user_ok << {:entity=>possible_matches_2[0].id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}
              end
            elsif possible_matches_2.length == 0
              matches_for_user_ok << {:entity=>possible_matches_1[0].id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}              
            end
          elsif possible_matches_1.length == 1
            # display the possible match
            matches_for_user_ok << {:entity=>possible_matches_1[0].id, :row=>row.to_csv,:recipient_name=>recipient_name, :recipient_id=>recipient_id}
          else
            # create entity
            if ent_type == "Individual"
              household = Household.new(:campaign_id=>@campaign.id)
              household.save
              new_entity = Person.new(:campaign_id=>@campaign.id, :first_name=>first_name, :last_name=>last_name, :occupation=>row[8], :employer=>row[9], :household_id=>household.id,:name=>first_name+" "+last_name)
              new_entity.save!
              logger.debug new_entity.id
            else
              raise
            end
            new_entity.import_contributor_id = import_contributor_id.to_s.strip
            unless row[7].to_s.strip == ""
              phone_hash = {"Primary"=>to_numbers(row[7].to_s)}
              new_entity.phones = Hash.new
              new_entity.phones.update(phone_hash)
              new_entity.primary_phone = "Primary"
            end
            unless row[18].to_s.strip == ""
              fax_hash = {"Primary"=>to_numbers(row[18].to_s)}
              new_entity.faxes = Hash.new
              new_entity.faxes.update(fax_hash)              
              new_entity.primary_fax = "Primary"
            end
            new_address = Address.new(:label=>"Primary",:line_1=>addr_line1, :city=>addr_city, :state=>row[5].to_s[0..1], :zip=>row[6].to_s[0..4],:entity_id=>new_entity.id)
            new_address.save!
            new_entity.primary_address = new_address
            new_entity.mailing_address = new_address
            if row[19].to_s != ""
              email = EmailAddress.new(:label=>"Primary",:address=>row[19].to_s,:entity_id=>new_entity.id)
              email.save
              new_entity.primary_email = email
            end
            new_entity.created_by = current_user.id
            new_entity.save!
            #create contribution
            contrib = Contribution.new(:entity_id=>new_entity.id, :amount=>amount, :date=>row[1].to_time, :recipient=>recipient_name, :recipient_committee_id=>recipient_id,:import_transaction_id=>row[11].to_s)
            contrib.save!
          end
        end
      end
    end
    session[:matches_for_user_ok] = matches_for_user_ok
    redirect_to :action=>:match_entities
  end
  
  def match_entities
    # display a page with possible matches
    @matches_for_user_ok = session[:matches_for_user_ok]
    if @matches_for_user_ok.length == 0
      flash[:notice] = "All contributions were successfully imported."
      redirect_to :controller=>'campaigns', :action=>'start_here'
      return
    end
  end
  
  def process_match
    # AJAX-processing call which handles one contribution-match process (yes, they match, no they don't)
    @row = params[:row].parse_csv
    if params['Yes'] == "Yes"
      @entity = Entity.find(params[:entity_id])
      #create contribution
      amount = to_numbers(@row[10]).to_f/100.0
      contrib = Contribution.new(:entity_id=>@entity.id, :amount=>amount, :date=>@row[1].to_time, :recipient=>params[:recipient_name], :recipient_committee_id=>params[:recipient_id],:import_transaction_id=>@row[11].to_s)
      contrib.save!
      render :update do |page|
        page.replace_html params[:dom_id], "Contribution successfully attributed to #{@entity.name}."
      end
      return
    elsif params['No'] == "No"
      row = @row
      import_contributor_id = row[14].to_i
      first_name = row[16].to_s
      last_name = row[17].to_s
      addr_line1 = row[3].to_s
      addr_city = row[4].to_s
      phone = to_numbers(row[7].to_s)
      ent_type = row[15].to_s
      amount = to_numbers(row[10]).to_f/100.0
      # create entity
      if ent_type == "Individual"
        household = Household.new(:campaign_id=>@campaign.id)
        household.save
        new_entity = Person.new(:campaign_id=>@campaign.id, :first_name=>first_name, :last_name=>last_name, :occupation=>row[8], :employer=>row[9], :household_id=>household.id,:name=>first_name+" "+last_name)
        new_entity.save!
        # logger.debug new_entity.id
      else
        raise
      end
      new_entity.import_contributor_id = import_contributor_id
      unless row[7].to_s.strip == ""
        logger.debug to_numbers(row[7].to_s)
        phone_hash = {"Primary"=>to_numbers(row[7].to_s)}
        new_entity.phones = Hash.new
        new_entity.phones.update(phone_hash)
        # new_entity.save
        logger.debug new_entity.phones
        new_entity.primary_phone = "Primary"
      end
      unless row[18].to_s.strip == ""
        fax_hash = {"Primary"=>to_numbers(row[18].to_s)}
        new_entity.faxes = Hash.new
        new_entity.faxes.update(fax_hash)              
        new_entity.primary_fax = "Primary"
      end
      new_address = Address.new(:label=>"Primary",:line_1=>addr_line1, :city=>addr_city, :state=>row[5].to_s[0..1], :zip=>row[6].to_s[0..4],:entity_id=>new_entity.id)
      new_address.save!
      new_entity.primary_address = new_address
      new_entity.mailing_address = new_address
      if row[19].to_s != ""
        email = EmailAddress.new(:label=>"Primary",:address=>row[19].to_s,:entity_id=>new_entity.id)
        email.save
        new_entity.primary_email = email
      end
      new_entity.created_by = current_user.id
      new_entity.save!
      #create contribution
      contrib = Contribution.new(:entity_id=>new_entity.id, :amount=>amount, :date=>row[1].to_time, :recipient=>params[:recipient_name], :recipient_committee_id=>params[:recipient_id],:import_transaction_id=>row[11].to_s)
      contrib.save!  
      render :update do |page|
        page.replace_html params[:dom_id], "New entry created, and the contribution attributed to it."
      end
      return
    end
  end

end