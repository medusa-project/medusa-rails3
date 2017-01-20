class Workflow::ProjectItemIngest < Workflow::Base

  belongs_to :user
  belongs_to :project

  STATES = %w(start email_started ingest email_done end)

  validates_inclusion_of :state, in: STATES, allow_blank: false

  def perform_email_started
    Workflow::ProjectItemIngestMailer.started(self).deliver_now
    be_in_state_and_requeue('ingest')
  end

  def perform_email_done
    Workflow::ProjectItemIngestMailer.done(self).deliver_now
    be_in_state_and_requeue('end')
  end

  def perform_end
    destroy_queued_jobs_and_self
  end

end
