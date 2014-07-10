class Job::AmazonBackup < Job::Base

  belongs_to :amazon_backup

  #We should only be able to have one of these at a time for a given backup
  validates_uniqueness_of :amazon_backup_id

  def self.create_for(amazon_backup)
    Delayed::Job.enqueue(self.create(amazon_backup: amazon_backup), :queue => 'glacier')
  end

  def perform
    self.amazon_backup.request_backup
  end

end