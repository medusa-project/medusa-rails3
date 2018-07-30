class StorageManager

  attr_accessor :main_root, :amqp_roots, :project_staging_root, :accrual_roots, :tmpdir

  def initialize
    initialize_main_storage
    initialize_amqp_storage
    initialize_project_staging_storage
    initialize_accrual_storage
    initialize_tmpdir
  end

  def initialize_main_storage
    root_config = Settings.storage.main_root.to_h
    root_set = MedusaStorage::RootSet.new(Array.wrap(root_config))
    self.main_root = root_set.at(root_config[:name]) || raise('Main storage root not defined')
  end

  def initialize_amqp_storage
    amqp_config = Settings.storage.amqp.collect(&:to_h)
    self.amqp_roots = MedusaStorage::RootSet.new(amqp_config)
  end

  def initialize_project_staging_storage
    root_config = Settings.storage.project_staging.to_h
    root_set = MedusaStorage::RootSet.new(Array.wrap(root_config))
    self.project_staging_root = root_set.at(root_config[:name]) || raise('Project staging root not defined')
  end

  def initialize_accrual_storage
    accrual_config = Settings.storage.accrual.collect(&:to_h)
    self.accrual_roots = MedusaStorage::RootSet.new(accrual_config)
  end

  def amqp_root_at(name)
    amqp_roots.at(name)
  end

  def initialize_tmpdir
    self.tmpdir = Settings.storage.tmpdir.if_blank(ENV['TMPDIR'])
  end

end