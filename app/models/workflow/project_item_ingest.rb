require 'open3'
class Workflow::ProjectItemIngest < Workflow::Base

  belongs_to :user
  belongs_to :project
  has_many :workflow_item_ingest_requests, :class_name => 'Workflow::ItemIngestRequest', dependent: :destroy, foreign_key: :workflow_project_item_ingest_id
  has_many :items, through: :workflow_item_ingest_requests

  STATES = %w(start email_started ingest email_done email_staging_directory_missing email_target_directory_missing end)

  validates_inclusion_of :state, in: STATES, allow_blank: false

  def perform_start
    be_in_state_and_requeue('email_started')
  end

  def perform_email_started
    Workflow::ProjectItemIngestMailer.started(self).deliver_now
    be_in_state_and_requeue('ingest')
  end

  def perform_email_done
    Workflow::ProjectItemIngestMailer.done(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_ingest
    be_in_state_and_requeue('email_staging_directory_missing') and return unless project.ingest_folder.present? and Dir.exist?(project.staging_directory)
    be_in_state_and_requeue('email_target_directory_missing') and return unless safe_target_directory.present?
    items.each do |item|
      ingest_item(item) if !item.ingested and Dir.exist?(item.staging_directory)
    end
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

  protected

  def ingest_item(item)
    rsync_item(item)
    create_and_assess_item_cfs_directory(item)
    item.ingested = true
    item.save!
  end

  def rsync_item(item)
    opts = %w(-a --ignore-times --safe-links --chmod Dug+w --exclude-from) << exclude_file_path
    source = item.staging_directory
    target = project.target_cfs_directory_path
    out, err, status = Open3.capture3('rsync', *opts, source, target)
    unless status.success?
      message = <<MESSAGE
Error doing rsync for project item ingest job #{self.id} for item #{item.id}.
STDOUT: #{out}
STDERR: #{err}
Rescheduling.
MESSAGE
      Rails.logger.error message
      raise RuntimeError, message
    end
  end

  def create_and_assess_item_cfs_directory(item)
    target_cfs_directory = project.target_cfs_directory
    cfs_directory = target_cfs_directory.subdirectories.find_or_create_by!(path: item.ingest_identifier,
                                                                           root_cfs_directory: target_cfs_directory.root_cfs_directory)
    cfs_directory.run_initial_assessment
  end

  def exclude_file_path
    File.join(Rails.root, 'config', 'accrual_rsync_exclude.txt')
  end

  def safe_target_directory
    project.target_cfs_directory rescue nil
  end

end
