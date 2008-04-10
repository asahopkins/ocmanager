entities = Entity.find(:all)

entities.each do |entity|
  if entity.emails and entity.emails.class==Hash and entity.emails.length >= 1 and entity.email_addresses.length == 0
    entity.emails.each do |label, address|
      email_address = EmailAddress.new(:entity_id=>entity.id, :label=>label, :address=>address, :invalid=>false, :created_by=>entity.created_by, :updated_by=>entity.updated_by)
      email_address.save
      if email_address.label == entity.primary_email_label
        entity.update_attribute(:primary_email_id, email_address.id)
      end
    end
  end
end