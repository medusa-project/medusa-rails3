require 'find'
require 'open3'
require 'render_anywhere'
require 'set'

class Workflow::AccrualJob < Workflow::Base
  include RenderAnywhere

  attr_accessor :comment

  belongs_to :cfs_directory
  belongs_to :user
  belongs_to :amazon_backup

  has_many :workflow_accrual_directories, class_name: 'Workflow::AccrualDirectory', dependent: :delete_all, foreign_key: 'workflow_accrual_job_id'
  has_many :workflow_accrual_files, class_name: 'Workflow::AccrualFile', dependent: :delete_all, foreign_key: 'workflow_accrual_job_id'
  has_many :workflow_accrual_conflicts, class_name: 'Workflow::AccrualConflict', dependent: :delete_all, foreign_key: 'workflow_accrual_job_id'
  has_many :workflow_accrual_comments, -> {order 'created_at desc'}, class_name: 'Workflow::AccrualComment', dependent: :delete_all, foreign_key: 'workflow_accrual_job_id'
  has_many :workflow_accrual_keys, :class_name => 'Workflow::AccrualKey', dependent: :delete_all, foreign_key: 'workflow_accrual_job_id'

  delegate :file_group, :root_cfs_directory, :collection, :repository, to: :cfs_directory

  validates_presence_of :cfs_directory_id, :user_id
  validates_uniqueness_of :staging_path, scope: :cfs_directory_id

  STATE_HASH = {'start' => 'Start', 'check' => 'Checking for existing files', 'check_sync' => 'Checking sync',
                'initial_approval' => 'Awaiting approval',
                'copying' => 'Copying', 'admin_approval' => 'Awaiting admin approval',
                'amazon_backup' => 'Amazon backup', 'amazon_backup_completed' => 'Amazon backup completed',
                'assessing' => 'Starting Assessments', 'await_assessment' => 'Running Assessment',
                'email_done' => 'Emailing completion',
                'aborting' => 'Aborting', 'end' => 'Ending'}
  STATES = STATE_HASH.keys

  def self.create_for(user, cfs_directory, staging_path, requested_files, requested_directories, allow_overwrite)
    transaction do
      workflow = self.create!(cfs_directory: cfs_directory, user: user, staging_path: staging_path, state: 'start', allow_overwrite: allow_overwrite)
      workflow.create_accrual_requests(requested_files, requested_directories)
      workflow.put_in_queue
    end
  end

  def self.awaiting_admin
    where(state: 'admin_approval')
  end

  def create_accrual_requests(requested_files, requested_directories)
    requested_files.each do |file|
      Workflow::AccrualFile.create!(name: file, workflow_accrual_job: self) unless excluded_file?(file)
    end
    requested_directories.each do |directory|
      Workflow::AccrualDirectory.create!(name: directory, workflow_accrual_job: self)
    end
  end

  def staging_root_and_prefix
    #The form of staging_path is /root_name/pre/fix/. Note that splitting gives this blank entry
    # for the leading '/', but not the trailing one.
    path_components = staging_path.split('/').drop(1)
    staging_root_name = path_components.shift
    staging_root = accrual_root(staging_root_name)
    prefix = path_components.join('/')
    return staging_root, prefix
  end

  def accrual_root(name)
    Application.storage_manager.accrual_roots.at(name)
  end

  def perform_start
    be_in_state_and_requeue('check_sync')
  end

  #TODO: I'm going to assume for now that we are going to get rid of this step by having a
  # saner way to stage the content. If not we can revisit this stuff later. For now just
  # assume there is no sync and we're dealing directly with the staged content as the user
  # did it.
  def perform_check_sync
    be_in_state_and_requeue('check')
