require 'net_id_person_associator'
require 'registers_handle'
require 'mods_helper'
require 'utils/luhn'

class Collection < ActiveRecord::Base
  include RegistersHandle
  include ModsHelper
  net_id_person_association(:contact)
  attr_accessible :access_url, :description, :private_description, :end_date, :file_package_summary, :notes,
                  :ongoing, :published, :repository_id, :start_date, :title, :access_system_ids,
                  :preservation_priority_id, :resource_type_ids, :rights_declaration_attributes

  belongs_to :repository
  has_many :assessments, :dependent => :destroy
  has_many :file_groups, :dependent => :destroy
  has_many :access_system_collection_joins, :dependent => :destroy
  has_many :access_systems, :through => :access_system_collection_joins
  has_many :collection_resource_type_joins, :dependent => :destroy
  has_many :resource_types, :through => :collection_resource_type_joins
  has_one :ingest_status, :dependent => :destroy
  belongs_to :preservation_priority
  has_one :rights_declaration, :dependent => :destroy, :autosave => true, :as => :rights_declarable
  has_many :directories
  has_one :root_directory, :class_name => Directory, :conditions => {:parent_id => nil}

  validates_presence_of :title
  validates_uniqueness_of :title, :scope => :repository_id
  validates_presence_of :repository_id
  validates_presence_of :preservation_priority_id
  validates_uniqueness_of :uuid
  validates_each :uuid do |record, attr, value|
    record.errors.add attr, 'is not a valid uuid' unless Utils::Luhn.verify(value)
  end

  after_create :ensure_ingest_status
  after_create :ensure_handle
  after_create :ensure_root_directory
  after_save :ensure_fedora_collection
  before_destroy :remove_handle
  before_destroy :delete_fedora_collection
  before_validation :ensure_uuid
  before_validation :ensure_rights_declaration

  accepts_nested_attributes_for :rights_declaration

  auto_strip_attributes :description, :private_description, :notes, :file_package_summary, :nullify => false

  [:description, :private_description, :notes, :file_package_summary].each do |field|
    auto_html_for field do
      html_escape
      link :target => "_blank"
      simple_format
    end
  end

  def total_size
    self.file_groups.sum(:total_file_size)
  end

  def ensure_ingest_status
    self.ingest_status ||= IngestStatus.new(:state => :unstarted)
  end

  def ensure_uuid
    self.uuid ||= Utils::Luhn.add_check_character(UUID.generate)
  end

  def handle
    self.uuid ? "10111/MEDUSA:#{self.uuid}" : nil
  end

  def medusa_url
    Rails.application.routes.url_helpers.collection_url(self, :host => MedusaRails3::Application.medusa_host, :protocol => 'https')
  end

  def medusa_pid
    "MEDUSA:#{self.uuid}"
  end

  def resource_type_names
    self.resource_types.collect(&:name).join('; ')
  end

  def preservation_priority_name
    self.preservation_priority.try(:name)
  end

  def ensure_rights_declaration
    self.rights_declaration ||= self.build_rights_declaration
  end

  def to_mods
    with_mods_boilerplate do |xml|
      xml.titleInfo do
        xml.title self.title
      end
      xml.identifier(self.uuid, :type => 'uuid')
      xml.identifier(self.handle, :type => 'handle')
      self.resource_types.each do |resource_type|
        xml.typeOfResource(resource_type.name, :collection => 'yes')
      end
      xml.abstract self.description
      xml.location do
        xml.url(self.access_url || '', :access => 'object in context', :usage => 'primary')
      end
      xml.originInfo do
        xml.publisher(self.repository.title)
        xml.dateOther(self.start_date, :point => 'start')
        xml.dateOther(self.end_date, :point => 'end')
      end
    end
  end

  #make sure there is a corresponding collection object in fedora and that its mods is up to date
  def ensure_fedora_collection

    unless self.fedora_class.exists?(self.medusa_pid)
      self.fedora_class.new(:pid => self.medusa_pid).save
    end
    collection = self.fedora_collection
    mods_stream = collection.datastreams['MODS']
    unless mods_stream
      mods_stream = collection.create_datastream(ActiveFedora::Datastream, 'MODS', :controlGroup => 'M',
                                                 :dsLabel => 'MODS', :contentType => 'text/xml', :checksumType => 'SHA-1')
      collection.add_datastream(mods_stream)
    end
    current_mods = self.to_mods
    unless mods_stream.content == current_mods
      mods_stream.content = current_mods
    end
    collection.save
  end

  def delete_fedora_collection
    collection = self.fedora_collection
    collection.delete if collection.present?
  end

  #Note - you have to be careful with this since it fetches the collection anew.
  #If you already have the collection then you probably want to operate on
  #its datastreams directly!
  def fedora_mods_datastream
    self.fedora_collection.datastreams['MODS']
  end

  def fedora_collection
    self.fedora_class.find(self.medusa_pid) rescue nil
  end

  def fedora_class
    Medusa::Collection
  end

  def ensure_root_directory
    unless self.root_directory
      self.create_root_directory!(:name => "root-#{self.id}")
    end
  end

  def make_file_group_root(name)
    self.root_directory.children.create!(:name => name)
  end

  def bit_export(target_directory, opts = {})
    self.root_directory.bit_export(target_directory, opts)
  end

  def bit_recursive_delete()
    self.file_groups.each do |file_group|
      file_group.bit_recursive_delete
    end
  end

end

