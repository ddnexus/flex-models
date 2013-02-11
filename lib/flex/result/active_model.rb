module Flex
  class Result
    module ActiveModel

      include Flex::Result::Scope

      # extend if the context include a Flex::ActiveModel
      def self.should_extend?(result)
       result.variables[:context].include?(Flex::ActiveModel)
      end

      # super is from flex-scopes
      def get_docs
        freeze = !!variables[:params][:fields]
        docs = super
        return docs if variables[:raw_result]
        if docs.is_a?(Array)
          res = docs.map {|d| build_object(d, freeze)}
          res.extend Struct::Paginable
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
