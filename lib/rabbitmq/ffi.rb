
require 'ffi'


module RabbitMQ
  module FFI
    extend ::FFI::Library
    
    def self.available?
      @available
    end
    
    begin
      lib_name = 'librabbitmq'
      lib_paths = ['/usr/local/lib', '/opt/local/lib', '/usr/lib64']
        .map { |path| "#{path}/#{lib_name}.#{::FFI::Platform::LIBSUFFIX}" }
      ffi_lib lib_paths + [lib_name]
      @available = true
    rescue LoadError
      warn ""
      warn "WARNING: #{self} is not available without librabbitmq."
      warn ""
      @available = false
    end
    
    if available?
      opts = {
        blocking: true  # only necessary on MRI to deal with the GIL.
      }
      
      # The following definition is based on library version 0.5.2
      
      attach_function :amqp_version_number, [], :uint32, **opts
      attach_function :amqp_version,        [], :string, **opts
      
      class Boolean
        extend ::FFI::DataConverter
        native_type ::FFI::TypeDefs[:int]
        def self.to_native val, ctx;   val ? 1 : 0; end
        def self.from_native val, ctx; val != 0;    end
      end
      
      MethodNumber = :uint32
      Flags        = :uint32
      Channel      = :uint16
      
      class Bytes < ::FFI::Struct
        layout :len,   :size_t,
               :bytes, :pointer
      end
      
      class Decimal < ::FFI::Struct
        layout :decimals, :uint8,
               :value,    :uint32
      end
      
      class Table < ::FFI::Struct
        layout :num_entries, :int,
               :entries,     :pointer
      end
      
      class Array < ::FFI::Struct
        layout :num_entries, :int,
               :entries,     :pointer
      end
      
      class FieldValueValue < ::FFI::Union
        layout :boolean, Boolean,
               :i8,      :int8,
               :u8,      :uint8,
               :i16,     :int16,
               :u16,     :uint16,
               :i32,     :int32,
               :u32,     :uint32,
               :i64,     :int64,
               :u64,     :uint64,
               :f32,     :float,
               :f64,     :double,
               :decimal, Decimal,
               :bytes,   Bytes,
               :table,   Table,
               :array,   Array
      end
      
      class FieldValue < ::FFI::Struct
        layout :kind,  :uint8,
               :value, FieldValueValue
      end
      
      class TableEntry < ::FFI::Struct
        layout :key,   Bytes,
               :value, FieldValue
      end
      
      FieldValueKindEnum = enum [
        :boolean,   't'.ord,
        :i8,        'b'.ord,
        :u8,        'B'.ord,
        :i16,       's'.ord,
        :u16,       'u'.ord,
        :i32,       'I'.ord,
        :u32,       'i'.ord,
        :i64,       'l'.ord,
        :u64,       'L'.ord,
        :f32,       'f'.ord,
        :f64,       'd'.ord,
        :decimal,   'D'.ord,
        :utf8,      'S'.ord,
        :array,     'A'.ord,
        :timestamp, 'T'.ord,
        :table,     'F'.ord,
        :void,      'V'.ord,
        :bytes,     'x'.ord,
      ]
      
      class PoolBlocklist < ::FFI::Struct
        layout :num_blocks, :int,
               :blocklist,  :pointer
      end
      
      class Pool < ::FFI::Struct
        layout :pagesize,     :size_t,
               :pages,        PoolBlocklist,
               :large_blocks, PoolBlocklist,
               :next_pages,   :int,
               :alloc_block,  :pointer,
               :alloc_used,   :size_t
      end
      
      class Method < ::FFI::Struct
        layout :id,      MethodNumber,
               :decoded, :pointer
      end
      
      class FramePayloadProperties < ::FFI::Struct
        layout :class_id,  :uint16,
               :body_size, :uint64,
               :decoded,   :pointer,
               :raw,       Bytes
      end
      
      class FramePayloadProtocolHeader < ::FFI::Struct
        layout :transport_high,         :uint8,
               :transport_low,          :uint8,
               :protocol_version_major, :uint8,
               :protocol_version_minor, :uint8
      end
      
      class FramePayload < ::FFI::Union
        layout :method,          Method,
               :properties,      FramePayloadProperties,
               :body_fragment,   Bytes,
               :protocol_header, FramePayloadProtocolHeader
      end
      
      class Frame < ::FFI::Union
        layout :frame_type, :uint8,
               :channel,    Channel,
               :payload,    FramePayload
      end
      
      ResponseTypeEnum = enum [
        :none, 0,
        :normal,
        :library_exception,
        :server_exception,
      ]
      
      class RpcReply < ::FFI::Struct
        layout :reply_type,    ResponseTypeEnum,
               :reply,         Method,
               :library_error, :int
      end
      
      SaslMethodEnum = enum [
        :plain, 0,
      ]
      
      ConnectionState = :pointer
      
      StatusEnum = enum [
        :ok,                          0x0,
        :no_memory,                  -0x0001,
        :bad_amqp_data,              -0x0002,
        :unknown_class,              -0x0003,
        :unknown_method,             -0x0004,
        :hostname_resolution_failed, -0x0005,
        :incompatible_amqp_version,  -0x0006,
        :connection_closed,          -0x0007,
        :bad_url,                    -0x0008,
        :socket_error,               -0x0009,
        :invalid_parameter,          -0x000A,
        :table_too_big,              -0x000B,
        :wrong_method,               -0x000C,
        :timeout,                    -0x000D,
        :timer_failure,              -0x000E,
        :heartbeat_timeout,          -0x000F,
        :unexpected_state,           -0x0010,
        :tcp_error,                  -0x0100,
        :tcp_socketlib_init_error,   -0x0101,
        :ssl_error,                  -0x0200,
        :ssl_hostname_verify_failed, -0x0201,
        :ssl_peer_verify_failed,     -0x0202,
        :ssl_connection_failed,      -0x0203,
      ]
      
      DeliveryModeEnum = enum [
        :nonpersistent, 1,
        :persistent,    2,
      ]
      
      attach_function :amqp_constant_name,          [:int], :string, **opts
      attach_function :amqp_constant_is_hard_error, [:int], Boolean, **opts
      
      attach_function :amqp_method_name,        [MethodNumber],                            :string, **opts
      attach_function :amqp_method_has_content, [MethodNumber],                            Boolean, **opts
      attach_function :amqp_decode_method,      [MethodNumber, :pointer, Bytes, :pointer], :int,    **opts
      attach_function :amqp_decode_properties,  [:uint16, :pointer, Bytes, :pointer],      :int,    **opts
      attach_function :amqp_encode_method,      [MethodNumber, :pointer, Bytes],           :int,    **opts
      attach_function :amqp_encode_properties,  [:uint16, :pointer, Bytes],                :int,    **opts
      
      class ConnectionStart < ::FFI::Struct
        layout :version_major,     :uint8,
               :version_minor,     :uint8,
               :server_properties, Table,
               :mechanisms,        Bytes,
               :locales,           Bytes
      end
      
      class ConnectionStartOk < ::FFI::Struct
        layout :client_properties, Table,
               :mechanism,         Bytes,
               :response,          Bytes,
               :locale,            Bytes
      end
      
      class ConnectionSecure < ::FFI::Struct
        layout :challenge, Bytes
      end
      
      class ConnectionSecureOk < ::FFI::Struct
        layout :response, Bytes
      end
      
      class ConnectionTune < ::FFI::Struct
        layout :channel_max, :uint16,
               :frame_max,   :uint32,
               :heartbeat,   :uint16
      end
      
      class ConnectionTuneOk < ::FFI::Struct
        layout :channel_max, :uint16,
               :frame_max,   :uint32,
               :heartbeat,   :uint16
      end
      
      class ConnectionOpen < ::FFI::Struct
        layout :virtual_host, Bytes,
               :capabilities, Bytes,
               :insist,       Boolean
      end
      
      class ConnectionOpenOk < ::FFI::Struct
        layout :known_hosts, Bytes
      end
      
      class ConnectionClose < ::FFI::Struct
        layout :reply_code, :uint16,
               :reply_text, Bytes,
               :class_id,   :uint16,
               :method_id,  :uint16
      end
      
      class ConnectionCloseOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ConnectionBlocked < ::FFI::Struct
        layout :reason, Bytes
      end
      
      class ConnectionUnblocked < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ChannelOpen < ::FFI::Struct
        layout :out_of_band, Bytes
      end
      
      class ChannelOpenOk < ::FFI::Struct
        layout :channel_id, Bytes
      end
      
      class ChannelFlow < ::FFI::Struct
        layout :active, Boolean
      end
      
      class ChannelFlowOk < ::FFI::Struct
        layout :active, Boolean
      end
      
      class ChannelClose < ::FFI::Struct
        layout :reply_code, :uint16,
               :reply_text, Bytes,
               :class_id,   :uint16,
               :method_i,   :uint16
      end
      
      class ChannelCloseOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class AccessRequest < ::FFI::Struct
        layout :realm,     Bytes,
               :exclusive, Boolean,
               :passive,   Boolean,
               :active,    Boolean,
               :write,     Boolean,
               :read,      Boolean
      end
      
      class AccessRequestOk < ::FFI::Struct
        layout :ticket, :uint16
      end
      
      class ExchangeDeclare < ::FFI::Struct
        layout :ticket,      :uint16,
               :exchange,    Bytes,
               :type,        Bytes,
               :passive,     Boolean,
               :durable,     Boolean,
               :auto_delete, Boolean,
               :internal,    Boolean,
               :nowait,      Boolean,
               :arguments,   Bytes
      end
      
      class ExchangeDeclareOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ExchangeDelete < ::FFI::Struct
        layout :ticket,    :uint16,
               :exchange,  Bytes,
               :if_unused, Boolean,
               :nowait,    Boolean
      end
      
      class ExchangeDeleteOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ExchangeBind < ::FFI::Struct
        layout :ticket,      :uint16,
               :destination, Bytes,
               :source,      Bytes,
               :routing_key, Bytes,
               :nowait,      Boolean,
               :arguments,   Bytes
      end
      
      class ExchangeBindOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ExchangeUnbind < ::FFI::Struct
        layout :ticket,      :uint16,
               :destination, Bytes,
               :source,      Bytes,
               :routing_key, Bytes,
               :nowait,      Boolean,
               :arguments,   Bytes
      end
      
      class ExchangeUnbindOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class QueueDeclare < ::FFI::Struct
        layout :ticket,      :uint16,
               :queue,       Bytes,
               :passive,     Boolean,
               :durable,     Boolean,
               :exclusive,   Boolean,
               :auto_delete, Boolean,
               :nowait,      Boolean,
               :arguments,   Bytes
      end
      
      class QueueDeclareOk < ::FFI::Struct
        layout :queue,          Bytes,
               :message_count,  :uint32,
               :consumer_count, :uint32
      end
      
      class QueueBind < ::FFI::Struct
        layout :ticket,      :uint16,
               :queue,       Bytes,
               :exchange,    Bytes,
               :routing_key, Bytes,
               :nowait,      Boolean,
               :arguments,   Bytes
      end
      
      class QueueBindOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class QueuePurge < ::FFI::Struct
        layout :ticket, :uint16,
               :queue,  Bytes,
               :nowait, Boolean
      end
      
      class QueuePurgeOk < ::FFI::Struct
        layout :message_count, :uint32
      end
      
      class QueueDelete < ::FFI::Struct
        layout :ticket,    :uint16,
               :queue,     Bytes,
               :if_unused, Boolean,
               :if_empty,  Boolean,
               :nowait,    Boolean
      end
      
      class QueueDeleteOk < ::FFI::Struct
        layout :message_count, :uint32
      end
      
      class QueueUnbind < ::FFI::Struct
        layout :ticket,      :uint16,
               :queue,       Bytes,
               :exchange,    Bytes,
               :routing_key, Bytes,
               :arguments,   Bytes
      end
      
      class QueueUnbindOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class BasicQos < ::FFI::Struct
        layout :prefetch_size,  :uint32,
               :prefetch_count, :uint16,
               :global,         Boolean
      end
      
      class BasicQosOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class BasicConsume < ::FFI::Struct
        layout :ticket,       :uint16,
               :queue,        Bytes,
               :consumer_tag, Bytes,
               :no_local,     Boolean,
               :no_ack,       Boolean,
               :exclusive,    Boolean,
               :nowait,       Boolean,
               :arguments,    Bytes
      end
      
      class BasicConsumeOk < ::FFI::Struct
        layout :consumer_tag, Bytes
      end
      
      class BasicCancel < ::FFI::Struct
        layout :consumer_tag, Bytes,
               :nowait,       Boolean
      end
      
      class BasicCancelOk < ::FFI::Struct
        layout :consumer_tag, Bytes
      end
      
      class BasicPublish < ::FFI::Struct
        layout :ticket,      :uint16,
               :exchange,    Bytes,
               :routing_key, Bytes,
               :mandatory,   Boolean,
               :immediate,   Boolean
      end
      
      class BasicReturn < ::FFI::Struct
        layout :reply_code,  :uint16,
               :reply_text,  Bytes,
               :exchange,    Bytes,
               :routing_key, Bytes
      end
      
      class BasicDeliver < ::FFI::Struct
        layout :consumer_tag, Bytes,
               :delivery_tag, :uint64,
               :redelivered,  Boolean,
               :exchange,     Bytes,
               :routing_key,  Bytes
      end
      
      class BasicGet < ::FFI::Struct
        layout :ticket, :uint16,
               :queue,  Bytes,
               :no_ack, Boolean
      end
      
      class BasicGetOk < ::FFI::Struct
        layout :delivery_tag,  :uint64,
               :redelivered,   Boolean,
               :exchange,      Bytes,
               :routing_key,   Bytes,
               :message_count, :uint32
      end
      
      class BasicGetEmpty < ::FFI::Struct
        layout :cluster_id, Bytes
      end
      
      class BasicAck < ::FFI::Struct
        layout :delivery_tag, :uint64,
               :multiple,     Boolean
      end
      
      class BasicReject < ::FFI::Struct
        layout :delivery_tag, :uint64,
               :requeue,      Boolean
      end
      
      class BasicRecoverAsync < ::FFI::Struct
        layout :requeue, Boolean
      end
      
      class BasicRecover < ::FFI::Struct
        layout :requeue, Boolean
      end
      
      class BasicRecoverOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class BasicNack < ::FFI::Struct
        layout :delivery_tag, :uint64,
               :multiple, Boolean,
               :requeue, Boolean
      end
      
      class TxSelect < ::FFI::Struct
        layout :dummy, :char
      end
      
      class TxSelectOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class TxCommit < ::FFI::Struct
        layout :dummy, :char
      end
      
      class TxCommitOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class TxRollback < ::FFI::Struct
        layout :dummy, :char
      end
      
      class TxRollbackOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ConfirmSelect < ::FFI::Struct
        layout :nowait, Boolean
      end
      
      class ConfirmSelectOk < ::FFI::Struct
        layout :dummy, :char
      end
      
      class ConnectionProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end

      class ChannelProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end

      class AccessProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end

      class ExchangeProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end

      class QueueProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end
      
      class TxProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end
      
      class ExchangeProperties < ::FFI::Struct
        layout :flags, Flags,
               :dummy, :char
      end
      
      class BasicProperties < ::FFI::Struct
        layout :_flags,           Flags,
               :content_type,     Bytes,
               :content_encoding, Bytes,
               :headers,          Table,
               :delivery_mode,    :uint8,
               :priority,         :uint8,
               :correlation_id,   Bytes,
               :reply_to,         Bytes,
               :expiration,       Bytes,
               :message_id,       Bytes,
               :timestamp,        :uint64,
               :type,             Bytes,
               :user_id,          Bytes,
               :app_id,           Bytes,
               :cluster_id,       Bytes
      end
      
      attach_function :amqp_channel_open,     [ConnectionState, Channel],                                                   :pointer, **opts
      attach_function :amqp_channel_flow,     [ConnectionState, Channel, Boolean],                                          :pointer, **opts
      attach_function :amqp_exchange_declare, [ConnectionState, Channel, Bytes, Bytes, Boolean, Boolean, Table],            :pointer, **opts
      attach_function :amqp_exchange_delete,  [ConnectionState, Channel, Bytes, Boolean],                                   :pointer, **opts
      attach_function :amqp_exchange_bind,    [ConnectionState, Channel, Bytes, Bytes, Bytes, Table],                       :pointer, **opts
      attach_function :amqp_exchange_unbind,  [ConnectionState, Channel, Bytes, Bytes, Bytes, Table],                       :pointer, **opts
      attach_function :amqp_queue_declare,    [ConnectionState, Channel, Bytes, Boolean, Boolean, Boolean, Boolean, Table], :pointer, **opts
      attach_function :amqp_queue_bind,       [ConnectionState, Channel, Bytes, Bytes, Bytes, Table],                       :pointer, **opts
      attach_function :amqp_queue_purge,      [ConnectionState, Channel, Bytes],                                            :pointer, **opts
      attach_function :amqp_queue_delete,     [ConnectionState, Channel, Bytes, Boolean, Boolean],                          :pointer, **opts
      attach_function :amqp_queue_unbind,     [ConnectionState, Channel, Bytes, Bytes, Bytes, Table],                       :pointer, **opts
      attach_function :amqp_basic_qos,        [ConnectionState, Channel, :uint32, :uint16, Boolean],                        :pointer, **opts
      attach_function :amqp_basic_consume,    [ConnectionState, Channel, Bytes, Bytes, Boolean, Boolean, Boolean, Table],   :pointer, **opts
      attach_function :amqp_basic_cancel,     [ConnectionState, Channel, Bytes],                                            :pointer, **opts
      attach_function :amqp_basic_recover,    [ConnectionState, Channel, Boolean],                                          :pointer, **opts
      attach_function :amqp_tx_select,        [ConnectionState, Channel],                                                   :pointer, **opts
      attach_function :amqp_tx_commit,        [ConnectionState, Channel],                                                   :pointer, **opts
      attach_function :amqp_tx_rollback,      [ConnectionState, Channel],                                                   :pointer, **opts
      attach_function :amqp_confirm_select,   [ConnectionState, Channel],                                                   :pointer, **opts
      
      attach_function :init_amqp_pool,        [:pointer, :size_t],           :void,    **opts
      attach_function :recycle_amqp_pool,     [:pointer],                    :void,    **opts
      attach_function :empty_amqp_pool,       [:pointer],                    :void,    **opts
      attach_function :amqp_pool_alloc,       [:pointer, :size_t],           :pointer, **opts
      attach_function :amqp_pool_alloc_bytes, [:pointer, :size_t, :pointer], :void,    **opts
      
      attach_function :amqp_cstring_bytes,    [:string], Bytes, **opts
      attach_function :amqp_bytes_malloc_dup, [Bytes],   Bytes, **opts
      attach_function :amqp_bytes_malloc,     [:size_t], Bytes, **opts
      attach_function :amqp_bytes_free,       [Bytes],   :void, **opts
      
      attach_function :amqp_new_connection, [], ConnectionState, **opts
      attach_function :amqp_get_sockfd,         [ConnectionState],                   :int,  **opts
      attach_function :amqp_set_sockfd,         [ConnectionState, :int],             :void, **opts
      attach_function :amqp_tune_connection,    [ConnectionState, :int, :int, :int], :int,  **opts
      attach_function :amqp_get_channel_max,    [ConnectionState],                   :int,  **opts
      attach_function :amqp_destroy_connection, [ConnectionState],                   :int,  **opts
      
      attach_function :amqp_handle_input,                     [ConnectionState, Bytes, :pointer], :int,    **opts
      attach_function :amqp_release_buffers_ok,               [ConnectionState],                  Boolean, **opts
      attach_function :amqp_release_buffers,                  [ConnectionState],                  :void,   **opts
      attach_function :amqp_maybe_release_buffers,            [ConnectionState],                  :void,   **opts
      attach_function :amqp_maybe_release_buffers_on_channel, [ConnectionState, Channel],         :void,   **opts
      attach_function :amqp_send_frame,                       [ConnectionState, :pointer],        :int,    **opts
      
      attach_function :amqp_table_entry_cmp, [:pointer, :pointer], :int, **opts
      attach_function :amqp_open_socket,     [:string, :int],      :int, **opts
      
      attach_function :amqp_send_header,               [ConnectionState],                                  :int,    **opts
      attach_function :amqp_frames_enqueued,           [ConnectionState],                                  Boolean, **opts
      attach_function :amqp_simple_wait_frame,         [ConnectionState, :pointer],                        :int,    **opts
      attach_function :amqp_simple_wait_frame_noblock, [ConnectionState, :pointer, :pointer],              :int,    **opts
      attach_function :amqp_simple_wait_method,        [ConnectionState, Channel, MethodNumber, :pointer], :int,    **opts
      attach_function :amqp_send_method,               [ConnectionState, Channel, MethodNumber, :pointer], :int,    **opts
      
      attach_function :amqp_simple_rpc,            [ConnectionState, Channel, MethodNumber, :pointer, :pointer],           RpcReply, **opts
      attach_function :amqp_simple_rpc_decoded,    [ConnectionState, Channel, MethodNumber, MethodNumber, :pointer],       :pointer, **opts
      attach_function :amqp_get_rpc_reply,         [ConnectionState],                                                      RpcReply, **opts
      attach_function :amqp_login,                 [ConnectionState, :string, :int, :int, :int, SaslMethodEnum],           RpcReply, **opts
      attach_function :amqp_login_with_properties, [ConnectionState, :string, :int, :int, :int, :pointer, SaslMethodEnum], RpcReply, **opts
      attach_function :amqp_channel_close,         [ConnectionState, Channel, :int],                                       RpcReply, **opts
      attach_function :amqp_connection_close,      [ConnectionState, :int],                                                RpcReply, **opts
      
      attach_function :amqp_basic_publish, [ConnectionState, Channel, Bytes, Bytes, Boolean, Boolean, :pointer, Bytes], :int, **opts
      attach_function :amqp_basic_ack,     [ConnectionState, Channel, :uint64, Boolean],                                :int, **opts
      attach_function :amqp_basic_get,     [ConnectionState, Channel, Bytes, Boolean],                                  :int, **opts
      attach_function :amqp_basic_reject,  [ConnectionState, Channel, :uint64, Boolean],                                :int, **opts
      attach_function :amqp_basic_nack,    [ConnectionState, Channel, :uint64, Boolean, Boolean],                       :int, **opts
      
      attach_function :amqp_data_in_buffer, [ConnectionState], Boolean, **opts
      
      attach_function :amqp_error_string,  [:int], :string, **opts
      attach_function :amqp_error_string2, [:int], :string, **opts
      
      attach_function :amqp_decode_table, [Bytes, :pointer, :pointer, :pointer], :int, **opts
      attach_function :amqp_encode_table, [Bytes, :pointer, :pointer],           :int, **opts
      attach_function :amqp_table_clone,  [:pointer, :pointer, :pointer],        :int, **opts
      
      class Message < ::FFI::Struct
        layout :properties, BasicProperties,
               :body,       Bytes,
               :pool,       Pool
      end
      
      attach_function :amqp_read_message,    [ConnectionState, Channel, :pointer, :int], RpcReply, **opts
      attach_function :amqp_destroy_message, [:pointer],                                 :void,    **opts
      
      class Envelope < ::FFI::Struct
        layout :channel,      Channel,
               :consumer_tag, Bytes,
               :delivery_tag, :uint64,
               :redelivered,  Boolean,
               :exchange,     Bytes,
               :routing_key,  Bytes,
               :message,      Message
      end
      
      attach_function :amqp_consume_message,  [ConnectionState, :pointer, :pointer, :int], RpcReply, **opts
      attach_function :amqp_destroy_envelope, [:pointer],                                  :void,    **opts
      
      class ConnectionInfo < ::FFI::Struct
        layout :user,     :string,
               :password, :string,
               :host,     :string,
               :vhost,    :string,
               :port,     :int,
               :ssl,      Boolean
      end
      
      attach_function :amqp_default_connection_info, [:pointer],                          :void,    **opts
      attach_function :amqp_parse_url,               [:string, :pointer],                 :int,     **opts
      attach_function :amqp_socket_open,             [:pointer, :string, :int],           :int,     **opts
      attach_function :amqp_socket_open_noblock,     [:pointer, :string, :int, :pointer], :int,     **opts
      attach_function :amqp_socket_get_sockfd,       [:pointer],                          :int,     **opts
      attach_function :amqp_get_socket,              [ConnectionState],                   :pointer, **opts
      attach_function :amqp_get_server_properties,   [ConnectionState],                   Table,    **opts
    end
  end
end
