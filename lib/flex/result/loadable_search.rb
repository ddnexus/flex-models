module Flex
  class Result
    module LoadableSearch

      # extend if result comes from a search url
      def self.should_extend?(result)
        result['hits'] && result['hits']['hits']
      end

      def loaded_collection
        @loaded_collection ||= begin
                                 records  = []
                                 # returns a structure like {Comment=>[{"_id"=>"123", ...}, {...}], BlogPost=>[...]}
                                 h = Utils.group_array_by(collection) do |d|
                                   d.mapped_class(should_raise=true)
                                 end
                                 h.each do |klass, docs|
                                   records |= klass.find(docs.map(&:_id))
                                 end
                                 class_ids = collection.map { |d| [d.mapped_class.to_s,  d._id] }
                                 # Reorder records to preserve order from search results
                                 records = class_ids.map do |class_str, id|
                                   records.detect do |record|
                                     record.class.to_s == class_str && record.id.to_s == id.to_s
                                   end
                                 end
                                 records.extend Struct::Paginable
                                 records.setup(self['hits']['total'], variables)
                                 records
                               end
      end

    end
  end
end
