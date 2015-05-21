And(/^the bag '(.*)' is staged in the root named '(.*)' at path '(.*)'$/) do |bag_name, root_name, path|
  root = StagingStorage.instance.root_named(root_name)
  staging_target = File.join(root.local_path, path)
  FileUtils.rm_rf(staging_target)
  FileUtils.mkdir_p(staging_target)
  FileUtils.cp_r(File.join(Rails.root, 'features', 'fixtures', 'bags', bag_name, 'data'), staging_target)
end

And(/^I should see the accrual form and dialog$/) do
  expect(page).to have_selector('form#add-files-form')
  expect(page).to have_selector('#add-files-dialog')
end

And(/^I should not see the accrual form and dialog$/) do
  expect(page).not_to have_selector('form#add-files-form')
  expect(page).not_to have_selector('#add-files-dialog')
end

Then(/^the cfs directory with path '(.*)' should have an accrual job with (\d+) files? and (\d+) director(?:y|ies)$/) do |path, file_count, directory_count|
  cfs_directory = CfsDirectory.find_by(path: path)
  accrual_job = Workflow::AccrualJob.find_by(cfs_directory_id: cfs_directory.id)
  expect(accrual_job.workflow_accrual_files.count).to eql(file_count.to_i)
  expect(accrual_job.workflow_accrual_directories.count).to eql(directory_count.to_i)
end

And(/^the cfs directory with path '(.*)' should have an accrual job with (\d+) minor conflicts? and (\d+) serious conflicts?$/) do |path, minor_conflict_count, serious_conflict_count|
  cfs_directory = CfsDirectory.find_by(path: path)
  accrual_job = Workflow::AccrualJob.find_by(cfs_directory_id: cfs_directory.id)
  expect(accrual_job.workflow_accrual_conflicts.not_serious.count).to eql(minor_conflict_count.to_i)
  expect(accrual_job.workflow_accrual_conflicts.serious.count).to eql(serious_conflict_count.to_i)
end

Then(/^the cfs directory with path '(.*)' should not have an accrual job$/) do |path|
  cfs_directory = CfsDirectory.find_by(path: path)
  accrual_job = Workflow::AccrualJob.find_by(cfs_directory_id: cfs_directory.id)
  expect(accrual_job).to be_nil
end