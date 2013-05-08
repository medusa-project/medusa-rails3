module FileGroupsHelper

  def producers_select_collection
    Producer.order(:title).all.collect do |producer|
      [producer.title, producer.id]
    end
  end

  def file_types_select_collection
    FileType.order(:name).all.collect do |type|
      [type.name, type.id]
    end
  end

  def file_group_form_tab_list
    ['base', 'rights-declaration', 'summary', 'provenance-note',
     'collection-file-package-summary', 'related-file-groups']
  end

end
