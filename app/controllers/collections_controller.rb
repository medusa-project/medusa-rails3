class CollectionsController < ApplicationController

  before_action :require_medusa_user, except: [:show, :index]
  before_action :require_medusa_user_or_basic_auth, only: [:show, :index]
  before_action :find_collection_and_repository, only: [:show, :destroy, :edit, :update, :red_flags,
                                                        :assessments, :attachments, :events,
                                                        :show_file_stats]

  helper_method :load_collection_file_extension_stats, :load_collection_content_type_stats

  include ModelsToCsv

  def show
    @projects = @collection.projects
    respond_to do |format|
      format.html
      format.xml { render xml: @collection.to_mods }
      format.json
    end
  end

  def attachments
    @attachable = @collection
  end

  def assessments
    @assessable = @collection
    @assessments = @assessable.recursive_assessments
  end

  def destroy
    authorize! :destroy, @collection
    @collection.destroy
    redirect_to repository_path(@repository)
  end

  def edit
    authorize! :update, @collection
  end

  def update
    authorize! :update, @collection
    if @collection.update_attributes(allowed_params)
      redirect_to collection_path(@collection)
    else
      render 'edit'
    end
  end

  def new
    @collection = Collection.new
    @collection.rights_declaration = RightsDeclaration.new(rights_declarable_type: 'Collection')
    @repository = Repository.find(params[:repository_id]) rescue Repository.order(:title).first
    @collection.repository = @repository
    authorize! :create, @collection
  end

  def create
    #this is a tiny bit unintuitive, but we have to do enough at the start to perform authorization
    @repository = Repository.find(params[:collection][:repository_id]) rescue Repository.order(:title).first
    @collection = Collection.new
    @collection.repository = @repository
    authorize! :create, @collection
    if @collection.update_attributes(allowed_params)
      redirect_to collection_path(@collection)
    else
      render 'new'
    end
  end

  def index
    #Getting file groups and cfs_directories speeds things up considerably for an initial generation of the view,
    #but slows it down a bit when most of the rows are cached. I don't know how to decide ahead of time, so
    #I have chosen this way of doing it to reduce the maximum time.
    @collections = Collection.order(:title).includes(:repository, :preservation_priority, :contact)
    respond_to do |format|
      format.html
      format.csv { send_data collections_to_csv(@collections), type: 'text/csv', filename: 'collections.csv' }
      format.json { @collections.includes(:medusa_uuid) }
    end
  end

  def red_flags
    @red_flags = @collection.cascaded_red_flags
    @aggregator = @collection
  end

  def events
    @eventable = Collection.find(params[:id])
    @events = @eventable.cascaded_events
  end

  def show_file_stats
    respond_to do |format|
      format.html { render partial: 'file_stats_table', layout: false }
      format.csv do
        content_type_hashes = load_collection_content_type_stats(@collection)
        file_extension_hashes = load_collection_file_extension_stats(@collection)
        send_data file_stats_to_csv(content_type_hashes, file_extension_hashes), type: 'text/csv', filename: 'file-statistics.csv'
      end
    end
  end

  protected

  def find_collection_and_repository
    @collection = Collection.find(params[:id])
    @collection.build_contact unless @collection.contact
    @breadcrumbable = @collection
    @repository = @collection.repository
  end

  def allowed_params
    params[:collection].permit(:access_url, :description, :private_description, :end_date, :notes,
                               :repository_id, :start_date, :title,
                               :publish, :representative_image, :representative_item,
                               :preservation_priority_id, :package_profile_id, :contact_email, :external_id,
                               rights_declaration_attributes: [:rights_basis, :copyright_jurisdiction, :copyright_statement,
                                                               :access_restrictions, :custom_copyright_statement, :id],
                               resource_type_ids: [], access_system_ids: []
    )
  end

  def load_collection_content_type_stats(collection)
    ActiveRecord::Base.connection.
        select_all(load_collection_content_type_sql, nil, [[nil, collection.id]])
  end

  def load_collection_file_extension_stats(collection)
    ActiveRecord::Base.connection.
        select_all(load_collection_file_extension_sql, nil, [[nil, collection.id]]).to_hash
  end

  def load_collection_content_type_sql
    <<SQL
    SELECT CTS.content_type_id, CTS.name, CTS.file_size, CTS.file_count,
    COALESCE(CTC.count,0) AS tested_count
    FROM view_file_content_type_stats_by_collection CTS
    LEFT JOIN (SELECT content_type_id, count FROM view_tested_file_content_type_counts_by_collection WHERE collection_id = $1) CTC
    ON CTS.content_type_id = CTC.content_type_id
    WHERE collection_id = $1
SQL
  end

  def load_collection_file_extension_sql
    <<SQL
    SELECT FES.file_extension_id, FES.extension, FES.file_size, FES.file_count,
    COALESCE(FEC.count,0) AS tested_count
    FROM view_file_extension_stats_by_collection FES
    LEFT JOIN (SELECT file_extension_id, count FROM view_tested_file_file_extension_counts_by_collection WHERE collection_id = $1) FEC
    ON FES.file_extension_id = FEC.file_extension_id
    WHERE collection_id = $1
SQL
  end

end
