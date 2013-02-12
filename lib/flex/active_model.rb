module Flex
  module ActiveModel

    attr_reader :_version, :_id, :highlight, :raw_result
    alias_method :id, :_id

    def self.included(base)
      base.class_eval do
        @flex ||= ClassProxy::Base.new(base)
        @flex.extend(ClassProxy::ModelIndexer).init
        @flex.extend(ClassProxy::ModelSyncer)
        @flex.extend(ClassProxy::ActiveModel).init :params => {:version => true}
        def self.flex; @flex end

        include Scopes
        include ActiveAttr::Model

        extend  ::ActiveModel::Callbacks
        define_model_callbacks :create, :update, :save, :destroy

        include Storage::InstanceMethods
        extend  Storage::ClassMethods
        include Inspection
        extend  Timestamps
        extend  Attachment
      end
    end

    def flex
      @flex ||= InstanceProxy::ActiveModel.new(self)
    end

    def flex_source
      attributes
    end

    def flex_indexable?
      true
    end

    def attribute_readers
      @attribute_readers ||= []
    end

  end
end
