module FileGroupsHelper

  def producers_select_collection
    Producer.order(:title).load.collect do |producer|
      [producer.title, producer.id]
    end
  end

  def file_group_form_tab_list
    %w(descriptive-metadata administrative-metadata)
  end

end
