require 'rake'
require 'fileutils'
require 'csv'

namespace :fixity do

  DEFAULT_BATCH_SIZE = 100000
  SUB_BATCH_LIMIT = 100
  FIXITY_STOP_FILE = File.join(Rails.root, 'fixity_stop.txt')
  desc "Run fixity on a number of files. BATCH_SIZE sets number (default #{DEFAULT_BATCH_SIZE})"
  task run_batch: :environment do
    batch_size = (ENV['BATCH_SIZE'] || DEFAULT_BATCH_SIZE).to_i
    errors = Hash.new
    bar = ProgressBar.new(batch_size)
    sub_batch_size = [batch_size, SUB_BATCH_LIMIT].min
    batch_size -= sub_batch_size
    while sub_batch_size > 0
      fixity_files(sub_batch_size).each do |cfs_file|
        break if File.exist?(FIXITY_STOP_FILE)
        begin
          cfs_file.update_fixity_status_with_event
          unless cfs_file.fixity_check_status == 'ok'
            puts "#{cfs_file.id}: #{cfs_file.fixity_check_status}"
            case cfs_file.fixity_check_status
              when 'bad'
                errors[cfs_file] = 'Bad fixity'
              when 'nf'
                errors[cfs_file] = 'Not found'
              else
                raise RuntimeError, 'Unrecognized fixity check status'
            end
          end
          bar.increment!
        rescue RSolr::Error::Http => e
          errors[cfs_file] = e.to_s
          FileUtils.touch(FIXITY_STOP_FILE)
        rescue Exception => e
          errors[cfs_file] = e.to_s
          if errors.length > 25
            FileUtils.touch(FIXITY_STOP_FILE)
          end
        ensure
          Sunspot.commit
          sub_batch_size = [batch_size, SUB_BATCH_LIMIT].min
          batch_size -= sub_batch_size
        end
      end
    end
    if errors.present?
      error_string = StringIO.new
      error_string.puts "Fixity errors"
      errors.each do |k, v|
        error_string.puts "#{k.id}: #{v}"
      end
      GenericErrorMailer.error(error_string.string, subject: 'Fixity batch error').deliver_now
    end
  end

  desc "Email about any bad fixity reports"
  task report_problems: :environment do
    if CfsFile.not_found_fixity.count > 0 or CfsFile.bad_fixity.count > 0
      FixityErrorMailer.report_problems.deliver_now
    end
  end

  desc "Make CSV report about bad/missing fixity files"
  task csv_report: :environment do
    f = File.open('fixity_report.csv', 'wb')
    csv = CSV.new(f)
    csv << %w(cfs_file_id status cfs_directory_id file_group_id path)
    problem_files = CfsFile.not_found_fixity.to_a + CfsFile.bad_fixity.to_a
    problem_files.each do |f|
      csv << [f.id, f.fixity_check_status, f.cfs_directory_id, f.file_group.id, f.absolute_path]
    end
    f.close
    # File.open('fixity_report.csv', 'wb') do |f|
    #   CSV.new(f) do |csv|
    #     csv << %w(cfs_file_id status cfs_directory_id file_group_id path)
    #     problem_files = CfsFile.not_found_fixity.to_a + CfsFile.bad_fixity.to_a
    #     problem_files.each do |f|
    #       csv << [f.id, f.fixity_check_status, f.cfs_directory_id, f.file_group.id, f.absolute_path]
    #     end
    #   end
    # end
  end
end

def fixity_files(batch_size)
  if CfsFile.where(fixity_check_status: nil).where('size is not null').first
    CfsFile.where(fixity_check_status: nil).where('size is not null').limit(batch_size)
  else
    timeout = (Settings.medusa.fixity_interval || 90).days
    CfsFile.where('fixity_check_time < ?', Time.now - timeout).order('fixity_check_time asc').limit(batch_size)
  end
end


