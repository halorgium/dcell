module DCell
  class Future
    def initialize(address,node_id,node_addr)
      @address = address
      @node_id = node_id
      @node_addr = node_addr
    end

    def <<(message)
      node = Node[@node_id]
      node = Node.new(@node_id, @node_addr) unless node
      node.send_message! Message::Relay.new(self, message)
    end

    def _dump(level)
      Marshal.dump [@address, @node_id, @node_addr]
    end

    # Loader for custom marshal format
    def self._load(string)
      address, node_id, node_addr = Marshal.load(string)
      if node_id == DCell.id
        Router.find(address)
      else
        new(address, node_id, node_addr)
      end
    end
  end
end
