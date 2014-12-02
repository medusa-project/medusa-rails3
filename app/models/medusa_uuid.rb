require 'utils/luhn'

class MedusaUuid < ActiveRecord::Base
  belongs_to :uuidable, polymorphic: true

  validates_uniqueness_of :uuidable_type, scope: :uuidable_id
  validates_uniqueness_of :uuid, allow_blank: false
  # validates_each :uuid do |record, attr, value|
  #   record.errors.add attr, 'is not a valid uuid' unless Utils::Luhn.verify(value)
  # end

  def self.generate_for(uuidable)
    self.create!(uuid: Utils::Luhn.add_check_character(UUID.generate), uuidable: uuidable)
  end

end
