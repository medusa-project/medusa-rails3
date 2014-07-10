module FileGroupsHelper

  def producers_select_collection
    Producer.order(:title).load.collect do |producer|
      [producer.title, producer.id]
    end
  end

  def file_types_select_collection
    FileType.order(:name).load.collect do |type|
      [type.name, type.id]
    end
  end

  def cfs_file_group_root_select_collection(file_group)
    #an existing record for a file group of type that doesn't support cfs doesn't need anything to display
    return [] unless (file_group.new_record? or file_group.supports_cfs)
    available_roots = CfsRoot.instance.available_roots
    available_roots.unshift(file_group.cfs_directory) if !file_group.new_record? and file_group.cfs_directory.present?
    available_roots.collect do |cfs_directory|
      [cfs_directory.path, cfs_directory.id]
    end
  end

  def file_group_form_tab_list
    ['essential-information', 'rights-declaration', 'summary', 'provenance-note',
     'collection-file-package-summary', 'related-file-groups']
  end

  def file_group_show_tab_list
    tabs = ['description', 'rights', 'assessments', 'attachments']
    if @file_group.cfs_directory.present?
      tabs << 'amazon'
    end
    tabs.collect {|x| ["#{x}-tab", x.capitalize]}
  end

  def package_profile_select_collection
    PackageProfile.order('name ASC').load.collect {|profile| [profile.name, profile.id]}
  end

end
