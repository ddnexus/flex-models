module Flex
  # private module
  module LiveReindex

    class MissingRedisError            < StandardError; end
    class LiveReindexInProgressError   < StandardError; end
    class MissingAppIdError            < StandardError; end
    class MissingStopIndexingProcError < StandardError; end
    class MissingEnsureIndicesError    < StandardError; end
    class ExtraIndexError              < StandardError; end
    class MultipleReindexError         < StandardError; end

    # private module
    module Redis

      KEYS = { :reindexing => 'flex-reindexing',
               :changes    => 'flex-changes' }

      extend self

      def method_missing(command, key, *args)
        return unless Conf.redis
        Conf.redis.send(command, "#{KEYS[key]}-#{Conf.app_id}", *args)
      end

      def reset_keys
        KEYS.keys.each { |k| del k }
      end

      def init
        begin
          require 'redis'
        rescue LoadError
          raise MissingRedisError, 'The live-reindex feature rely on redis. Please, install redis and the "redis" gem.'
        end
        # this should never happen
        raise LiveReindexInProgressError, %(It looks like a live-reindex is in progress. If you are sure that there is no live-reindex in progress, please run the "flex:reset_redis_keys" rake task and retry.) \
              if get(:reindexing)
        reset_keys # just in case
        set(:reindexing, true)
      end

    end


    extend self

    def models(opts={}, &block)
      @migrate_block = block || models_default_migrate_proc
      transaction(opts) do
        opts.extend Struct::Mergeable
        opts = opts.deep_merge(:force          => false,
                               :import_options => {:reindexing => true})
        ModelTasks.new(opts).import_models
      end
    end

    def active_models(opts={}, &block)
      @migrate_block  = block
      opts[:verbose]  = true unless opts.has_key?(:verbose)
      opts[:models] ||= Conf.flex_active_models
      transaction(opts) do
        opts[:models].each do |model|
          model = eval("::#{model}") if model.is_a?(String)
          raise ArgumentError, "The model #{model.name} is not a standard Flex::ActiveModel model" \
                unless model.include?(Flex::ActiveModel)

          pbar = ProgBar.new(model.count, nil, "Model #{model}: ") if opts[:verbose]

          model.find_in_batches({:raw_result => true, :params => {:fields => '*,_source'}}, opts) do |result|
            batch  = result['hits']['hits']
            result = process_and_post_batch(batch)
            pbar.process_result(result, batch.size) if opts[:verbose]
          end

          pbar.finish if opts[:verbose]

        end
      end
    end

    def indices(opts={}, &block)
      @migrate_block = block
      opts[:verbose] = true unless opts.has_key?(:verbose)
      opts[:index] ||= opts.delete(:indices) || config_hash.keys
      transaction(opts) do
        migrate_indices(opts)
      end
    end

    def in_progress?
      !!Redis.get(:reindexing)
    end

    def track_change(action, document)
      Redis.rpush(:changes, MultiJson.encode([action, document]))
    end

    # use this method when you are tracking the change of another app
    # you must pass the app_id of the app being affected by the change
    def track_external_change(app_id, action, document)
      return unless Conf.redis
      Conf.redis.rpush("#{KEYS[:changes]}-#{app_id}", MultiJson.encode([action, document]))
    end

    def prefix_index(index)
      base = unprefix_index(index)
      # raise if base is not included in @ensure_indices
      raise ExtraIndexError, "The index #{base} is missing from the :ensure_indices option. Reindexing aborted." \
            if @ensure_indices && !@ensure_indices.include?(base)
      prefixed = @timestamp + base
      unless @indices.include?(base)
        unless Flex.exist?(:index => prefixed)
          config_hash[base] = {} unless config_hash.has_key?(base)
          Flex.POST "/#{prefixed}", config_hash[base]
        end
        @indices |= [base]
      end
      prefixed
    end

    # remove the (eventual) prefix
    def unprefix_index(index)
      index.sub(/^\d{14}_/, '')
    end

  private

    def config_hash
      @config_hash ||= ModelTasks.new.config_hash
    end

    def transaction(opts={})
      Config.logger.warn 'Safe reindex is disabled!' if opts[:safe_reindex] == false
      Redis.init
      @indices        = []
      @timestamp      = Time.now.strftime('%Y%m%d%H%M%S_')
      @ensure_indices = nil

      raise MissingAppIdError, 'You must set the Flex::Configuration.app_id, and be sure you deploy it before live-reindexing.' \
            if Conf.app_id.nil?

      raise MissingStopIndexingProcError, 'The :stop_indexing_proc Proc is not set.' \
            if !opts.has_key?(:stop_indexing_proc) && !Conf.respond_to?(:stop_indexing_proc)
      stop_indexing_proc = opts.has_key?(:stop_indexing_proc) ? opts.delete(:stop_indexing_proc) : Conf.stop_indexing_proc

      raise MissingEnsureIndicesError, 'You must pass the :ensure_indices option when you pass the :models option.' \
            if opts.has_key?(:models) && !opts.has_key?(:ensure_indices)
      if opts[:ensure_indices]
        @ensure_indices = opts.delete(:ensure_indices)
        @ensure_indices = @ensure_indices.split(',') unless @ensure_indices.is_a?(Array)
        # no block, so verbatim copy into the new index
        migrate_block = @migrate_block
        @migrate_block = nil
        migrate_indices(:index => @ensure_indices)
        @migrate_block = migrate_block
      end

      yield
      # when the reindexing is ended we retries to empty the changes list a few times
      tries = 0
      bulk_string = ''
      until (count = Redis.llen(:changes)) == 0 || tries > 9
        count.times { bulk_string << build_bulk_string_from_change(Redis.lpop(:changes))}
        Flex.post_bulk_string(:bulk_string => bulk_string)
        bulk_string = ''
        tries += 1
      end
      # at this point the changes list should be empty or contain the minimum number of changes we could achieve live
      # the :stop_indexing_proc should ensure to stop/suspend all the actions that would produce changes in the indices being reindexed,
      # flush and wait a couple of secs maybe; pass nil if your index is not updated live by any other process
      stop_indexing_proc.call unless stop_indexing_proc.nil?
      # if we have still changes, we can index them (until the list will be empty)
      bulk_string = ''
      while (change = Redis.lpop(:changes))
        bulk_string << build_bulk_string_from_change(change)
      end
      Flex.post_bulk_string(:bulk_string => bulk_string)

      # deletes the old indices and create the aliases to the new
      @indices.each do |index|
        Flex.delete_index :index => index
        Flex.put_index_alias :alias => index,
                             :index => @timestamp + index
      end
      # after the execution of this method the user should deploy the new code and then resume the regular app processing

      # we redefine this method so it will raise an error if any new live-reindex is attempted during this session.
      unless opts[:safe_reindex] == false
        class_eval <<-ruby, __FILE__, __LINE__
          def transaction(*)
            raise MultipleReindexError, "Multiple live-reindex attempted! You cannot use any reindexing method multiple times in the same session or you may corrupt your index/indices! The previous reindexing in this session successfully reindexed and swapped the new index/indices: #{@indices.map{|i| @timestamp + i}.join(', ')}. If the code-changes that you are about to deploy rely on the successive reindexings that have been aborted, your app may fail. You should complete the other reindexing in single successive deploys ASAP. (If you are working in development mode - the next time - you can silence this error by passing :safe_reindex => false, but now you must restart the session.)"
          end
        ruby
      end

    rescue Exception
      # delete all the created indices
      @indices ||=[]
      @indices.each do |index|
        Flex.delete_index :index => @timestamp + index
      end
      raise

    ensure
      Redis.reset_keys
    end


    def models_default_migrate_proc
      proc do |action, doc|
        if action == 'index'
          begin
            { action => doc.load! }
          rescue Mongoid::Errors::DocumentNotFound, ActiveRecord::RecordNotFound
            nil # record already deleted
          end
        else
          { action => doc }
        end
      end
    end

    def migrate_indices(opts)
      opts[:verbose] = true unless opts.has_key?(:verbose)
      pbar = ProgBar.new(Flex.count(opts)['count'], nil, "index #{opts[:index].inspect}: ") if opts[:verbose]

      Flex.dump_all(opts) do |batch|
        result = process_and_post_batch(batch)
        pbar.process_result(result, batch.size) if opts[:verbose]
      end

      pbar.finish if opts[:verbose]
    end

    def process_and_post_batch(batch)
      bulk_string = ''
      batch.each do |document|
        bulk_string << build_bulk_string('index', document)
      end
      Flex.post_bulk_string(:bulk_string => bulk_string)
    end

    def build_bulk_string_from_change(change)
      action, document = MultiJson.decode(change)
      return '' unless @indices.include?(unprefix_index(document['_index']))
      build_bulk_string(action, document)
    end

    def build_bulk_string(action, document)
      result = if @migrate_block
                 document.extend(Result::Document)
                 document.extend(Result::DocumentLoader)
                 @migrate_block.call(action, document)
               else
                 [{ action => document }]
               end
      result = [result] unless result.is_a?(Array)
      bulk_string = ''
      result.compact.each do |hash|
        act, doc = hash.to_a.flatten
        bulk_string << Flex.build_bulk_string(doc, :reindexing => true, :action => act)
      end
      bulk_string
    end

  end
end
