module Flex
  module ClassProxy
    module StoredModel

      def init(*vars)
        variables.deep_merge! *vars
      end

      def sync(*synced)
        raise ArgumentError, 'You cannot flex.sync(self) a Flex::StoredModel.' \
              if synced.any?{|s| s == host_class}
        super
      end

      def get_index_mapping
        props = { }
        context.attributes.each do |name, attr|
          options     = attr.send(:options)
          props[name] = case
                        when options.has_key?(:properties)
                          Utils.keyfy(:to_s, attr.send(:options)[:properties])
                        when options.has_key?(:not_analyzed) && options[:not_analyzed] ||
                             options.has_key?(:analyzed)     && !options[:analyzed]
                          { 'type' => 'string', 'index' => 'not_analyzed' }
                        when options[:type] == DateTime
                          { 'type' => 'date', 'format' => 'dateOptionalTime' }
                        else
                          next
                        end
        end
        { index => { 'mappings' => { type => { 'properties' => props } } } } unless props.empty?
      end

    end
  end
end