#     comparators = (workflow_accrual_directories + workflow_accrual_files).collect {|obj| obj.comparator.analyze}
#     if comparators.all? {|comparator| comparator.objects_equal?}
#       be_in_state_and_requeue('check')
#     else
#       tmpfile = File.join(Dir.tmpdir, "check_sync-#{self.id}-#{Time.now}")
#       File.open(tmpfile, 'wb') do |f|
#         f.puts 'Source only:'
#         comparators.each {|comparator| comparator.augmented_source_only_paths.each {|p| f.puts p}}
#         f.puts 'Target only:'
#         comparators.each {|comparator| comparator.augmented_target_only_paths.each {|p| f.puts p}}
#         f.puts 'Differences:'
#         comparators.each {|comparator| comparator.augmented_different_sizes_paths.each {|p| f.puts p}}
#         f.puts 'Suggested remediation:'
#         comparators.each do |comparator|
#           comparator.augmented_target_only_paths.each do |p|
#             puts Shellwords.escape("rm -f #{File.join(staging_remote_path, p)}")
#           end
#         end
#         comparators.each do |comparator|
#           (comparator.augmented_source_only_paths + comparator.augmented_different_sizes_paths).each do |p|
#             puts Shellwords.escape("cp -f #{File.join(staging_local_path, p)} #{File.join(staging_remote_path, p)}")
#           end
#         end
#       end
#       GenericErrorMailer.error("Check sync failed for accrual_job: #{self.id}.\n See #{tmpfile} for details.",
#                                subject: 'Accrual Check Sync Error').deliver_now
#       raise RuntimeError,
#             %Q(storage.library and condo copies of accrual directory are not in sync.
# #{comparators.collect {|comparator| comparator.source_only_paths.count}.sum} files are only present in the source copy
# #{comparators.collect {|comparator| comparator.target_only_paths.count}.sum} files are only present in the target copy
# #{comparators.collect {|comparator| comparator.different_sizes_paths.count}.sum} files are present in both copies but with different sizes
# Paths are stored for inspection in #{tmpfile} on the server.
# )
#     end
  end

  #TODO See if we can't break this down a bit. It might do to have a class that does this work.
  def perform_check
    root, prefix = staging_root_and_prefix
    ingest_keys = Set.new
    empty_files = StringIO.new
    workflow_accrual_files.each do |file|
      key = file.name
      ingest_keys << key
      file.size = root.size(File.join(prefix, key))
      file.save!
      empty_files.puts(key) if file.size.zero?
    end
    workflow_accrual_directories.each do |directory|
      #get the keys in this directory relative to the accrual prefix
      keys = root.unprefixed_subtree_keys(File.join(prefix, directory.name)).collect do |unprefixed_key|
        File.join(directory.name, unprefixed_key)
      end
      size = 0
      keys.each do |key|
        key_size = root.size(File.join(prefix, key))
        size += key_size
        empty_files.puts(key) if key_size.zero?
      end
      directory.size = size
      directory.count = keys.count
      directory.save!
      ingest_keys << keys
    end
    update_attribute(:empty_file_report, empty_files.string)
    cfs_directory_prefix = cfs_directory.relative_path
    existing_keys = Application.storage_manager.main_root.unprefixed_subtree_keys(cfs_directory_prefix)
    duplicate_keys = ingest_keys.intersection(existing_keys)
    duplicate_keys.each do |key|
      existing_md5 = Application.storage_manager.main_root.md5_sum(File.join(cfs_directory_prefix, key))
      ingest_md5 = root.md5_sum(File.join(prefix, key))
      file_changed = existing_md5 == ingest_md5
      workflow_accrual_conflicts.create!(path: key, different: file_changed)
    end
    if has_serious_conflicts? and (not allow_overwrite)
      Workflow::AccrualMailer.illegal_overwrite(self).deliver_now
      be_in_state_and_requeue('end')
    else
      create_workflow_accrual_keys(keys)
      be_in_state('initial_approval')
      Workflow::AccrualMailer.initial_approval(self).deliver_now
    end
  end

  def create_workflow_accrual_keys(keys)
    workflow_accrual_keys.clear
    keys.each do |key|
      workflow_accrual_keys.create(key: key) unless excluded_file?(File.basename(key))
    end
  end

  # def perform_check
  #   add_stats
  #   source_path = staging_local_path
  #   duplicate_files(source_path).each do |duplicate_file|
  #     file_changed = file_changed?(duplicate_file, source_path)
  #     workflow_accrual_conflicts.create!(path: duplicate_file, different: file_changed)
  #   end
  #   if has_serious_conflicts? and (not allow_overwrite)
  #     Workflow::AccrualMailer.illegal_overwrite(self).deliver_now
  #     be_in_state_and_requeue('end')
  #   else
  #     be_in_state('initial_approval')
  #     Workflow::AccrualMailer.initial_approval(self).deliver_now
  #   end
  # end
  #
  # def add_stats
  #   source_path = staging_local_path
  #   empty_files = StringIO.new
  #   workflow_accrual_files.each do |file|
  #     file_path = File.join(source_path, file.name)
  #     file.size = File.size(file_path)
  #     file.save!
  #     empty_files.puts(file.name) if file.size.zero?
  #   end
  #   workflow_accrual_directories.each do |directory|
  #     directory_path = File.join(source_path, directory.name)
  #     Dir.chdir(directory_path) do
  #       count = 0
  #       size = 0
  #       Find.find('.') do |entry|
  #         next if File.directory?(entry)
  #         count += 1
  #         file_size = File.size(entry)
  #         size += file_size
  #         empty_files.puts(File.join(directory.name, entry.gsub(/^\.\//, ''))) if file_size.zero?
  #       end
  #       directory.count = count
  #       directory.size = size
  #       directory.save!
  #     end
  #   end
  #   update_attribute(:empty_file_report, empty_files.string)
  # end

  # def duplicate_files(source_path)
  #   existing_files.intersection(requested_files(source_path))
  # end
  #
  # def requested_files(source_path)
  #   Set.new.tap do |files|
  #     self.workflow_accrual_files.each {|file| files << file.name}
  #     Dir.chdir(source_path) do
  #       self.workflow_accrual_directories.each do |directory|
  #         Find.find(directory.name) do |entry|
  #           files << entry if File.file?(entry)
  #         end
  #       end
  #     end
  #   end
  # end
  #
  # def existing_files
  #   Set.new.tap do |files|
  #     Dir.chdir(cfs_directory.absolute_path) do
  #       Find.find('.') do |entry|
  #         files << entry.sub(/\.\//, '') if File.file?(entry)
  #       end
  #     end
  #   end
  # end

  # def file_changed?(file, source_path)
  #   #if the initial assessment hasn't been done yet this can error out, i.e. if the db and file system views of the
  #   #existing content are different
  #   old_md5 = cfs_directory.find_file_at_relative_path(file).md5_sum
  #   new_md5 = Digest::MD5.file(File.join(source_path, file)).to_s
  #   old_md5 != new_md5
  # end

  def perform_initial_approval
    unrunnable_state
  end

  def perform_admin_approval
    unrunnable_state
  end

  def internal_perform_copying(overwrite: false)
    source_path = staging_local_path
    target_path = cfs_directory.absolute_path
    copy_entries_and_remove(workflow_accrual_files, source_path, target_path, overwrite: overwrite)
    copy_entries_and_remove(workflow_accrual_directories, source_path, target_path, overwrite: overwrite)
    be_in_state_and_requeue('assessing')
  end

  def perform_copying
    if has_serious_conflicts?
      internal_perform_copying(overwrite: true)
      reset_conflict_fixities_and_fits
    else
      internal_perform_copying(overwrite: false)
    end
    cfs_directory.events.create!(key: 'deposit_completed', cascadable: true,
                                 note: "Accrual from #{staging_path}", actor_email: user.email)
  end

  def reset_conflict_fixities_and_fits
    workflow_accrual_conflicts.where(different: true).find_each {|conflict| conflict.reset_cfs_file}
  end

  #note that this means remove the db model from the accrual job, not the files from the source filesystem
  def copy_entries_and_remove(entries, source_path, target_path, overwrite: false)
    entries.each do |entry|
      copy_entry(entry, source_path, target_path, overwrite: overwrite)
      entry.destroy!
    end
  end

  def copy_entry(entry, source_path, target_path, overwrite: false)
    opts = %w(-a --ignore-times --safe-links --chmod Du+rwx,Dgo+rw,Dgo-w,Fu+rw,Fu-x,Fgo+r,Fgo-wx --exclude-from) << exclude_file_path
    opts << '--ignore-existing' unless overwrite
    source_entry = File.join(source_path, entry.name)
    return unless File.exists?(source_entry)
    out, err, status = Open3.capture3('rsync', *opts, source_entry, target_path)
    unless status.success?
      message = <<MESSAGE
