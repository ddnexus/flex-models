require 'flex-model'
require 'flex/flex_model_tasks'

env   = defined?(Rails) ? :environment : []

namespace :flex do

  desc 'imports from an ActiveRecord or Mongoid models'
  task(:import => env) {  Flex::ModelTasks.new.import_models }

end
