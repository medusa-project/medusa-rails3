FactoryGirl.define do
  factory :fits_directory_job, class: Job::FitsDirectory do
    cfs_directory
    file_group
    file_count 1
  end
end