module Flex
  class Result
    module StoredModel

      # super is from flex-scopes
      def get_docs
        return super unless variables[:context].include?(Flex::StoredModel)
        freeze = !!variables[:params][:fields]
        docs = super
        if docs.is_a?(Array)
          res = docs.map {|d| build_object(d, freeze)}
          res.extend Result::Collection
          res.setup docs.size, variables
          res
        else
          build_object docs, freeze
        end
      end

      private

      def build_object(doc, freeze)
        attrs  = (doc['_source']||{}).merge(doc['fields']||{})
        object = variables[:context].new attrs
        object.instance_eval do
          @_id      = doc['_id']
          @_version = doc['_version']
        end
        (freeze || doc['fields']) ? object.freeze : object
      end

    end
  end
end
