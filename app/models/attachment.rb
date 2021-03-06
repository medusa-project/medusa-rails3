class Attachment < ApplicationRecord
  include EmailPersonAssociator
	email_person_association(:author)

	belongs_to :attachable, polymorphic: true, touch: true
	validates_inclusion_of :attachable_type, in: %w(Collection FileGroup ExternalFileGroup BitLevelFileGroup Project FileFormat)

	# Paperclip
	has_attached_file :attachment, styles: {}

  validates_attachment :attachment, presence: true, size: {less_than: Settings.classes.attachment.max_size}
  do_not_validate_attachment_file_type :attachment

  before_destroy :destroy_attachment

  def destroy_attachment
    self.attachment.try(:destroy)
  end

end