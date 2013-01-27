module Flex
  module ClassProxy
    module ModelSyncer

      attr_accessor :synced

      def sync(*synced)

        # Flex::ActiveModel has its own way of syncing, and a Flex::ModelSyncer only cannot be synced
        if synced.any?{|s| s == context} && context.include?(Flex::ActiveModel) || !context.include?(Flex::ModelMapper)
          raise ArgumentError, %(You cannot flex.sync(self) #{self}.)
        end

        @synced = synced
        context.class_eval do
          raise NotImplementedError, "the class #{self} must implement :after_save and :after_destroy callbacks" \
                unless respond_to?(:after_save) && respond_to?(:after_destroy)
          after_save    { flex.sync }
          after_destroy { flex.sync }
        end
      end

    end
  end
end
