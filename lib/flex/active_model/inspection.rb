module Flex
  module ActiveModel
    module Inspection

      def inspect
        full_descriptions = [%(_id: #{@_id.inspect}), %(_version: #{@_version})]
        all_attributes    = attributes.merge Hash[attribute_readers.map{|k|[k,send(k)]}]
        full_descriptions << Utils.keyfy(:to_sym, all_attributes).sort.map { |key, value| "#{key}: #{value.inspect}" }
        separator         = " " unless full_descriptions.empty?
        "#<#{self.class.name}#{separator}#{full_descriptions.join(", ")}>"
      end

    end
  end
end
