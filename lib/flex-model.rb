require 'flex'
require 'flex/scopes'
require 'active_attr'

require 'flex/struct/mergeable'

require 'flex/class_proxy/model_syncer'
require 'flex/instance_proxy/model_syncer'
require 'flex/model_syncer'

require 'flex/class_proxy/model_indexer'
require 'flex/instance_proxy/model_indexer'
require 'flex/model_indexer'

require 'flex/active_model/timestamps'
require 'flex/active_model/inspection'
require 'flex/active_model/storage'
require 'flex/class_proxy/active_model'
require 'flex/instance_proxy/active_model'
require 'flex/active_model'

require 'flex/refresh_callbacks'

require 'flex/result/document_loader'
require 'flex/result/search_loader'
require 'flex/result/active_model'

Flex::LIB_PATHS << __FILE__.sub(/flex-model.rb$/, '')

# get_docs calls super so we make sure the result is extended by Scope first
Flex::Conf.result_extenders |= [ Flex::Result::DocumentLoader,
                                 Flex::Result::SearchLoader,
                                 Flex::Result::ActiveModel ]
Flex::Conf.flex_models = []
