Then(/^the file group named '(.*)' should have a scheduled event with fields:$/) do |name, table|
  file_group = FileGroup.find_by_name(name)
  table.hashes.each do |hash|
    file_group.scheduled_events.where(hash).first.should be_truthy
  end
end

Given(/^the file group named '(.*)' has scheduled events with fields:$/) do |name, table|
  file_group = FileGroup.find_by_name(name)
  table.hashes.each do |hash|
    file_group.scheduled_events.create(hash)
  end
end

Then(/^I should on the edit page for the scheduled event with key '(.*)' and action date '(.*)'$/) do |key, date|
  current_path.should == edit_scheduled_event_path(ScheduledEvent.where(key: key, action_date: date).first)
end

When(/^I edit the scheduled event with key '(.*)' and action date '(.*)'$/) do |key, date|
  visit edit_scheduled_event_path(ScheduledEvent.where(key: key, action_date: date).first)
end

Then(/^there should be no scheduled event having key '(.*)' and action date '(.*)'$/) do |key, date|
  ScheduledEvent.where(key: key, action_date: date).first.should == nil
end

