And /^I go to the site home$/ do
  visit '/'
end

Then /^I should be on the site home page$/ do
  current_path.should == root_path
end

Then /^I should see a global navigation bar$/ do
  page.should have_selector('#global-navigation')
end

When /^I click on '(.*)' in the global navigation bar$/ do |name|
  within('#global-navigation') {click_link name}
end

Then /^I should see a link to '(.*)'$/ do |url|
  #page.has_link?(url, :href => url).should be_true
  page.should have_link(url)
end

