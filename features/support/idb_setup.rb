require 'fileutils'

module IdbTestHelper
  module_function

  def idb_ingest_message
    {'operation' => 'ingest', 'staging_path' => 'prefix/test_dir/file.txt'}
  end

  def idb_delete_message
    {'operation' => 'delete', 'uuid' => 'c3712760-1183-0134-1d5b-0050569601ca-b'}
  end

  def staging_path
    idb_ingest_message['staging_path']
  end

  def stage_content
    stage_content_to(staging_path, 'Staging text')
  end

  def stage_content_to(key, content_string)
    md5_sum = Digest::MD5.base64digest(content_string)
    storage_root = Application.storage_manager.amqp_root_at('idb')
    storage_root.copy_io_to(key, StringIO.new(content_string), md5_sum, content_string.length)
  end

end

Before('@idb') do
  #clear idb staging directories - test should set these up as desired
  Application.storage_manager.amqp_root_at('idb').delete_all_content
end

Around('@idb-no-deletions') do |scenario, block|
  old_value = AmqpAccrual::Config.allow_delete('idb')
  AmqpAccrual::Config.set_allow_delete('idb', false)
  block.call
  AmqpAccrual::Config.set_allow_delete('idb', old_value)
end
