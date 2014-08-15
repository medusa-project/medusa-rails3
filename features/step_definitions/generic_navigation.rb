When /^I go to the (.*) index page$/ do |object_type|
  visit generic_collection_path(object_type)
end

Then /^I should be on the (.*) index page$/ do |object_type|
  expect(current_path).to eq(generic_collection_path(object_type))
end

When /^I view the (.*) with (.*) '(.*)'$/ do |object_type, key, value|
  visit generic_object_path(object_type, key, value)
end

Then /^I should be on the view page for the (.*) with (.*) '(.*)'$/ do |object_type, key, value|
  expect(current_path).to eq(generic_object_path(object_type, key, value))
end

When /^I edit the (.*) with (.*) '(.*)'$/ do |object_type, key, value|
  visit generic_object_path(object_type, key, value, 'edit')
end

Then /^I should be on the edit page for the (.*) with (.*) '(.*)'$/ do |object_type, key, value|
  expect(current_path).to eq(generic_object_path(object_type, key, value, 'edit'))
end

Then /^I should be on the update page for the (.*) with (.*) '(.*)'$/ do |object_type, key, value|
  expect(current_path).to eq(generic_object_path(object_type, key, value))
end

Then /^I should be on the new (.*) page$/ do |object_type|
  expect(current_path).to eq(self.send("new_#{object_type.gsub(' ', '_')}_path"))
end

Then /^I should be on the create (.*) page$/ do |object_type|
  expect(current_path).to eq(generic_collection_path(object_type))
end

def generic_collection_path(object_type)
  self.send(:"#{object_type.gsub(' ', '_').pluralize}_path")
end

def class_for_object_type(object_type)
  Kernel.const_get(object_type.gsub(' ', '_').camelize)
end

def generic_object_path(object_type, key, value, prefix = nil)
  klass = class_for_object_type(object_type)
  path_prefix = prefix ? "#{prefix}_" : ''
  self.send(:"#{path_prefix}#{object_type.gsub(' ', '_')}_path", klass.find_by(key => value))
end