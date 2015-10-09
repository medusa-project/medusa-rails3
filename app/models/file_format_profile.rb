class FileFormatProfile < ActiveRecord::Base

  STATUSES = %w(active inactive)
  validates_uniqueness_of :name, allow_blank: false
  validates :status, presence: true, inclusion: STATUSES

  has_many :file_format_profiles_content_types_joins, dependent: :destroy
  has_many :content_types, -> {order "name asc"}, through: :file_format_profiles_content_types_joins
  has_many :file_format_profiles_file_extensions_joins, dependent: :destroy
  has_many :file_extensions, -> {order "extension asc"}, through: :file_format_profiles_file_extensions_joins

  def self.active
    where(status: 'active')
  end

end
