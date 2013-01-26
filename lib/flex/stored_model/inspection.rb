module Flex
  module StoredModel
    module Inspection

      def inspect
        full_descriptions = [%(_id: #{@_id.inspect}), %(_version: #{@_version})]
        full_descriptions <<  attributes.sort.map { |key, value| "#{key}: #{value.inspect}" }
        separator = " " unless full_descriptions.empty?
        "#<#{self.class.name}#{separator}#{full_descriptions.join(", ")}>"
      end

    end
  end
end
