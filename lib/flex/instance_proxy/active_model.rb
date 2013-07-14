module Flex
  module InstanceProxy
    class ActiveModel < ModelIndexer

      def store(*vars)
        return super unless instance.flex_indexable? # this should never happen since flex_indexable? returns true
        meth = instance.respond_to?(:generate_id) || !instance.new_record? ? :put_store : :post_store
        Flex.send(meth, metainfo, {:data => instance.flex_source}, *vars)
      end

      def id
        instance.new_record? && instance.respond_to?(:generate_id) ? instance.generate_id : super
      end

      def sync_self
        instance.instance_eval do
          if destroyed?
            run_callbacks :destroy do
              flex.remove
            end
          else
            run_callbacks :save do
              context = new_record? ? :create : :update
              run_callbacks(context) do
                result    = context == :create ? flex.store : flex.store(:params => { :version => _version })
                @_id      = result['_id']
                @_version = result['_version']
              end
            end
          end
        end
      end

    end
  end
end
