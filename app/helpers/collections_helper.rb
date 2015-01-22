module CollectionsHelper

  def access_system_select_collection
    AccessSystem.all.collect {|system| [system.name, system.id]}
  end

  def repository_select_collection
    Repository.order(:title).collect {|repository| [repository.title, repository.id]}
  end

  def collection_confirm_message
    'This is irreversible. Associated assessments and file groups will also be deleted.'
  end

  def collection_form_tab_list
    %w(descriptive-metadata administrative-metadata rights-metadata)
  end

end
