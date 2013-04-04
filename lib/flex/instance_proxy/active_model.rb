module Flex
  module InstanceProxy
    class ActiveModel < ModelIndexer

      def store(*vars)
        return super unless instance.flex_indexable? # this should never happen since flex_indexable? returns true
        meth = instance.respond_to?(:new_record_id) || !instance.new_record? ? :store : :post_store
        Flex.send(meth, metainfo, {:data => instance.flex_source}, *vars)
      end

      def id
        instance.new_record? && instance.respond_to?(:new_record_id) ? instance.new_record_id : super
      end

    end
  end
end