Error doing rsync for accrual job #{self.id} for #{entry.class} #{entry.name}.
STDOUT: #{out}
STDERR: #{err}
Rescheduling.
MESSAGE
      Rails.logger.error message
      raise RuntimeError, message
    end
  end

  def exclude_file_path
    File.join(Rails.root, 'config', 'accrual_rsync_exclude.txt')
  end

  def excluded_file?(file)
    %w(Thumbs.db .DS_Store).include?(file)
  end

  #We have to be a little careful here, as we want to make sure the backup happens, but at the same time it may
  #be the case that there is already a backup scheduled or ongoing, and in light of the fact that we only allow a single
  #backup per file group / date pair we may need to latch on to an existing backup or schedule a backup in the future.
  #How we proceed: If there is already a backup scheduled for after today then make that the amazon backup for this, but
  #don't create another job to run it. If not and there is a job scheduled for today then make a job for tomorrow and
  #run it. If not then make a job for today and run it. Let errors propagate.
  #In addition to this we need to make the association to AmazonBackup one to many and the message receiving method
  #must reflect that.
  def perform_amazon_backup
    #TODO this return doesn't get us out of this state - may need to do
    #something else instead. If the file group isn't present what does that
    #mean?
    return if file_group.blank?
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

  def perform_aborting
    Workflow::AccrualMailer.aborted(self).deliver_now
    archive('aborted')
    be_in_state_and_requeue('end')
  end

  def perform_amazon_backup_completed
    be_in_state_and_requeue('email_done')
  end

  def perform_assessing
    cfs_directory.make_and_assess_tree
    be_in_state_and_requeue('await_assessment')
  end

  def perform_await_assessment
    wait_time = Rails.env.test? ? (0.1).seconds : 5.minutes
    if has_pending_assessments?
      if self.created_at + 2.days > Time.now
        self.put_in_queue(run_at: Time.now + wait_time)
      else
        raise RuntimeError, "Assessments are still pending. Accrual Job: #{self.id}. Cfs Directory: #{self.cfs_directory.id}"
      end
    else
      Workflow::AccrualMailer.assessment_done(self).deliver_now
      be_in_state_and_requeue('amazon_backup')
    end
  end

  #Are there any initial directory assessments belonging to a subdirectory of this accrual jobs cfs directory?
  def has_pending_assessments?
    transaction do
      subdirectory_ids = self.cfs_directory.recursive_subdirectory_ids.to_set
      possible_assessment_job_ids = Job::CfsInitialDirectoryAssessment.where(file_group_id: self.cfs_directory.file_group.id).pluck(:cfs_directory_id).to_set
      return subdirectory_ids.intersect?(possible_assessment_job_ids)
    end
  end

  def perform_email_done
    Workflow::AccrualMailer.done(self).deliver_now
    archive('completed')
    be_in_state_and_requeue('end')
    #TODO - perhaps delete staged content, perhaps not
  end

  def status_label
    STATE_HASH[self.state]
  end

  def approve_and_proceed
    case state
    when 'initial_approval'
      be_in_state('admin_approval')
      notify_admin_of_request
    when 'admin_approval'
      be_in_state_and_requeue('copying')
    else
      raise RuntimeError, 'Job approved from unallowed initial state'
    end
  end

  def archive(completion_state)
    ArchivedAccrualJob.create!(workflow_accrual_job_id: self.id, file_group_id: file_group.id, cfs_directory_id: cfs_directory_id,
                               amazon_backup_id: amazon_backup_id, user_id: user_id, state: completion_state, staging_path: staging_path, report: render_report)
  end

  def abort_and_proceed
    be_in_state_and_requeue('aborting')
  end

  def has_conflicts?
    workflow_accrual_conflicts.count > 0
  end

  def has_serious_conflicts?
    workflow_accrual_conflicts.serious.count > 0
  end

  def notify_admin_of_request
    Workflow::AccrualMailer.notify_admin_of_incoming_request(self).deliver_now
  end

  def has_report?
    !self.state.in?(%w(start check))
  end

  def file_group
    cfs_directory.file_group
  end

  def file_group_title
    file_group.try(:title) rescue '[UNKNOWN]'
  end

  def relative_target_path
    cfs_directory.relative_path
  end

  def directory_count
    workflow_accrual_directories.count
  end

  def top_level_file_count
    workflow_accrual_files.count
  end

  def total_file_count
    top_level_file_count + workflow_accrual_directories.sum(:count)
  end

  def size
    workflow_accrual_directories.sum(:size) + workflow_accrual_files.sum(:size)
  end

  class RenderingController < RenderAnywhere::RenderingController
    attr_accessor :workflow_accrual
  end

  def render_report
    set_instance_variable('workflow_accrual', self)
    render partial: 'workflow/accrual_mailer/view_report'
  end

end
