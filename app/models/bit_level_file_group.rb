require 'fileutils'
require 'set'
class BitLevelFileGroup < FileGroup
  include RedFlagAggregator

  has_many :virus_scans, dependent: :destroy, foreign_key: :file_group_id

  aggregates_red_flags self: :cfs_red_flags, label_method: :title

  has_many :job_fits_directories, class_name: 'Job::FitsDirectory', foreign_key: :file_group_id
  has_many :job_cfs_initial_directory_assessments, class_name: 'Job::CfsInitialDirectoryAssessment', foreign_key: :file_group_id

  after_create :ensure_cfs_directory
  after_destroy :maybe_destroy_cfs_directories
  before_destroy :check_emptiness

  delegate :pristine?, :ensure_file_at_absolute_path, :ensure_file_at_relative_path,
           :find_directory_at_relative_path, :find_file_at_relative_path, to: :cfs_directory

  def ensure_cfs_directory
    physical_cfs_directory_path = expected_absolute_cfs_root_directory
    FileUtils.mkdir_p(physical_cfs_directory_path) unless Dir.exists?(physical_cfs_directory_path)
    if cfs_directory = CfsDirectory.find_by(path: expected_relative_cfs_root_directory)
      self.cfs_directory_id = cfs_directory.id unless self.cfs_directory_id
      self.save!
    else
      cfs_directory = CfsDirectory.create!(path: expected_relative_cfs_root_directory, skip_assessment: true)
      self.cfs_directory_id = cfs_directory.id unless self.cfs_directory_id
      self.save!
    end
  end

  #Destroy the physical cfs directory and/or CfsDirectory corresponding to this
  #ONLY IF they are empty
  def maybe_destroy_cfs_directories
    physical_cfs_directory_path = expected_absolute_cfs_root_directory
    if Dir.entries(physical_cfs_directory_path).to_set == %w(. ..).to_set
      Dir.unlink(physical_cfs_directory_path) rescue nil
    end
    if cfs_directory.try(:is_empty?)
      cfs_directory.destroy
    end
  end

  def storage_level
    'bit-level store'
  end

  def self.downstream_types
    ['ObjectLevelFileGroup']
  end

  def supports_cfs
    true
  end

  def full_cfs_directory_path
    raise RuntimeError, "No cfs directory set for file group #{self.id}" unless self.cfs_directory.present?
    File.join(CfsRoot.instance.path, self.cfs_directory.path)
  end

  def expected_absolute_cfs_root_directory
    File.join(CfsRoot.instance.path, self.expected_relative_cfs_root_directory)
  end

  def expected_relative_cfs_root_directory
    File.join(self.collection_id.to_s, self.id.to_s)
  end

  def schedule_initial_cfs_assessment
    Job::CfsInitialFileGroupAssessment.create_for(self)
  end

  def run_initial_cfs_assessment
    self.cfs_directory.make_initial_tree
    self.cfs_directory.schedule_initial_assessments
  end

  def running_fits_file_count
    Job::FitsDirectory.where(file_group_id: self.id).sum(:file_count)
  end

  def running_initial_assessments_file_count
    Job::CfsInitialDirectoryAssessment.where(file_group_id: self.id).sum(:file_count)
  end

  def cfs_red_flags
    return [] unless self.cfs_directory
    RedFlag.where(red_flaggable_type: 'CfsFile').
        joins('JOIN cfs_files ON red_flags.red_flaggable_id = cfs_files.id').
        where(cfs_files: {cfs_directory_id: self.cfs_directory.recursive_subdirectory_ids})
  end

  def file_size
    return total_file_size
  end

  def file_count
    return total_files
  end

  def amazon_backups
    if self.cfs_directory.present?
      self.cfs_directory.amazon_backups
    else
      []
    end
  end

  def last_amazon_backup
    self.amazon_backups.first
  end

  def is_currently_assessable?
    !(Job::CfsInitialFileGroupAssessment.find_by(file_group_id: self.id) or
        Job::CfsInitialDirectoryAssessment.find_by(file_group_id: self.id))
  end

  def cfs_directory_id
    cfs_directory.try(:id)
  end

  def cfs_directory_id=(cfs_directory_id)
    old_cfs_directory = self.cfs_directory
    new_cfs_directory = (CfsDirectory.find(cfs_directory_id) rescue nil)
    #just return if there is no change
    return if new_cfs_directory.blank? and old_cfs_directory.blank?
    return if old_cfs_directory == new_cfs_directory
    transaction do
      if old_cfs_directory
        old_cfs_directory.parent = nil
        old_cfs_directory.save!
      end
      if new_cfs_directory
        new_cfs_directory.parent = self
        new_cfs_directory.save!
      end
    end
    self.cfs_directory(true)
  end

  def accrual_unstarted?
    events.where(key: 'files_added').blank? and
    (cfs_directory.blank? or cfs_directory.pristine?)
  end

  def check_emptiness
    unless self.pristine?
      errors.add(:base, 'This file group has content and cannot be deleted. Please contact Medusa administrators to have it removed.')
      return false
    end
    return true
  end

  def self.aggregate_size
    self.sum('total_file_size')
  end

end