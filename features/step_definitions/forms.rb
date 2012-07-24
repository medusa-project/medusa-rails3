When /^I fill in fields:$/ do |table|
  table.hashes.each do |hash|
    fill_in(hash[:field], :with => hash[:value])
  end
end

When /^I press '(.*)'$/ do |button_name|
  click_button(button_name)
end

Then /^I should see '(.*)'$/ do |text|
  page.should have_content(text)
end

