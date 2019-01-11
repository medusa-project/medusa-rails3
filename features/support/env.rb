# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'cucumber/rails'
require 'json_spec/cucumber'
require 'capybara/poltergeist'
require 'sunspot_test/cucumber'
require 'capybara/mechanize/cucumber'
require 'fileutils'

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

#This preserves compatibility with Capybara 1.x, under which we started developing
Capybara.match = :prefer_exact

Capybara.server = :puma

Capybara.default_driver = :rack_test
#For this to work chromedriver must be installed on the path. I've
# taken the gem out of the gemfile since it is generally available and
# more up to date through brew, npm, or the like
Capybara.javascript_driver = :selenium_chrome_headless
#Capybara.javascript_driver = :poltergeist
#Capybara.javascript_driver = :webkit
#Capybara.javascript_driver = :selenium
# Capybara.javascript_driver = :selenium_chrome

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
Cucumber::Rails::Database.javascript_strategy = :truncation,
    {except: %w(storage_media resource_types preservation_priorities static_pages file_format_test_reasons),
     pre_count: true}

def last_json
  page.source
end

%i(selenium chrome selenium_chrome_headless selenium_chrome poltergeist webkit selenium_chrome_headless_downloading).each do |driver|
  Around("@#{driver}") do |scenario, block|
    begin
      Capybara.current_driver = driver
      block.call
    ensure
      Capybara.use_default_driver
    end
  end
end

# Register a driver specially for downloading stuff
# This is basically taken from:
# https://gist.github.com/bbonamin/4b01be9ed5dd1bdaf909462ff4fdca95
CAPYBARA_DOWNLOAD_DIR = Rails.root.join('tmp/test-downloads').to_s
Capybara.register_driver :selenium_chrome_headless_downloading do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_preference(:download, prompt_for_download: false, default_directory: CAPYBARA_DOWNLOAD_DIR)
  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })
  options.headless!
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  ### Allow file downloads in Google Chrome when headless!!!
  ### https://bugs.chromium.org/p/chromium/issues/detail?id=696481#c89
  bridge = driver.browser.send(:bridge)
  path = '/session/:session_id/chromium/send_command'
  path[':session_id'] = bridge.session_id
  bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
                   params: {
                       behavior: 'allow',
                       downloadPath: CAPYBARA_DOWNLOAD_DIR
                   })
  driver
end

Before("@selenium_chrome_headless_downloading") do
  FileUtils.rm_rf(CAPYBARA_DOWNLOAD_DIR)
  FileUtils.mkdir_p(CAPYBARA_DOWNLOAD_DIR)
end

#Make sure the browser is big enough - a few of the tests will send input to the wrong place if
# it is not wide enough.
Before("@javascript") do
  Capybara.current_session.current_window.resize_to(1600, 1200)
end

require 'capybara/email'
World(Capybara::Email::DSL)

puts "Compiling webpack"
Dir.chdir(Rails.root) do
  system("RAILS_ENV=test bundle exec rake webpacker:compile")
end
puts "Webpack compiled"

#Uncommenting the activating line will look at the page object at the end of each test and if it is html will
# dump it into tmp/html_dump. It also creates a manifest file mapping the file to the page url
# This is far from perfect and massively redundant, but will allow a decent amount of html validation checking
# with little additional effort, so is fine for now.
# Note that we may set some other places in the code that also dump when the dumper is active.
require_relative('html_dumper')
After do
  begin
    HtmlDumper.instance.dump(page)
  rescue Exception => e
    puts "Problem dumping html: #{e}"
  end
end
