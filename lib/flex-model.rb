require 'flex'
require 'flex/scopes'
require 'active_attr'

require 'flex/struct/mergeable'
require 'flex/class_proxy/model_sync'
require 'flex/class_proxy/model_mapper'
require 'flex/class_proxy/related_model'

require 'flex/instance_proxy/base'
require 'flex/instance_proxy/model_mapper'
require 'flex/instance_proxy/related_model'

require 'flex/manager'

require 'flex/related_model'
require 'flex/model_mapper'

require 'flex/stored_model/timestamps'
require 'flex/stored_model/inspection'
require 'flex/stored_model/storage'
require 'flex/class_proxy/stored_model'
require 'flex/instance_proxy/stored_model'
require 'flex/stored_model'
require 'flex/refresh_callbacks'

require 'flex/result/loadable_document'
require 'flex/result/loadable_search'
require 'flex/result/stored_model'

require 'flex/deprecation'

Flex::LIB_PATHS << __FILE__.sub(/flex-model.rb$/, '')

# get_docs calls super so we make sure the result is extended by Scope first
Flex::Conf.result_extenders |= [ Flex::Result::LoadableDocument,
                                 Flex::Result::LoadableSearch,
                                 Flex::Result::Scope,
                                 Flex::Result::StoredModel ]
Flex::Conf.flex_models = []
