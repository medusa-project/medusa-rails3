Then /^There should be standard default file types$/ do
   ['Derivatgit ive Content','Master Metadata','Other'].each do |name|
    FileType.find_by_name(name).should_not be_nil
  end
end