module Flex
  module StoredModel
    module Storage

      module ClassMethods

        def create(args={}, vars={})
          document = new(args)
          return false unless document.valid?
          document.save(vars)
        end

      end


      module InstanceMethods

        def reload
          document        = flex.get
          self.attributes = document['_source']
          @_id            = document['_id']
          @_version       = document['_version']
        end

        def save(vars={})
          return false unless valid?
          run_callbacks :save do
            run_callbacks(new_record? ? :create : :update) { do_save(vars) }
          end
          self
        end

        # Optimistic Lock Update
        #
        #    doc.lock_update do |d|
        #      d.amount += 100
        #    end
        #
        # if you are trying to update a stale object, the block is yielded again with a fresh reloaded document and the
        # document is saved only when it is not stale anymore (i.e. the _version has not changed since it has been loaded)
        # read: http://www.elasticsearch.org/blog/2011/02/08/versioning.html
        #
        def lock_update(vars={})
          return false unless valid?
          run_callbacks :save do
            run_callbacks :update do
              begin
                yield self
                result = flex.store({:params => {:version => _version}}.merge(vars))
              rescue Flex::HttpError => e
                if e.status == 409
                  reload
                  retry
                else
                  raise
                end
              end
            end
            @_id      = result['_id']
            @_version = result['_version']
          end
          self
        end

        def destroy
          run_callbacks :destroy do
            flex.remove
            @destroyed = true
          end
          self.freeze
        end

        def update_attributes(attributes)
          attributes.each {|name, value| send "#{name}=", value }
          save
        end

        def destroyed?
          !!@destroyed
        end

        def persisted?
          !(new_record? || destroyed?)
        end

        def new_record?
          !@_id || !@_version
        end

      private

        def do_save(vars)
          result    = flex.store(vars)
          @_id      = result['_id']
          @_version = result['_version']
        end

      end

    end


  end
end
