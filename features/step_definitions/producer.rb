And /^I have producers with fields:$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create :producer, hash
  end
end

Then /^I should see all producer fields$/ do
  ['Address 1', 'Address 2', 'City', 'State', 'Zip', 'Phone Number', 'Email', 'URL', 'Notes'].each do |field|
    step "I should see '#{field}'"
  end
end

Then /^I should be on the producer creation page$/ do
  current_path.should == new_producer_path
end

And /^The collection titled '(.*)' has (\d+) file groups? produced by '(.*)'$/ do |collection, count, producer|
  collection = Collection.find_by_title(collection)
  producer = Producer.find_by_title(producer)
  count.to_i.times do
    FactoryGirl.create(:file_group, :collection => collection, :producer => producer)
  end
end
