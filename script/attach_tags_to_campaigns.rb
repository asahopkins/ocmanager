#!/usr/bin/env ruby

@campaigns = Campaign.find(:all)
@campaigns.each do |campaign|
  @tags = campaign.find_all_tags
  @tags.each do |tag|
    tag.campaign = campaign
    tag.save
  end
end