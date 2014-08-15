Given(/^the collection titled '(.*)' has an access system named '(.*)'$/) do |title, name|
  collection = Collection.find_by_title(title) || FactoryGirl.create(:collection, :title => title)
  access_system = AccessSystem.find_by_name(name) || FactoryGirl.create(:access_system, :name => name)
  collection.access_systems << access_system
end
