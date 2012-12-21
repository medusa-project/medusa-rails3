require 'set'
require 'fileutils'
class Directory < ActiveRecord::Base
  attr_accessible :name, :collection_id
  has_many :bit_files, :dependent => :restrict, :order => 'name'
  belongs_to :collection

  acts_as_tree order: 'name'

  validates_presence_of :name, :collection_id
  validates_uniqueness_of :name, :scope => :parent_id
  #only allow one root for each collection
  validates_uniqueness_of :collection_id, :unless => :parent_id
  validates_each :collection_id, :if => :parent_id do |record, attr, value|
    unless record.collection_id == record.parent.collection_id
      record.errors.add attr, 'must be the same as parent'
    end
  end

  before_validation :set_collection_id

  def root?
    !self.parent_id
  end

  def bit_ingest(source_directory, opts = {})
    Dir.chdir(source_directory) do
      self.recursive_ingest('.', opts)
    end
  end

  def bit_export(target_directory, opts = {})
    FileUtils.mkdir_p(target_directory)
    Dir.chdir(target_directory) do
      self.recursive_export('.', opts)
    end
  end

  def recursive_delete(delete_self = true)
    self.reload
    #recursively delete subdirs
    self.children(true).each do |subdir|
      subdir.recursive_delete
    end
    self.bit_files(true).each do |bit_file|
      bit_file.full_delete
    end
    self.bit_files(true)
    self.destroy if delete_self
  end

  def recursive_export(target_directory, opts = {})
    Dir.chdir(target_directory) do
      #export any files in this directory
      self.bit_files.each do |bit_file|
        Dx.instance.export_file(bit_file, '.')
      end
      #recursively ensure child directories exist and export
      self.children.each do |subdir|
        FileUtils.mkdir_p(subdir.name)
        subdir.recursive_export(subdir.name, opts)
      end
    end
  end

  def recursive_ingest(source_directory, opts = {})
    Rails.logger.info "Bit ingesting directory #{source_directory}"
    initialize_ingest_opts(opts)
    #find all files and directories in the source directory
    sources = (Dir[File.join(source_directory, '*')] + Dir[File.join(source_directory, '.*')].reject { |f| ['.', '..'].include?(File.basename(f)) }).sort
    source_dirs = sources.select { |s| File.directory?(s) }
    source_files = sources.select { |s| File.file?(s) }
    #ingest each file in the directory
    bit_ingest_files(source_files, opts)
    #ensure subdirectories are present
    subdirs = ensure_subdirectories(source_dirs, opts)
    #recursively ingest each subdirectory
    subdirs.each { |subdir| subdir.recursive_ingest(File.join(source_directory, subdir.name), opts.merge(:path => File.join(opts[:path], subdir.name))) }
    Rails.logger.info "Bit ingest finished for directory #{source_directory}"
  end

  def initialize_ingest_opts(opts)
    opts[:path] ||= self.path_from_root
    opts[:root_id] ||= self.root.id
  end

  def bit_ingest_files(files, opts = {})
    #ensure file objects exist
    current_files = existing_file_names
    BitFile.transaction do
      files.each do |file|
        name = File.basename(file)
        unless current_files.include?(name)
          Rails.logger.info "Creating Rails file #{name}"
          bf = BitFile.new(:name => name, :directory_id => self.id)
          bf.save!
        end
      end
    end
    #ingest into dx if necessary for each one
    base_path = self.relative_path
    file_typer = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    self.bit_files(true).each do |bit_file|
      unless bit_file.dx_ingested
        file_path = base_path.blank? ? bit_file.name : File.join(base_path, bit_file.name)
        #compute file stuff as needed. Save file.
        bit_file.md5sum = Digest::MD5.file(file_path).base64digest
        bit_file.content_type = file_typer.file(file_path) rescue 'application/octet-stream'
        bit_file.size = File.size(file_path)
        bit_file.save
        Rails.logger.info "DX ingesting #{file_path}"
        Dx.instance.ingest_file(file_path, bit_file, opts)
        #mark as ingested and resave.
        bit_file.dx_ingested = true
        bit_file.save
      end
    end
  end

  def ensure_subdirectories(dirs, opts = {})
    current_subdirs = existing_subdirectory_names
    dirs.each do |dir|
      name = File.basename(dir)
      unless current_subdirs.include?(name)
        Rails.logger.info "Creating Rails subdirectory #{name}"
        self.children.create(:name => name, :collection_id => self.collection_id)
      end
    end
    self.children(true)
  end

  def existing_file_names
    self.bit_files.collect { |bf| bf.name }.to_set
  end

  def existing_subdirectory_names
    self.children.collect { |dir| dir.name }.to_set
  end

  def relative_path
    dirs = self.self_and_ancestors.reverse
    dirs.shift
    File.join(*(dirs.collect { |dir| dir.name }))
  end

  def path_from_root
    '/' + self.relative_path
  end

  def set_collection_id
    (self.collection_id ||= self.parent.collection_id) if self.parent
  end

  #total size of files owned directly by this directory
  def owned_file_size
    BitFile.where(:directory_id => self.id).sum(:size)
  end

  #total size of files owned by this directory and subdirectory
  def recursive_file_size
    self.descendant_file_size + self.owned_file_size
  end

  #total size of files owned by descendants of this directory (but not this directory itself)
  def descendant_file_size
    BitFile.where(:directory_id => descendant_directory_ids).sum(:size)
  end

  #total size of files owned by root directory of this directory
  def root_file_size
    BitFile.where(:directory_id => collection_directory_ids).sum(:size)
  end

  def collection_directory_ids
    Directory.where(:collection_id => self.collection_id).order('id').select('id').collect(&:id)
  end

  #this shouldn't do too badly unless we have deep trees - nested_set instead of acts_as_tree
  #would make this easier, but has its own problems of course. If it becomes a problem
  #we could write something in postgres itself to do it more efficiently.
  def descendant_directory_ids
    ids, old_ids = [], nil
    until ids == old_ids
      old_ids = ids
      ids = Directory.where(:parent_id => (old_ids.clone << self.id)).order('id').select('id').collect(&:id)
    end
    ids
  end

end
