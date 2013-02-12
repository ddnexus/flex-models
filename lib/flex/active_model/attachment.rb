require 'base64'
module Flex
  module ActiveModel
    module Attachment

      # defines accessors for <attachment_field_name>
      # if you omit the arguments it uses :attachment as the <attachment_field_name>
      # you can also pass other properties that will be merged with the default property for attachment
      def attribute_attachment(*args)
        name  = args.first.is_a?(Symbol) ? args.shift : :attachment
        props = {:properties => { 'type'   => 'attachment',
                                  'fields' => { name.to_s      => { 'store' => 'yes', 'term_vector' => 'with_positions_offsets' },
                                                'title'        => { 'store' => 'yes' },
                                                'author'       => { 'store' => 'yes' },
                                                'name'         => { 'store' => 'yes' },
                                                'content_type' => { 'store' => 'yes' },
                                                'date'         => { 'store' => 'yes' },
                                                'keywords'     => { 'store' => 'yes' }
                                              }
                                }
                }
        props.extend(Struct::Mergeable).deep_merge! args.first if args.first.is_a?(Hash)
        attribute name, props
      end

    end
  end
end
