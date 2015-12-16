class SearchHelper::EnhancedItem < SearchHelper::Base

  attr_accessor :project, :batch

  def base_class
    ::Item
  end

  def initialize(args = {})
    super
    self.project = args[:project]
    self.batch = args[:batch]
  end

  def table_id
    'items'
  end

  def url
    Rails.application.routes.url_helpers.items_project_path(project, format: :json, batch: batch)
  end

  def full_count
    project.items.count
  end

  def search
    @search ||= base_class.search do
      fulltext search_string, fields: search_fields
      paginate page: page, per_page: per_page
      order_by order_field, order_direction
      all_of do
        with :project_id, project.id
        with :batch, batch
      end
    end
  end


  def columns
    [{header: 'Barcode', solr_field: :barcode, value_method: :search_barcode_link, searchable: true},
     {header: 'Bib Id', solr_field: :bib_id, value_method: :bib_id, searchable: true},
     {header: 'Title', solr_field: :some_title, value_method: :some_title, searchable: true},
     {header: 'Notes', solr_field: :notes, value_method: :notes, searchable: true},
     {header: 'Batch', solr_field: :batch, value_method: :batch, searchable: true},
     {header: 'Assign', value_method: ->(decorated_item) {decorated_item.assign_checkbox(project)} },
     {header: 'Call Number', solr_field: :call_number, value_method: :call_number, searchable: true},
     {header: 'Author', solr_field: :author, value_method: :author, searchable: true},
     {header: 'Record Series Id', solr_field: :record_series_id, value_method: :record_series_id, searchable: true},
     {header: '', value_method: :action_buttons}]
  end

end