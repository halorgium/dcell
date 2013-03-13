module DCell
  class RPC < Celluloid::SyncCall
    IVARS = [:@caller, :@method, :@arguments, :@block]

    def initialize(id, data)
      @id = id
      @data = data
      IVARS.each.with_index do |ivar,index|
        instance_variable_set(ivar, data.fetch(index))
      end
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump @data
      "#{@id}:#{payload}"
    end

    def self.store(object)
      data = IVARS.map do |ivar|
        object.instance_variable_get(ivar)
      end
      Manager.store(object, data)
    end

    # Loader for custom marshal format
    def self._load(string)
      Manager.load(self, string)
    end
  end
end
