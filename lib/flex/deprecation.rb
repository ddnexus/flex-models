module Flex

  module Model
    NEW_MODULE = ModelMapper
    extend Deprecation::Module
  end

  module Result::Document
    NEW_MODULE = Result::LoadableDocument
    extend Utils::DeprecateModule
  end

end
