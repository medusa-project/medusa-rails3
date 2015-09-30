require 'registers_handle'
require 'mods_helper'

class Collection < ActiveRecord::Base
  include MedusaAutoHtml
  include RegistersHandle
  include ModsHelper
  include RedFlagAggregator
  include Uuidable
  include Breadcrumb
  include CascadedEventable
  include ResourceTypeable
  include EmailPersonAssociator

  email_person_association(:contact)

  belongs_to :repository
  belongs_to :preservation_priority

  has_many :assessments, dependent: :destroy, as: :assessable
  has_many :file_groups, dependent: :destroy
  has_many :access_system_collection_joins, dependent: :destroy
  has_many :access_systems, through: :access_system_collection_joins
  has_one :rights_declaration, dependent: :destroy, autosave: true, as: :rights_declarable
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :projects

  delegate :public?, to: :rights_declaration
  delegate :title, to: :repository, prefix: true
  delegate :name, to: :preservation_priority, prefix: true, allow_nil: true

  validates_presence_of :title
  validates_uniqueness_of :title, scope: :repository_id
  validates_presence_of :repository_id
  validates_presence_of :preservation_priority_id

  after_create :delayed_ensure_handle
  before_destroy :remove_handle
  before_validation :ensure_rights_declaration

  accepts_nested_attributes_for :rights_declaration

  auto_strip_attributes :description, :private_description, :notes, nullify: false

  standard_auto_html(:description, :private_description, :notes)

  aggregates_red_flags collections: :file_groups, label_method: :title
  breadcrumbs parent: :repository, label: :title
  cascades_events parent: :repository

  def total_size
    self.file_groups.select {|fg| fg.is_a?(BitLevelFileGroup)}.collect { |fg| fg.file_size }.sum
  end

  def medusa_url
    Rails.application.routes.url_helpers.collection_url(self, host: MedusaCollectionRegistry::Application.medusa_host, protocol: 'https')
  end

  def ensure_rights_declaration
    self.rights_declaration ||= RightsDeclaration.new(rights_declarable_id: self.id,
                                                      rights_declarable_type: 'Collection')
  end

  def to_mods
    with_mods_boilerplate do |xml|
      xml.titleInfo do
        xml.title self.title
      end
      xml.identifier(self.uuid, type: 'uuid')
      xml.identifier(self.handle, type: 'handle')
      resource_types_to_mods(xml)
      xml.abstract self.description
      xml.location do
        xml.url(self.access_url || '', access: 'object in context', usage: 'primary')
      end
      xml.originInfo do
        xml.publisher(self.repository.title)
      end
    end
  end

  def recursive_assessments
    (self.assessments + self.file_groups.collect { |file_group| file_group.assessments }.flatten)
  end

  def all_scheduled_events
    self.file_groups.collect { |file_group| file_group.scheduled_events }.flatten
  end

  def incomplete_scheduled_events
    self.file_groups.collect { |file_group| file_group.incomplete_scheduled_events }.flatten
  end


end

