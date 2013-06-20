class RedFlag < ActiveRecord::Base
  attr_accessible :message, :red_flaggable_id, :red_flaggable_type, :notes, :priority, :status
  belongs_to :red_flaggable, :polymorphic => true

  PRIORITIES = %w(high medium low)
  STATUSES = %w(flagged unflagged)

  validates_inclusion_of :priority, :in => PRIORITIES
  validates_inclusion_of :status, :in => STATUSES

  before_validation :ensure_priority, :ensure_status

  def ensure_priority
    self.priority ||= 'medium'
  end

  def ensure_status
    self.status ||= 'flagged'
  end

  def flagged?
    self.status == 'flagged'
  end

  def unflag!
    self.status = 'unflagged'
    self.save!
  end

end
