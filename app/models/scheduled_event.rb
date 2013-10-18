class ScheduledEvent < ActiveRecord::Base
  #attr_accessible :action_date, :actor_netid, :key, :note, :scheduled_eventable_id, :scheduled_eventable_type, :state

  belongs_to :scheduled_eventable, :polymorphic => true

  STATES = ['scheduled', 'completed', 'cancelled']

  validates_inclusion_of :key, :in => lambda { |event| event.scheduled_eventable.supported_scheduled_event_keys }
  validates_format_of :actor_netid, :with => /\A[A-Za-z0-9]+\z/
  validates_presence_of :action_date
  validates_inclusion_of :state, :in => STATES
  before_validation :ensure_state

  def message
    self.scheduled_eventable.scheduled_event_message(self.key)
  end

  def ensure_state
    self.state ||= 'scheduled'
  end

  def enqueue_initial
    Delayed::Job.enqueue(self, :run_at => self.action_date)
  end

  def perform
    self.send("perform_#{self.state}")
  end

  def perform_scheduled
    #mail reminder
    ScheduledEventMailer.reminder(self).deliver
    #reschedule self - avoid endless loop in test system
    unless Rails.env.test?
      Delayed::Job.enqueue(self, :run_at => Date.today + 7.days)
    end
  end

  def perform_completed
    self.destroy
  end

  def perform_cancelled
    self.destroy
  end

  def scheduled?
    self.state == 'scheduled'
  end

  def be_complete
    self.transaction do
      self.state = 'completed'
      self.create_completion_event
      self.save!
    end
  end

  def be_cancelled
    self.state = 'cancelled'
    self.save!
  end

  def create_completion_event
    e = self.scheduled_eventable.events.build(:actor_netid => self.actor_netid, :key => self.scheduled_eventable.normal_event_key(self.key), :date => Date.today)
    e.save!
  end

  def select_options
    self.scheduled_eventable.scheduled_event_select_options
  end

end
