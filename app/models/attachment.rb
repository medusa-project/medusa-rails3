require 'email_person_associator'
class Attachment < ActiveRecord::Base
	email_person_association(:author)

	belongs_to :attachable, :polymorphic => true
	validates_inclusion_of :attachable_type, :in => ['Collection', 'FileGroup', 'ExternalFileGroup', 'BitLevelFileGroup', 'ObjectLevelFileGroup']

	# Paperclip
	has_attached_file :attachment, :styles => {}

  validates_attachment :attachment, :presence => true, :size => {:less_than => 5.megabytes}
  do_not_validate_attachment_file_type :attachment
  do_not_validate_attachment_file_type :attachment
end