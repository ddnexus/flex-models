module Flex
  module ActiveModel
    module Inspection

      def inspect
        full_descriptions = [%(_id: #{@_id.inspect}), %(_version: #{@_version})]
        all_attributes    = if respond_to?(:raw_document)
                              reader_keys = raw_document.send(:readers).keys
                              # we send() the readers, so they would reflect an eventual overriding
                              Hash[ reader_keys.map{ |k| [k, send(k)] } ].merge(attributes)
                            else
                              attributes
                            end
        full_descriptions << Utils.keyfy(:to_sym, all_attributes).sort.map { |key, value| "#{key}: #{value.inspect}" }
        separator         = " " unless full_descriptions.empty?
        "#<#{self.class.name}#{separator}#{full_descriptions.join(", ")}>"
      end

    end
  end
end
