class Repository < ApplicationRecord
  include ActiveDateChecker
  include Breadcrumb
  include CascadedEventable
  include CascadedRedFlaggable
  include MedusaAutoHtml
  include EmailPersonAssociator

  email_person_association(:contact)
  belongs_to :institution
  has_many :collections, dependent: :destroy
  has_many :assessments, as: :assessable, dependent: :destroy
  has_many :virtual_repositories, dependent: :destroy

  LDAP_DOMAINS = %w(uofi uiuc)

  validates_uniqueness_of :title
  validates_presence_of :title
  validates_presence_of :institution_id
  validate :check_active_dates
  validates_inclusion_of :ldap_admin_domain, in: LDAP_DOMAINS, allow_blank: true

  standard_auto_html(:notes)

  breadcrumbs parent: nil, label: :title
  cascades_events parent: nil
  cascades_red_flags parent: nil

  def total_size
    self.collections.collect { |c| c.total_size }.sum
  end

  def total_files
    self.collections.collect {|c| c.total_files}.sum
  end

  #TODO - this will probably not be correct any more when we have more than one institution
  def self.aggregate_size
    BitLevelFileGroup.aggregate_size
  end

  def recursive_assessments
    self.assessments + self.collections.collect { |collection| collection.recursive_assessments }.flatten
  end

  def manager?(user)
    Application.group_resolver.is_member_of?(self.ldap_admin_group, user)
  end

  def repository
    self
  end

  def parent
    nil
  end
  
end
