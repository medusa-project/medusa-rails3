class Workflow::ProjectItemIngest < Workflow::Base

  belongs_to :user
  belongs_to :project
  belongs_to :amazon_backup
  has_many :workflow_item_ingest_requests, :class_name => 'Workflow::ItemIngestRequest', dependent: :destroy, foreign_key: :workflow_project_item_ingest_id
  has_many :items, through: :workflow_item_ingest_requests

  STATES = %w(start email_started ingest email_progress amazon_backup amazon_backup_completed email_done email_staging_directory_missing email_target_directory_missing end)

  validates_inclusion_of :state, in: STATES, allow_blank: false

  def perform_start
    be_in_state_and_requeue('email_started')
  end

  def perform_email_started
    Workflow::ProjectItemIngestMailer.started(self).deliver_now
    be_in_state_and_requeue('ingest')
  end

  def perform_email_progress
    Workflow::ProjectItemIngestMailer.progress(self).deliver_now
    be_in_state_and_requeue('amazon_backup')
  end

  def perform_email_done
    Workflow::ProjectItemIngestMailer.done(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_ingest
    be_in_state_and_requeue('email_target_directory_missing') and return unless safe_target_directory.present?
    be_in_state_and_requeue('email_staging_directory_missing') and return if staging_directory_missing?
    items.each do |item|
      begin
        ingest_item(item) if !item.ingested and has_staged_content?(item)
      rescue MedusaStorage::Error::InvalidDirectory
        #just pass
      end
    end
    add_file_group_event
    be_in_state_and_requeue('email_progress')
  end

  #this is based off of the one in Workflow::AccrualJob and we might be able to unify them
  def perform_amazon_backup
    file_group = project.target_cfs_directory.file_group
    return if file_group.blank?
    root_cfs_directory = file_group.cfs_directory
    today = Date.today
    transaction do
      if future_backup = AmazonBackup.find_by(cfs_directory_id: root_cfs_directory.id, date: today + 1)
        assign_amazon_backup(future_backup, run_backup: false)
      elsif AmazonBackup.find_by(cfs_directory_id: root_cfs_directory.id, date: today)
        assign_amazon_backup(AmazonBackup.create!(user_id: self.user.id, cfs_directory_id: root_cfs_directory.id, date: today + 1),
                             run_backup: true, backup_options: {run_at: today + 1.day + 1.hour})
      else
        assign_amazon_backup(AmazonBackup.create!(user_id: self.user.id, cfs_directory_id: root_cfs_directory.id, date: today),
                             run_backup: true)
      end
    end
    #Stay in amazon_backup state - Amazon Backup will do the transition when it receives a reply from the glacier server
  end

  def assign_amazon_backup(backup, run_backup: false, backup_options: {})
    self.amazon_backup = backup
    self.save!
    Job::AmazonBackup.create_for(backup, backup_options) if run_backup
  end


  def perform_amazon_backup_completed
    be_in_state_and_requeue('email_done')
  end

  def perform_email_staging_directory_missing
    Workflow::ProjectItemIngestMailer.staging_directory_missing(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_email_target_directory_missing
    Workflow::ProjectItemIngestMailer.target_directory_missing(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_end
    destroy_queued_jobs_and_self
  end

  def staging_root
    Application.storage_manager.project_staging_root
  end

  def main_root
    Application.storage_manager.main_root
  end

  protected

  def ingest_item(item)
    copy_item(item)
    item_cfs_directory = create_and_assess_item_cfs_directory(item)
    item.cfs_directory = item_cfs_directory
    item.ingested = true
    item.save!
  end

  def copy_item(item)
    source_key_prefix = item.staging_key_prefix
    target_key_prefix = project.target_key_prefix
    item_id = File.basename(source_key_prefix)
    source_keys = staging_root.unprefixed_subtree_keys(source_key_prefix).reject {|key| file_exclusions.include?(File.basename(key))}
    source_keys.each do |source_key|
      main_root.copy_content_to(File.join(target_key_prefix, item_id, source_key),
                                staging_root,
                                File.join(source_key_prefix, source_key))
    end
  end

  #return the cfs directory corresponding to the item
  def create_and_assess_item_cfs_directory(item)
    target_cfs_directory = project.target_cfs_directory
    target_cfs_directory.subdirectories.find_or_create_by!(path: item.ingest_identifier,
                                                           root_cfs_directory: target_cfs_directory.root_cfs_directory).tap do |cfs_directory|
      cfs_directory.run_initial_assessment
    end

  end

  def exclude_file_path
    File.join(Rails.root, 'config', 'accrual_rsync_exclude.txt')
  end

  def file_exclusions
    @file_exclusions ||= (File.read(exclude_file_path).lines.collect(&:chomp) rescue [])
  end

  def safe_target_directory
    project.target_cfs_directory rescue nil
  end

  def add_file_group_event
    file_group = project.target_cfs_directory.file_group
    note = "Ingested items: #{item_ids.join(',')}"
    file_group.events.create!(key: :project_item_ingest, actor_email: user.email, cascadable: true, note: note)
  end

  def staging_directory_missing?
    staging_root.subdirectory_keys(project.staging_key_prefix).blank? and
        staging_root.file_keys(project.staging_key_prefix).blank?
  rescue MedusaStorage::Error::InvalidDirectory
    true
  end

  def has_staged_content?(item)
    directory_key = item.staging_key_prefix
    staging_root.file_keys(directory_key).present? ||
        staging_root.subdirectory_keys(directory_key).present?
  rescue Aws::S3::Errors::NotFound
    false
  end

end
