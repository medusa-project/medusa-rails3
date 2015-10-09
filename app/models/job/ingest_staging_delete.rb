require 'fileutils'

class Job::IngestStagingDelete < Job::Base

  belongs_to :user
  belongs_to :external_file_group

  def self.create_for(external_file_group, user)
    path = external_file_group.local_staged_file_location
    #check to make sure that this is a legitimate path for this file group
    unless path and path.match(/#{external_file_group.collection_id}\/#{external_file_group.id}$/)
      raise RuntimeError, 'Can''t schedule delete for staging ingest - path is invalid.'
    end
    job = self.create!(external_file_group_id: external_file_group.id, path: path, user_id: user.id)
    options = {priority: 10}
    options[:run_at] = Time.now + (Rails.env.production? ? 30.days : 2.seconds)
    Delayed::Job.enqueue(job, options)
  end

  def perform
    if File.directory?(self.path)
      if File.writable?(self.path)
        FileUtils.rm_rf(self.path)
      else
        raise RuntimeError, "IngestStagingDelete: Medusa does not have permission to delete #{self.path}."
      end
    end
    if self.external_file_group.present?
      Workflow::IngestMailer.staging_delete_done(self.user, self.external_file_group).deliver_now
    end
  end

end