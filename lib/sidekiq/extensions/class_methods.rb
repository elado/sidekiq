require 'sidekiq/extensions/generic_proxy'

module Sidekiq
  module Extensions
    ##
    # Adds a 'delay' method to all Classes to offload class method
    # execution to Sidekiq.  Examples:
    #
    # User.delay.delete_inactive
    # Wikipedia.delay.download_changes_for(Date.today)
    #
    class DelayedClass
      include Sidekiq::Worker

      def perform(*msg)
        (target, method_name, args) = ArgsSerializer.deserialize_message(*msg)
        target.send(method_name, *args)
      end
    end

    module Klass
      def delay
        Proxy.new(DelayedClass, self)
      end
      def delay_for(interval)
        Proxy.new(DelayedClass, self, Time.now.to_f + interval.to_f)
      end

      def sidekiq_serialize
        "SIDEKIQ:CLASS@#{self.name}"
      end
    end

  end
end

Class.send(:include, Sidekiq::Extensions::Klass)
Module.send(:include, Sidekiq::Extensions::Klass)
