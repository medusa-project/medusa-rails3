class ExternalFileGroup < FileGroup

  before_save :nullify_cfs_directory

  def storage_level
    'external'
  end

  def self.downstream_types
    ['BitLevelFileGroup', 'ObjectLevelFileGroup']
  end

  #check that the staged_file_location is okay - it must end in collection_id/file_group_id
  #check that the staged storage has a matching root
  #check that the corresponding staged storage local directory exists
  def has_staged_directory?
    self.staged_file_location and
        StagingStorage.normalize_path(self.staged_file_location).match(/#{self.collection_id}\/#{self.id}$/) and
        StagingStorage.root_for(self.staged_file_location)
  end

  def ready_for_bit_level_ingest?
    self.has_staged_directory?
  end

end