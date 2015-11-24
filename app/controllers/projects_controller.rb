class ProjectsController < ApplicationController

  before_action :require_logged_in
  before_action :find_project, only: [:show, :edit, :update, :destroy, :attachments, :assign_batch]
  include ModelsToCsv

  autocomplete :user, :email

  def index
    @projects = Project.order('title ASC')
    respond_to do |format|
      format.html
      format.csv { send_data projects_to_csv(@projects), type: 'text/csv', filename: 'projects.csv' }
    end
  end

  def new
    @collection = Collection.find(params[:collection_id])
    @project = Project.new
    @project.collection = @collection
    authorize! :create, @project
  end

  def create
    @project = Project.new(allowed_params)
    authorize! :create, @project
    if @project.save
      redirect_to @project
    else
      @collection = @project.collection
      render 'new'
    end
  end

  def edit
    authorize! :update, @project
    @collection = @project.collection
  end

  def update
    authorize! :update, @project
    authorize! :update, Collection.find(params[:project][:collection_id])
    if @project.update_attributes(allowed_params)
      redirect_to @project
    else
      render 'edit'
    end
  end

  def assign_batch
    authorize! :update, @project
    batch = params[:assign_batch][:batch].strip
    @project.items.where(id: params[:assign_batch][:assign]).find_each do |item|
      item.batch = batch
      item.save!
    end
    redirect_to @project
  end

  def show
    @items = @project.items
    @batch = params[:batch]
    @items = @items.where(batch: @batch) if @batch.present?
    respond_to do |format|
      format.html
      format.csv { send_data items_to_csv(@items), type: 'text/csv', filename: 'items.csv' }
    end
  end

  def destroy
    authorize! :destroy, @project
    if @project.destroy
      redirect_to projects_path
    else
      redirect_to :back, alert: 'Unknown error deleting project'
    end
  end

  def attachments
    @attachable = @project
  end

  protected

  def find_project
    @project = Project.find(params[:id])
  end

  def allowed_params
    params[:project].permit(:title, :manager_email, :owner_email, :start_date,
                            :status, :specifications, :summary, :collection_id, :external_id)
  end

end