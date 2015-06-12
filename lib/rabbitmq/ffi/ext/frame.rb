
module RabbitMQ
  module FFI
    
    class Frame
      def payload
        member = case self[:frame_type]
        when :method; :method
        when :header; :properties
        when :body;   :body_fragment
        else; raise NotImplementedError, "frame type: #{self[:frame_type]}"
        end
        self[:payload][member]
      end
      
      def as_method_to_h(free=false)
        # TODO: raise correct error class with enough info for appropriate action
        raise "Wrong frame type for method frame of event: #{self[:frame_type]}" \
          unless self[:frame_type] == :method
        
        payload.to_h(free).merge(channel: self[:channel])
      end
      
      def as_header_to_h(free=false)
        # TODO: raise correct error class with enough info for appropriate action
        raise "Wrong frame type for header frame of multiframe event: #{self[:frame_type]}" \
          unless self[:frame_type] == :header
        
        properties = self[:payload][:properties]
        { header: properties.decoded.to_h(free), body_size: properties[:body_size] }
      end
      
      def as_body_to_s(free=false)
        # TODO: raise correct error class with enough info for appropriate action
        raise "Wrong frame type for body frame of multiframe event: #{self[:frame_type]}" \
          unless self[:frame_type] == :body
        
        self[:payload][:body_fragment].to_s(free)
      end
    end
    
  end
end
