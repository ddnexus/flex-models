module Flex
  class Result
    module ActiveModel

      class FlattenedReaderError < StandardError; end

      include Flex::Result::Scope

      # extend if the context include a Flex::ActiveModel
      def self.should_extend?(result)
       result.variables[:context].include?(Flex::ActiveModel)
      end

      def get_docs
        # super is from flex-scopes
        docs = super
        return docs if variables[:raw_result]
        if docs.is_a?(Array)
          res = docs.map {|d| build_object(d)}
          res.extend Struct::Paginable
          res.setup docs.size, variables
          res.instance_variable_set(:'@raw_result', self)
          def res.raw_result; @raw_result end
          res
        else
          build_object docs
        end
      end

    private

      def build_object(doc)
        attrs  = (doc['_source']||{}).merge(doc['fields']||{})
        object = variables[:context].new attrs
        raw_result = self
        object.instance_eval do
          metaclass = class << self; self end
          # adds readers like :a_b_c for nested attributes like 'a.b.c'
          # so multi_fields and attachment fields are accessible
          attrs.keys.sort.each do |key|
            if key.include?('.')
              reader = key.gsub('.','_').to_sym
              raise FlattenedReaderError, "Instance method #{reader.inspect} already defined for class #{self.class}" \
                    if respond_to?(reader)
            else
              reader = key
            end
            unless respond_to?(key)
              metaclass.class_eval do
                define_method(reader) { attrs[key] }
              end
              attribute_readers << reader
            end
          end

          @_id        = doc['_id']
          @_version   = doc['_version']
          @highlight  = doc['highlight']
          @raw_result = raw_result
          # load the flex proxy before freezing
          flex
          self.freeze if raw_result.variables[:params][:fields] || doc['fields']
        end
        object
      end

    end
  end
end
