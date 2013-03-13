require 'weakref'

module DCell
  # Tracks objects-in-flight
  class Manager
    @mutex  = Mutex.new
    @ids    = {}
    @objects = {}

    def self.load(klass, string)
      id = string.slice!(0, string.index(":") + 1)
      match = id.match(/^([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})@(.+?):$/)
      raise ArgumentError, "couldn't parse object ID" unless match

      uuid, node_id = match[1], match[2]

      if DCell.id == node_id
        claim uuid
      else
        klass.new("#{uuid}@#{node_id}", Marshal.load(string))
      end
    end

    def self.store(object, *data)
      uuid = register(object)
      payload = Marshal.dump(data)
      "#{uuid}@#{DCell.id}:#{payload}"
    end

    def self.register(object)
      @mutex.lock
      begin
        id = @ids[object.object_id]
        unless id
          id = Celluloid.uuid
          @ids[object.object_id] = id
        end

        @objects[id] = WeakRef.new(object)
        id
      ensure
        @mutex.unlock rescue nil
      end
    end

    def self.claim(id)
      @mutex.lock
      begin
        ref = @objects.delete(id)
        ref.__getobj__ if ref
      rescue WeakRef::RefError
        # Nothing to see here, folks
      ensure
        @mutex.unlock rescue nil
      end
    end
  end
end
