require 'weakref'

module DCell
  # Tracks calls-in-flight
  class Manager
    @mutex  = Mutex.new
    @ids    = {}
    @calls  = {}

    def self.load(string)
      id = string.slice!(0, string.index(":") + 1)
      match = id.match(/^([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})@(.+?):$/)
      raise ArgumentError, "couldn't parse call ID" unless match

      uuid, node_id = match[1], match[2]

      if DCell.id == node_id
        claim uuid
      else
        caller, method, arguments, block = Marshal.load(string)
        RPC.new("#{uuid}@#{node_id}", caller, method, arguments, block)
      end
    end

    def self.store(call, *data)
      uuid = register(call)
      payload = Marshal.dump(data)
      "#{uuid}@#{DCell.id}:#{payload}"
    end

    def self.register(call)
      @mutex.lock
      begin
        call_id = @ids[call.object_id]
        unless call_id
          call_id = Celluloid.uuid
          @ids[call.object_id] = call_id
        end

        @calls[call_id] = WeakRef.new(call)
        call_id
      ensure
        @mutex.unlock rescue nil
      end
    end

    def self.claim(call_id)
      @mutex.lock
      begin
        ref = @calls.delete(call_id)
        ref.__getobj__ if ref
      rescue WeakRef::RefError
        # Nothing to see here, folks
      ensure
        @mutex.unlock rescue nil
      end
    end
  end
end
