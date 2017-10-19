
module RabbitMQ
  module FFI
    class BasicGetEmpty < ::FFI::Struct
      layout(:cluster_id, Bytes)
      
      def self.id
        :basic_get_empty
      end
      
      def id
        :basic_get_empty
      end
      
      def apply(cluster_id: nil)
        self[:cluster_id] = Bytes.from_s(cluster_id.to_s) if cluster_id
        self
      end
      
      def to_h(free=false)
        {cluster_id: self[:cluster_id].to_s(free)}
      end
      
      def free!
        self[:cluster_id].free!
      end
      
    end
  end
end
