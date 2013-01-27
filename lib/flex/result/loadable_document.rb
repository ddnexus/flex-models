module Flex
  class Result

    #  adds sugar to documents with the following structure:
    #
    #    {
    #        "_index" : "twitter",
    #        "_type" : "tweet",
    #        "_id" : "1",
    #    }

    module LoadableDocument

      # extend if result has a structure like a document
      def self.should_extend?(obj)
        %w[_index _type _id].all? {|k| obj.has_key?(k)}
      end

      def mapped_class(should_raise=false)
        @mapped_class ||= Manager.type_class_map["#{_index}/#{_type}"]
      rescue NameError
        raise DocumentMappingError, "the '#{_index}/#{_type}' document cannot be mapped to any class." \
              if should_raise
      end

      def load
        mapped_class.find self['_id']
      end

    end

  end
end
