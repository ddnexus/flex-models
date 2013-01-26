module Flex
  module Manager

    extend self

    attr_accessor :parent_types
    @parent_types = []

    # arrays of all the types
    def types
      @types ||= Conf.flex_models.map {|m| (m.is_a?(String) ? eval("::#{m}") : m).flex.type }.flatten
    end

    # sets the default parent/child mappings and returns the default indices structure used for creating the indices
    def default_mapping
      @default_mapping ||= begin
                             default = {}.extend Struct::Mergeable
                             Conf.flex_models.each do |m|
                               m = eval"::#{m}" if m.is_a?(String)
                              default.deep_merge! m.flex.get_index_mapping
                             end
                             default
                           end
    end

    # maps all the index/types to the ruby class
    def type_class_map
      @type_class_map ||= begin
                            map = {}
                            Conf.flex_models.each do |m|
                              m = eval("::#{m}") if m.is_a?(String)
                              types = m.flex.type.is_a?(Array) ? m.flex.type : [m.flex.type]
                              types.each do |t|
                                map["#{m.flex.index}/#{t}"] = m
                              end
                            end
                            map
                          end
    end

  end
end
