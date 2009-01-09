namespace :init_setup do
  require 'yaml'

  desc "Load the basic set of user roles into the database"
  task :load_roles => :environment do
    Role.load_roles
  end

  desc "Create initial campaign"
  task :create_campaign => :load_roles do
    # create a new campaign, named based on a yml config file
    config_yaml = File.open( "#{RAILS_ROOT}/config/init_setup.yml" ) { |yf| YAML::load( yf ) }
    campaign_name = config_yaml["campaign_name"]
    campaign_email = config_yaml["campaign_email"]
    @campaign = Campaign.new(:name=>campaign_name, :from_emails=>[campaign_email])
    @campaign.save
  end

  desc "Create an initial admin user"
  task :create_admin => :create_campaign do
    params = {}
    params[:user] = {}
    config_yaml = File.open( "#{RAILS_ROOT}/config/init_setup.yml" ) { |yf| YAML::load( yf ) }
    params[:user][:email] = config_yaml["admin_user_email"]
    params[:user][:login] = config_yaml["admin_user_email"]
    params[:user][:name] = config_yaml["admin_user_name"]
    params[:user][:password] = config_yaml["admin_user_password"]
    params[:user][:password_confirmation] = config_yaml["admin_user_password"]
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      # connect to campaign
      @user.activate!
      @campaign = Campaign.find(:last)
      @superuser = Role.find(:first,:conditions=>["name = 'Super User'"])
      @cur = CampaignUserRole.new(:user_id=>@user.id, :campaign_id=>@campaign.id, :role_id=>@superuser, :financial=>true)
      @cur.save
    else
      #ERRORS!
    end
  end
  
  desc "Create and populate email_config and server_conf files"
  task :config_files => :environment do
    # TRIGGER_FILE = "/home/oc/"
    # REMOTE_PROTOCOL = "https://"
    # LOCAL_PROTOCOL = "http://"
    # REMOTE_DOWNLOAD_PATH = "/home/oc/sites/manager/current/exported_files/"
    # LOCAL_DOWNLOAD_PATH = "/Users/asa/Sites/ocmanager/exported_files/"
    # SERVER_NAME = "proton.planetargon.com"
    # BOUNCE_ADDRESS = "bounces@opencampaigns.net"
    # BOUNCE_PASSWORD = "QWD33%rt"
    # EMAIL_FROM = "open.campaigns@gmail.com"
    # ADMIN_EMAIL = "open.campaigns@gmail.com"
    # APP_URL = 'https://secure.opencampaigns.net/manager'
  end

end