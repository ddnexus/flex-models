module Flex
  module InstanceProxy
    class ActiveModel < ModelIndexer

      def store(*vars)
        return super unless instance.flex_indexable? # this should never happen since flex_indexable? returns true
        meth = instance.new_record? ? :post_store : :store
        Flex.send(meth, metainfo, {:data => instance.flex_source}, *vars)
      end

    end
  end
end
