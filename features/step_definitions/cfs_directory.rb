Then(/^I should be viewing the cfs root directory for the file group titled '(.*)'$/) do |title|
  file_group = FileGroup.find_by(title: title)
  expect(current_path).to eq(cfs_directory_path(file_group.cfs_directory))
end

When(/^I view the cfs directory for the file group titled '(.*)' for the path '(.*)'$/) do |title, path|
  file_group = FileGroup.find_by(title: title)
  visit cfs_directory_path(file_group.cfs_directory_at_path(path))
end

Given(/^I public view the cfs directory for the file group titled '(.*)' for the path '(.*)'$/) do |title, path|
  file_group = FileGroup.find_by(title: title)
  visit public_cfs_directory_path(file_group.cfs_directory_at_path(path))
end

Then(/^I should be viewing the cfs directory for the file group titled '(.*)' for the path '(.*)'$/) do |title, path|
  file_group = FileGroup.find_by(title: title)
  expect(current_path).to eq(cfs_directory_path(file_group.cfs_directory_at_path(path)))
end

Then(/^I should be public viewing the cfs directory for the file group titled '(.*)' for the path '(.*)'$/) do |title, path|
  file_group = FileGroup.find_by(title: title)
  expect(current_path).to eq(public_cfs_directory_path(file_group.cfs_directory_at_path(path)))
end

When(/^the cfs directory for the path '(.*)' for the file group titled '(.*)' has an assessment scheduled$/) do |path, title|
  file_group = FileGroup.find_by(title: title)
  cfs_directory = file_group.cfs_directory_at_path(path)
  Job::CfsInitialDirectoryAssessment.create(cfs_directory: cfs_directory, file_group: file_group)
end

Then(/^the file group titled '(.*)' should have root cfs directory with path '(.*)'$/) do |title, path|
  file_group = FileGroup.find_by(title: title)
  expect(file_group.cfs_directory.path).to eq(path)
end

Given(/^there are cfs directories with fields:$/) do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:cfs_directory, hash)
  end
end

And(/^there are cfs subdirectories of the cfs directory with path '(.*)' with fields:$/) do |path, table|
  parent = CfsDirectory.find_by(path: path)
  table.hashes.each do |hash|
    parent.subdirectories.create!(hash.merge(root_cfs_directory_id: parent.root_cfs_directory_id))
  end
end

And(/^there are cfs files of the cfs directory with path '(.*)' with fields:$/) do |path, table|
  parent = CfsDirectory.find_by(path: path)
  table.hashes.each do |hash|
    parent.cfs_files.create!(hash)
  end
end

Then(/^the cfs directory for the path '(.*)' should have tree size (\d+) and count (\d+)$/) do |path, size, count|
  cfs_directory = CfsDirectory.find_by(path: path)
  expect(cfs_directory.tree_size).to eq(size.to_d)
  expect(cfs_directory.tree_count).to eq(count.to_d)
end