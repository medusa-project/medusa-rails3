class Job::Base < ActiveRecord::Base

  self.abstract_class = true

  def destroy_queued_jobs_and_self
    self.delayed_jobs.each do |job|
      job.destroy
    end
    self.destroy
  end

  def delayed_jobs
    Delayed::Job.where(handler: self.to_yaml).all
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