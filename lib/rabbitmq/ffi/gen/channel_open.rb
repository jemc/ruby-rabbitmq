
module RabbitMQ
  module FFI
    class ChannelOpen < ::FFI::Struct
      layout(:out_of_band, Bytes)
      
      def self.id
        :channel_open
      end
      
      def id
        :channel_open
      end
      
      def apply(out_of_band: nil)
        self[:out_of_band] = Bytes.from_s(out_of_band.to_s) if out_of_band
        self
      end
      
      def to_h(free=false)
        {out_of_band: self[:out_of_band].to_s(free)}
      end
      
      def free!
        self[:out_of_band].free!
      end
      
    end
  end
end
