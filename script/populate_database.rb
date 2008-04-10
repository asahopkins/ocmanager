male_first_names = ["JAMES", "JOHN", "ROBERT", "MICHAEL", "WILLIAM", "DAVID", "RICHARD", "CHARLES", "JOSEPH", "THOMAS", "CHRISTOPHER", "DANIEL", "PAUL", "MARK", "DONALD", "GEORGE", "KENNETH", "STEVEN", "EDWARD", "BRIAN"]
female_first_names = ["MARY", "PATRICIA", "LINDA", "BARBARA", "ELIZABETH", "JENNIFER", "MARIA", "SUSAN", "MARGARET", "DOROTHY", "LISA", "NANCY", "KAREN", "BETTY", "HELEN", "SANDRA", "DONNA", "CAROL", "RUTH", "SHARON"]
last_names = ["Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor",
   "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson",
    "Clark" , "Rodriguez",  "Lewis", "Lee" , "Walker",  "Hall" , "Allen" , "Young" , "Hernandez", "King" ,"Wright" ,
    "Lopez" , "Hill" ,"Scott" ,"Green" ,"Adams" ,"Baker" ,"Gonzalez" ,"Nelson" ,"Carter" ,"Mitchell", "Perez" ,
    "Roberts", "Turner" ,"Phillips", "Campbell" ,"Parker" , "Evans" ,"Edwards", "Collins" ,"Stewart" ,"Sanchez" ,
    "Morris" ,"Rogers" ,"Reed" ,"Cook" ,"Morgan", "Bell" ,"Murphy", "Bailey" ,"Rivera" ,"Cooper" ,"Richardson", 
    "Cox" ,"Howard", "Ward" ,"Torres", "Peterson", "Gray" ,"Ramirez", "James" ,"Watson" ,"Brooks","Kelly" ,"Sanders", 
    "Price" ,"Bennett", "Wood" ,"Barnes", "Ross" ,"Henderson", "Coleman" ,"Jenkins" ,"Perry" ,"Powell" ,"Long" ,
    "Patterson", "Hughes" ,"Flores" ,"Washington" ,"Butler" ,"Simmons" ,"Foster" ,"Gonzales", "Bryant" ,"Alexander", 
    "Russell" ,"Griffin" ,"Diaz" ,"Hayes"]
street_names = ["Main St.", "Oak St.", "First Ave.", "Second Ave.", "Third Ave.", "Fourth Ave.", "Elm St.", "Court St.", "Fifth Ave.", "Maple St."]
towns = [["Pasadena", "91101"],["Altadena", "91001"], ["South Pasadena", "91030"]]
count = 100
campaign = 1

1.upto(count) do |hh|
  # puts hh
  Entity.transaction do
    num_r = rand
    last_name = last_names[rand(100)]
    h = Household.new(:campaign_id=>campaign)
    h.save!
    town = towns[rand(3)]
    phone_hash = {"Home"=>"626555"+rand(10000).to_s}
    addr_hash = {:label=>"Home",:line_1=>rand(1000).to_s + " "+street_names[rand(10)],:city=>town[0],:state=>"CA",:zip=>town[1]}
    if num_r > 0.95
      # three people in household
      3.times do
        if rand > 0.5
          a = Person.new(:first_name=>male_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")
          a.title = "Mr." if rand > 0.9
        else
          a = Person.new(:first_name=>female_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")      
          a.title = "Ms." if rand > 0.9
        end
        a.household = h
        a.name = a.first_name+" "+a.last_name
        a.phones = Hash.new
        if rand > 0.2
          a.phones.update(phone_hash)
        end
        a.save!
        address = Address.new(addr_hash)
        address.entity = a
        address.save!
        a.primary_address = address
        a.mailing_address = address
        a.created_by = 1
        if rand > 0.25
          email_address = EmailAddress.new(:label=>"Primary", :address=>a.first_name[0,1]+last_name+"@example.org", :entity_id=>a.id)
          email_address.save!
          a.primary_email = email_address
          if rand > 0.95
            a.receive_email = false
          end
        end
        if rand > 0.6
          a.registered_party = "Democratic"
        end
        a.save!
      end
    elsif num_r > 0.7
      # two people in household
      2.times do
        if rand > 0.5
          a = Person.new(:first_name=>male_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")
          a.title = "Mr." if rand > 0.9
        else
          a = Person.new(:first_name=>female_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")      
          a.title = "Ms." if rand > 0.9
        end
        a.household = h
        a.name = a.first_name+" "+a.last_name
        a.phones = Hash.new
        if rand > 0.2
          a.phones.update(phone_hash)
        end
        a.save!
        address = Address.new(addr_hash)
        address.entity = a
        address.save!
        a.primary_address = address
        a.mailing_address = address
        a.created_by = 1
        if rand > 0.25
          email_address = EmailAddress.new(:label=>"Primary", :address=>a.first_name[0,1]+last_name+"@example.net", :entity_id=>a.id)
          email_address.save!
          a.primary_email = email_address
          if rand > 0.95
            a.receive_email = false
          end
        end
        if rand > 0.6
          a.registered_party = "Democratic"
        end
        a.save!
      end
    else
      # one person in household
      if rand > 0.5
        a = Person.new(:first_name=>male_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")
        a.title = "Mr." if rand > 0.9
      else
        a = Person.new(:first_name=>female_first_names[rand(20)].capitalize, :last_name=>last_name, :campaign_id=>campaign, :primary_phone=>"Home")      
        a.title = "Ms." if rand > 0.9
      end
      a.household = h
      a.name = a.first_name+" "+a.last_name
      a.phones = Hash.new
      if rand > 0.2
        a.phones.update(phone_hash)
      end
      a.save!
      address = Address.new(addr_hash)
      address.entity = a
      address.save!
      a.primary_address = address
      a.mailing_address = address
      a.created_by = 1
      email_rand = rand
      if email_rand > 0.8
        email_address = EmailAddress.new(:label=>"Primary", :address=>a.first_name[0,1]+last_name+"@example.net", :entity_id=>a.id)
        email_address.save!
        a.primary_email = email_address
        if rand > 0.95
          a.receive_email = false
        end
      elsif email_rand > 0.25
        email_address = EmailAddress.new(:label=>"Primary", :address=>a.first_name[0,1]+last_name+"@example.com", :entity_id=>a.id)
        email_address.save!
        a.primary_email = email_address
        if rand > 0.95
          a.receive_email = false
        end
      end
      if rand > 0.6
        a.registered_party = "Democratic"
      end
      a.save!
    end
  end
end