module DCell
  class RPC < Celluloid::SyncCall
    def initialize(id, data)
      @id = id
      @data = data
      [:@caller, :@method, :@arguments, :@block].each.with_index do |ivar,index|
        instance_variable_set(ivar, data.fetch(index))
      end
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump @data
      "#{@id}:#{payload}"
    end

    # Loader for custom marshal format
    def self._load(string)
      Manager.load(self, string)
    end
  end
end
