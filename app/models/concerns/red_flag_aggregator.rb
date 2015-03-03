#Mix this in to an ActiveRecord::Base subclass and use aggregates_red_flags to specify how to accumulate
#red flags for a member of that class.
#The all_red_flags method is defined automatically and accumulates red flags as specified by the :self and
#:collections options.
#The :self option takes a symbol or array of symbols. Each of these  methods is called on the object to
#get a list of red flags.
#The :collections option takes a symbol or array of symbols. Each of these methods is called on the object to
#get a collection of other objects - for each of these objects :all_red_flags is called (if it is understood)
#and the returned red flags are accumulated
#The :label_method option specifies a method to send to the object to get a link label (to go back from the red flag
# table to the object.)
require 'active_support/concern'
module RedFlagAggregator
  extend ActiveSupport::Concern

  included do
    class_attribute :red_flag_methods
    class_attribute :red_flag_child_collections
    class_attribute :red_flag_aggregator_label_method
  end

  module ClassMethods
    def aggregates_red_flags(opts = {})
      self.red_flag_methods = Array.wrap(opts[:self] || [])
      self.red_flag_child_collections = Array.wrap(opts[:collections] || [])
      self.red_flag_aggregator_label_method = opts[:label_method]
    end

  end

  def all_red_flags
    red_flags = Array.new
    self.class.red_flag_methods.each do |method|
      red_flags = red_flags + self.send(method)
    end
    self.class.red_flag_child_collections.each do |child|
      collection = self.send(child)
      collection.each do |member|
        red_flags = red_flags + member.method_value_or_default(:all_red_flags, [])
      end
    end
    red_flags.uniq.sort { |a, b| b.created_at <=> a.created_at }
  end

  def red_flag_aggregator_label
    self.send(self.class.red_flag_aggregator_label_method)
  end


end