require 'date'
version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |s|
  s.name                      = 'flex-model'
  s.summary                   = 'Flex Plugin: provides different kinds of integration between ActiveRecord, Mongoid or persistent ActiveModel models and any Elasticserach index.'
  s.description               = <<-description
Flex Plugin: allows to map any ActiveRecord or Mongoid model structure to any Elasticsearch index. It also allows to use the Elasticsearch index as a data storage managed with ActiveModel validation and callbacks; ActiveAttr typecasting, attribute defaults. It implements storage, with optional optimistic lock update, finders, inline scope for easy query definition, etc.
  description
  s.homepage                  = 'http://github.com/ddnexus/flex-model'
  s.authors                   = ["Domizio Demichelis"]
  s.email                     = 'dd.nexus@gmail.com'
  s.extra_rdoc_files          = %w[README.md]
  s.files                     = `git ls-files -z`.split("\0")
  s.version                   = version
  s.date                      = Date.today.to_s
  s.required_rubygems_version = ">= 1.3.6"
  s.rdoc_options              = %w[--charset=UTF-8]

  s.add_runtime_dependency 'flex',        version
  s.add_runtime_dependency 'flex-scopes', version
  s.add_runtime_dependency 'flex-model',  version


  s.add_runtime_dependency 'active_attr', '>= 0.6.0', '~> 0.7.0'
end
