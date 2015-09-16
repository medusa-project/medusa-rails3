class Assessment < ActiveRecord::Base
  include MedusaAutoHtml
  include EmailPersonAssociator

  email_person_association(:author)

  belongs_to :assessable, polymorphic: true, touch: true
  belongs_to :storage_medium, touch: true

  delegate :name, to: :storage_medium, prefix: true, allow_nil: true

  validates_inclusion_of :assessable_type, in: %w(Collection FileGroup Repository)
  validates_presence_of :name

  ASSESSMENT_TYPES = %w(external_files)
  RISK_LEVELS = %w(low medium high urgent)

  validates_inclusion_of :assessment_type, in: ASSESSMENT_TYPES
  validates_inclusion_of :preservation_risk_level, in: RISK_LEVELS

  standard_auto_html(:naming_conventions, :directory_structure, :notes, :preservation_risks)

end
