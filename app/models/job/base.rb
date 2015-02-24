class Job::Base < ActiveRecord::Base

  self.abstract_class = true

  def destroy_queued_jobs_and_self
    self.delayed_jobs.each do |job|
      job.destroy
    end
    self.destroy
  end

  def delayed_jobs
    Delayed::Job.where("handler LIKE ?", self.delayed_job_handler_prefix + '%').all
  end

  #The way delayed job currently stores the handler we have to look it up with just the prefix
  #of the YAML representation. Note that this is different than just calling .to_yaml on the handler.
  def delayed_job_handler_prefix
    "--- !ruby/ActiveRecord:#{self.class}\nattributes:\n  id: #{self.id}\n"
  end

  def success(job)
    self.destroy!
  end

  def error(job, exception)
    notify_on_error(job, exception)
  end

  def failure(job)
    notify_on_error(job, nil)
  end

  def notify_on_error(job, exception = nil)
    DelayedJobErrorMailer.error(job, exception).deliver if job.attempts >= 5
  end

end