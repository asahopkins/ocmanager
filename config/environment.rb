# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '1.2.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # =======
    # HACK
    require 'drb'
    class DRb::DRbTCPSocket
      class << self
        alias parse_uri_orig parse_uri
        def parse_uri(*args)
          ary = parse_uri_orig(*args)
          ary[1] = nil if ary[1] == 0
          ary
        end
      end
    end
  # =======
  # Settings in config/environments/* take precedence those specified here
  
  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "rubyist-aasm", :lib => "aasm", :source => "http://gems.github.com"
  config.gem 'mislav-will_paginate', :version => '~> 2.3.6', :lib => 'will_paginate', :source => 'http://gems.github.com'
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store
  config.action_controller.session = {
    :session_key => '_manager_session',
    :secret      => '109cd2c583e1735a3d3cc16de9934963a49bb0f1e2204a43179cc6c10cf08f5c5ebdb1461512b26daa22d4b398cd3becc83004b83edffe4dad186dfd64cfb2b2'
  }

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  config.active_record.observers = :user_observer

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
  
  config.action_controller.relative_url_root="/manager"
  
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# require 'email_config'
# require 'server_config'
ActionController::Base.session_options[:session_key] = '_manager'
# require 'environments/localization_environment'
# require 'localization'
# Localization::load_localized_strings
require 'environments/user_environment'
require 'memory_logging'
require 'pdf/writer'

class Time   
  %w(to_date to_datetime).each do |method|   
    public method if private_instance_methods.include?(method)   
  end   
end

#ActionView::Base.register_template_handler 'rpdf', ActionView::PDFRender

