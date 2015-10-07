# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'cucumber/rails'
require 'json_spec/cucumber'
require 'capybara/poltergeist'
require 'sunspot_test/cucumber'

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

#This preserves compatibility with Capybara 1.x, under which we started developing
Capybara.match = :prefer_exact

#set drivers
Capybara.javascript_driver = :poltergeist
#Capybara.javascript_driver = :selenium
Capybara.default_driver = :rack_test

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

#make sure database is seeded before loading test code - this is necessary because some of the factories, etc. assume
#that the seeded stuff is there
def ensure_db_is_seeded
  if StaticPage.count == 0
    load File.join(Rails.root, 'db', 'seeds.rb')
  end
end

ensure_db_is_seeded

DatabaseCleaner.strategy = :transaction
# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
#Cucumber::Rails::Database.javascript_strategy = :truncation, {:except => %w[storage_media resource_types preservation_priorities static_pages]}
Cucumber::Rails::Database.javascript_strategy = :transaction

def last_json
  page.source
end

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
  end
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

require 'capybara/email'
World(Capybara::Email::DSL)