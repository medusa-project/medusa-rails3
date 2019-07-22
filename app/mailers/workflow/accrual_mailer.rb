class Workflow::AccrualMailer < MedusaBaseMailer
  default from: "medusa-noreply@#{self.smtp_settings['domain'].if_blank('library.illinois.edu')}"

  def done(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: standard_to_list(workflow_accrual))
  end

  def initial_approval(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: standard_to_list(workflow_accrual))
  end

  def illegal_overwrite(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: standard_to_list(workflow_accrual))
  end

  def aborted(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: standard_to_list(workflow_accrual))
  end

  def notify_admin_of_incoming_request(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: self.admin_address)
  end

  def assessment_done(workflow_accrual)
    @workflow_accrual = workflow_accrual
    mail(to: standard_to_list(workflow_accrual, add_collection_contact: true))
  end

  protected

  def standard_to_list(workflow_accrual, add_collection_contact: false)
    to_list = [workflow_accrual.user.email]
    to_list << workflow_accrual.collection&.contact&.email if add_collection_contact
    to_list
  end

end