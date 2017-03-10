require 'fileutils'
class Workflow::FileGroupDelete < Workflow::Base

  belongs_to :file_group
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User'

  before_create :cache_fields

  STATES = %w(start email_superusers wait_decision email_requester_accept email_requester_reject move_content delete_content email_requester_final_removal end)
  validates_inclusion_of :state, in: STATES, allow_blank: false

  def perform_start
    be_in_state_and_requeue('email_superusers')
  end

  def perform_email_superusers
    Workflow::FileGroupDeleteMailer.email_superusers(self).deliver_now
    be_in_state('wait_decision')
  end

  def perform_wait_decision
    unrunnable_state
  end

  def perform_email_requester_accept
    Workflow::FileGroupDeleteMailer.requester_accept(self).deliver_now
    be_in_state_and_requeue('move_content')
  end

  def perform_email_requester_reject
    Workflow::FileGroupDeleteMailer.requester_reject(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_move_content
    create_db_backup_tables
    move_physical_content
    destroy_db_objects
    be_in_state_and_requeue('delete_content')
  end

  def perform_email_requester_final_removal
    Workflow::FileGroupDeleteMailer.requester_final_removal(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_end
    destroy_queued_jobs_and_self
  end

  def approver_email
    approver.present? ? approver.email : 'Unknown'
  end

  def cache_fields
    self.cached_file_group_title ||= file_group.title
    self.cached_collection_id ||= file_group.collection_id
    self.cached_cfs_directory_id ||= file_group.cfs_directory_id
  end

  protected

  def move_physical_content
    FileUtils.mkdir_p(Settings.medusa.cfs.fg_delete_holding)
    FileUtils.move(file_group.cfs_directory.absolute_path, File.join(Settings.medusa.cfs.fg_delete_holding, file_group.id.to_s))
  end

  def destroy_db_objects
    file_group.cfs_directory.destroy_tree_from_leaves
    transaction do
      file_group.destroy!
      Event.create!(eventable: file_group.collection, key: :file_group_delete_moved, actor_email: requester.email,
                    note: "File Group #{file_group.id} - #{file_group.title} | Collection: #{file_group.collection.id}")
    end
  end

  def db_backup_schema_name
    "fg_holding_#{file_group_id}"
  end

  def db_backup_schema_exists?
    connection.table_exists? "#{db_backup_schema_name}.file_groups"
  end

  #This is the big one
  #First we check to see if we've already done this step. To do this just look for a table in the right schema,
  #e.g. db_backup_schema_name.file_groups
  #If that is not found, then create and run the SQL to do a huge transaction that will:
  #- Save file group info to db_backup_schema_name.file_groups - just select based on id
  #- Save cfs directory info to db_backup_schema_name.cfs_directories - use root cfs dir id to get all of them
  #- Save cfs file info to db_backup_schema_name.cfs_files - all that belong to the above dirs
  #- Save event info to db_backup_schema_name.events - three selects, one for each of the file group, dirs, and files
  #- Save rights declaration to db_backup_schema_name.rights_declaration - select based on file group id
  #- Save assessments to db_backup_schema_name.assessments - select based on file group id
  # these will be create table via selects except for two of the events which will be insert into table via selects
  def create_db_backup_tables
    return if db_backup_schema_exists?
    transaction do
      connection.execute(create_db_backup_tables_sql)
    end
  end

  #All we should have to do here is execute a cascaded delete of the schema
  def delete_db_backup_tables
    connection.execute("DROP SCHEMA #{db_backup_schema_name} CASCADE")
  end

  def create_db_backup_tables_sql
    cfs_directory_id = file_group.cfs_directory.id
    <<SQL
CREATE SCHEMA #{db_backup_schema_name};
CREATE TABLE #{db_backup_schema_name}.file_groups AS SELECT * FROM file_groups WHERE id=#{file_group_id};



SQL
  end

end
