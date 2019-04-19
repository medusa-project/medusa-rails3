class ReportMailer < MedusaBaseMailer

  def cfs_directory_map(job, report_io)
    @job = job
    subject("Medusa Report Map for #{job.cfs_directory.relative_path}")
    attachments['report.txt'] = report_io.string
    message = mail(to: job.user.email)
    message.parts.reverse!
  end

  def cfs_directory_manifest(job, report_io)
    @job = job
    subject("Medusa Report Manifest for #{job.cfs_directory.relative_path}")
    attachments['report.tsv'] = report_io.string
    mail(to: job.user.email)
  end

end