module DCell
  class RPC < Celluloid::SyncCall
    def initialize(id, caller, method, arguments, block)
      @id, @caller, @method, @arguments, @block = id, caller, method, arguments, block
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump [@caller, @method, @arguments, @block]
      "#{@id}:#{payload}"
    end

    # Loader for custom marshal format
    def self._load(string)
      Manager.load(self, string)
    end
  end
end
