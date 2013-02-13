FactoryGirl.define do
  factory :file_group do
    sequence(:name) {|n| "File Group #{n}"}
    storage_level 'external'
    external_file_location 'External File Location'
    file_format 'image/jpeg'
    total_file_size 10
    total_files 100
    storage_medium StorageMedium.find_by_name('DVD')
    file_type FileType.find_by_name('Other')
    collection
  end
end