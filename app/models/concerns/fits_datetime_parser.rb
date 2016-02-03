require 'active_support/concern'

module FitsDatetimeParser
  extend ActiveSupport::Concern

  module_function

  def parse_datetime(datetime_string, toolname)
    case toolname
      when 'Exiftool'
        parse_datetime_exiftool(datetime_string)
      when 'Tika'
        parse_datetime_tika(datetime_string)
      when 'NLNZ Metadata Extractor'
        parse_datetime_nlnz(datetime_string)
      else
        raise RuntimeError, "Unrecognized FITS tool: #{toolname} reporting datetime #{datetime_string}"
    end
  end

  def parse_datetime_exiftool(datetime_string)
    case datetime_string
      when /^-+$/, '0', /CPY/
        nil
      when %r[^\d{1,2}/\d{1,2}/\d{2}$]
        Time.strptime(datetime_string, '%m/%d/%y')
      when %r[^\d{1,2}/\d{1,2}/\d{4}$]
        Time.strptime(datetime_string, '%m/%d/%Y')
      when %r[^\d{1,2}/\d{1,2}/\d{4}(\s+)\d{1,2}:\d{2}:\d{2}$]
        Time.strptime(datetime_string, "%m/%d/%Y#{$1}%H:%M:%S")
      when %r[^\d{1,2}/\d{1,2}/\d{2} \d{1,2}:\d{2} (A|P)M$]
        Time.strptime(datetime_string, '%m/%d/%y %I:%M %p')
      when %r[^\d{1,2}/\d{1,2}/\d{2}, \d{1,2}:\d{2} (A|P)M$]
        Time.strptime(datetime_string, '%m/%d/%y, %I:%M %p')
      when %r[^\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}\.\d+(\+|-)\d{2}:\d{2}$]
        Time.strptime(datetime_string, '%Y:%m:%d %H:%M:%S.%L%:z')
      when %r[^\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}(\+|-)\d{2}:\d{2}$]
        Time.strptime(datetime_string, '%Y:%m:%d %H:%M:%S%:z')
      when %r[^\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}Z?$]
        Time.strptime(datetime_string, "%Y:%m:%d %H:%M:%S")
      when %r[^D:(\d+)Z?]
        Time.strptime($1, '%Y%m%d%H%M%S')
      when %r[^D:(\d+)(\+|-)(\d+)'(\d+)'$]
        Time.strptime("#{$1}#{$2}#{$3}#{$4}", '%Y%m%d%H%M%S%z')
      when %r|^[[:alpha:]]+ [[:alpha:]]+ \d{1,2} \d{4} \d{2}:\d{2}:\d{2}$|
        Time.strptime(datetime_string, '%a %b %d %Y %H:%M:%S')
      when %r<^[[:alpha:]]+, [[:alpha:]]+ \d{2}, \d{4} \d{1,2}:\d{2}:\d{2} (A|P)M$>
        Time.strptime(datetime_string, '%A, %B %d, %Y %I:%M:%S %p')
      when %r|^[[:alpha:]]+ [[:alpha:]]+ \d{1,2} \d{1,2}:\d{2}:\d{2} \d{4}$|
        Time.strptime(datetime_string, '%a %b %d %H:%M:%S %Y')
      when %r<^\d{1,2}:\d{2} (A|P)M [[:alpha:]]+, [[:alpha:]]+ \d{1,2}, \d{4}>
        Time.strptime(datetime_string, '%H:%M %p %A, %B %d, %Y')
      else
        raise RuntimeError
    end
  rescue Exception => e
    message = "Unable to parse Exiftool date time: #{datetime_string}"
    Rails.logger.error message
    raise RuntimeError, message
  end

  def parse_datetime_tika(datetime_string)
    Time.parse(datetime_string)
  rescue Exception => e
    message = "Unable to parse Tika date time: #{datetime_string}"
    Rails.logger.error message
    raise RuntimeError, message
  end

  def parse_datetime_nlnz(datetime_string)
    case datetime_string
      when /^\d{4}-/
        Time.parse(datetime_string)
      when /^\d{4}:/
        Time.strptime(datetime_string, '%Y:%m:%d %H:%M:%S')
      else
        raise RuntimeError
    end
  rescue Exception => e
    message = "Unable to parse NLNZ date time: #{datetime_string}"
    Rails.logger.error message
    raise RuntimeError, message
  end

end