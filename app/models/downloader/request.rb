class Downloader::Request < ActiveRecord::Base

  belongs_to :cfs_directory

  STATUSES = %w(pending request_received request_completed error)
  validates :status, inclusion: STATUSES, allow_blank: false

  def self.handle_response(payload)
    response = JSON.parse(payload)
    case response['action']
      when 'request_received'
        request = Downloader::Request.find_by(id: response['client_id'])
        request.handle_request_received(response)
      when 'request_completed'
        request = Downloader::Request.find_by(downloader_id: response['id'])
        request.handle_request_completed(response)
      when 'error'
        request = Downloader::Request.find_by(downloader_id: response['id'])
        request.handle_error(response)
      else
        Rails.logger.error "Unrecognized response from downloader server: #{response}"
        raise RuntimeError, "Unrecognized response from downloader server"
    end
  end

  def self.create_for(cfs_directory, user, recursive: false)
    request = self.create!(cfs_directory: cfs_directory, email: user.email, status: 'pending')
    request.send_export_request(recursive: recursive)
  end

  def handle_request_received(response)
    self.status = 'request_received'
    self.downloader_id = response['id']
    self.save!
  end

  def handle_error(response)
    self.status = 'error'
    self.save!
    CfsMailer.export_error_user(self, response).deliver_now
    CfsMailer.export_error_admin(self, response).deliver_now
  end

  def handle_request_completed(response)
    self.status = 'request_completed'
    self.save!
    CfsMailer.export_complete(self, response).deliver_now
  end

  def send_export_request(recursive: false)
    AmqpConnector.connector(:downloader).send_message(Application.downloader_config.outgoing_queue, export_request_message(recursive: recursive))
  end

  def export_request_message(recursive: false)
    config = Application.downloader_config
    Hash.new.tap do |h|
      h[:action] = :export
      h[:client_id] = self.id.to_s
      h[:return_queue] = config.incoming_queue
      h[:root] = config.root
      h[:zip_name] = File.basename(cfs_directory.path)
      Hash.new.tap do |target|
        h[:targets] = [target]
        target[:recursive] = recursive
        target[:type] = 'directory'
        target[:path] = cfs_directory.relative_path
        target[:zip_path] = ''
      end
    end
  end

end