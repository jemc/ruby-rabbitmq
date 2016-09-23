
require 'ffi'


module RabbitMQ
  
  # Bindings and wrappers for the native functions and structures exposed by
  # the librabbitmq C library. This module is for internal use only so that
  # all dependencies on the implementation of the C library are abstracted.
  # @api private
  module FFI
    extend ::FFI::Library
    
    libfile = "librabbitmq.#{::FFI::Platform::LIBSUFFIX}"
    
    ffi_lib ::FFI::Library::LIBC
    ffi_lib \
      File.expand_path("../../ext/rabbitmq/#{libfile}", File.dirname(__FILE__))
    
    opts = {
      blocking: true  # only necessary on MRI to deal with the GIL.
    }
    
    attach_function :free,   [:pointer], :void,    **opts
    attach_function :malloc, [:size_t],  :pointer, **opts
    
    attach_function :amqp_version_number, [], :uint32, **opts
    attach_function :amqp_version,        [], :string, **opts
    
    Status = enum ::FFI::TypeDefs[:int], [
      :ok,                              0x0,
      :no_memory,                      -0x0001,
      :bad_amqp_data,                  -0x0002,
      :unknown_class,                  -0x0003,
      :unknown_method,                 -0x0004,
      :hostname_resolution_failed,     -0x0005,
      :incompatible_amqp_version,      -0x0006,
      :connection_closed,              -0x0007,
      :bad_url,                        -0x0008,
      :socket_error,                   -0x0009,
      :invalid_parameter,              -0x000A,
      :table_too_big,                  -0x000B,
      :wrong_method,                   -0x000C,
      :timeout,                        -0x000D,
      :timer_failure,                  -0x000E,
      :heartbeat_timeout,              -0x000F,
      :unexpected_state,               -0x0010,
      :unexpected_socket_closed,       -0x0011,
      :unexpected_socket_inuse,        -0x0012,
      :broker_unsupported_sasl_method, -0x0013,
      :status_unsupported,             -0x0014,
      :tcp_error,                      -0x0100,
      :tcp_socketlib_init_error,       -0x0101,
      :ssl_error,                      -0x0200,
      :ssl_hostname_verify_failed,     -0x0201,
      :ssl_peer_verify_failed,         -0x0202,
      :ssl_connection_failed,          -0x0203,
    ]
    
    DeliveryMode = enum ::FFI::TypeDefs[:uint8], [
      :nonpersistent, 1,
      :persistent,    2,
    ]
    
    class Timeval < ::FFI::Struct
      layout :tv_sec,  :time_t,
             :tv_usec, :suseconds_t
    end
    
    class Boolean
      extend ::FFI::DataConverter
      native_type ::FFI::TypeDefs[:int]
      def self.to_native val, ctx;   val ? 1 : 0; end
      def self.from_native val, ctx; val != 0;    end
    end
    
    MethodNumber = enum ::FFI::TypeDefs[:uint32], [
      :connection_start,     0x000A000A, # 10, 10; 655370
      :connection_start_ok,  0x000A000B, # 10, 11; 655371
      :connection_secure,    0x000A0014, # 10, 20; 655380
      :connection_secure_ok, 0x000A0015, # 10, 21; 655381
      :connection_tune,      0x000A001E, # 10, 30; 655390
      :connection_tune_ok,   0x000A001F, # 10, 31; 655391
      :connection_open,      0x000A0028, # 10, 40; 655400
      :connection_open_ok,   0x000A0029, # 10, 41; 655401
      :connection_close,     0x000A0032, # 10, 50; 655410
      :connection_close_ok,  0x000A0033, # 10, 51; 655411
      :connection_blocked,   0x000A003C, # 10, 60; 655420
      :connection_unblocked, 0x000A003D, # 10, 61; 655421
      :channel_open,         0x0014000A, # 20, 10; 1310730
      :channel_open_ok,      0x0014000B, # 20, 11; 1310731
      :channel_flow,         0x00140014, # 20, 20; 1310740
      :channel_flow_ok,      0x00140015, # 20, 21; 1310741
      :channel_close,        0x00140028, # 20, 40; 1310760
      :channel_close_ok,     0x00140029, # 20, 41; 1310761
      :access_request,       0x001E000A, # 30, 10; 1966090
      :access_request_ok,    0x001E000B, # 30, 11; 1966091
      :exchange_declare,     0x0028000A, # 40, 10; 2621450
      :exchange_declare_ok,  0x0028000B, # 40, 11; 2621451
      :exchange_delete,      0x00280014, # 40, 20; 2621460
      :exchange_delete_ok,   0x00280015, # 40, 21; 2621461
      :exchange_bind,        0x0028001E, # 40, 30; 2621470
      :exchange_bind_ok,     0x0028001F, # 40, 31; 2621471
      :exchange_unbind,      0x00280028, # 40, 40; 2621480
      :exchange_unbind_ok,   0x00280033, # 40, 51; 2621491
      :queue_declare,        0x0032000A, # 50, 10; 3276810
      :queue_declare_ok,     0x0032000B, # 50, 11; 3276811
      :queue_bind,           0x00320014, # 50, 20; 3276820
      :queue_bind_ok,        0x00320015, # 50, 21; 3276821
      :queue_purge,          0x0032001E, # 50, 30; 3276830
      :queue_purge_ok,       0x0032001F, # 50, 31; 3276831
      :queue_delete,         0x00320028, # 50, 40; 3276840
      :queue_delete_ok,      0x00320029, # 50, 41; 3276841
      :queue_unbind,         0x00320032, # 50, 50; 3276850
      :queue_unbind_ok,      0x00320033, # 50, 51; 3276851
      :basic_qos,            0x003C000A, # 60, 10; 3932170
      :basic_qos_ok,         0x003C000B, # 60, 11; 3932171
      :basic_consume,        0x003C0014, # 60, 20; 3932180
      :basic_consume_ok,     0x003C0015, # 60, 21; 3932181
      :basic_cancel,         0x003C001E, # 60, 30; 3932190
      :basic_cancel_ok,      0x003C001F, # 60, 31; 3932191
      :basic_publish,        0x003C0028, # 60, 40; 3932200
      :basic_return,         0x003C0032, # 60, 50; 3932210
      :basic_deliver,        0x003C003C, # 60, 60; 3932220
      :basic_get,            0x003C0046, # 60, 70; 3932230
      :basic_get_ok,         0x003C0047, # 60, 71; 3932231
      :basic_get_empty,      0x003C0048, # 60, 72; 3932232
      :basic_ack,            0x003C0050, # 60, 80; 3932240
      :basic_reject,         0x003C005A, # 60, 90; 3932250
      :basic_recover_async,  0x003C0064, # 60, 100; 3932260
      :basic_recover,        0x003C006E, # 60, 110; 3932270
      :basic_recover_ok,     0x003C006F, # 60, 111; 3932271
      :basic_nack,           0x003C0078, # 60, 120; 3932280
      :tx_select,            0x005A000A, # 90, 10; 5898250
      :tx_select_ok,         0x005A000B, # 90, 11; 5898251
      :tx_commit,            0x005A0014, # 90, 20; 5898260
      :tx_commit_ok,         0x005A0015, # 90, 21; 5898261
      :tx_rollback,          0x005A001E, # 90, 30; 5898270
      :tx_rollback_ok,       0x005A001F, # 90, 31; 5898271
      :confirm_select,       0x0055000A, # 85, 10; 5570570
      :confirm_select_ok,    0x0055000B, # 85, 11; 5570571
    ]
    
    Flags = :uint32
    
    Channel = ::FFI::TypeDefs[:uint16]
    CHANNEL_MAX_ID = 2 ** (Channel.size * 8) - 1
    
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
    
    FieldValueKind = enum ::FFI::TypeDefs[:uint8], [
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
      layout :kind,  FieldValueKind,
             :value, FieldValueValue
    end
    
    class TableEntry < ::FFI::Struct
      layout :key,   Bytes,
             :value, FieldValue
    end
    
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
    
    FrameType = enum ::FFI::TypeDefs[:uint8], [
      :method,    1,
      :header,    2,
      :body,      3,
      :heartbeat, 8,
    ]
    
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
    
    class Frame < ::FFI::Struct
      layout :frame_type, FrameType,
             :channel,    Channel,
             :payload,    FramePayload
    end
    
    ResponseType = enum [
      :none, 0,
      :normal,
      :library_exception,
      :server_exception,
    ]
    
    class RpcReply < ::FFI::Struct
      layout :reply_type,    ResponseType,
             :reply,         Method,
             :library_error, Status
    end
    
    SaslMethod = enum [
      :undefined, -1,
      :plain,      0,
      :external,   1,
    ]
    
    ConnectionState = :pointer
    
    attach_function :amqp_constant_name,          [:int], :string, **opts
    attach_function :amqp_constant_is_hard_error, [:int], Boolean, **opts
    
    attach_function :amqp_method_name,        [MethodNumber],                                :string, **opts
    attach_function :amqp_method_has_content, [MethodNumber],                                Boolean, **opts
    attach_function :amqp_decode_method,      [MethodNumber, Pool.ptr, Bytes.val, :pointer], Status,  **opts
    attach_function :amqp_decode_properties,  [:uint16, Pool.ptr, Bytes.val, :pointer],      Status,  **opts
    attach_function :amqp_encode_method,      [MethodNumber, :pointer, Bytes.val],           Status,  **opts
    attach_function :amqp_encode_properties,  [:uint16, :pointer, Bytes.val],                Status,  **opts
    
    require_relative 'ffi/gen'
    
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
             :delivery_mode,    DeliveryMode,
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
      
      FLAGS = {
        content_type:     (1 << 15),
        content_encoding: (1 << 14),
        headers:          (1 << 13),
        delivery_mode:    (1 << 12),
        priority:         (1 << 11),
        correlation_id:   (1 << 10),
        reply_to:         (1 << 9),
        expiration:       (1 << 8),
        message_id:       (1 << 7),
        timestamp:        (1 << 6),
        type:             (1 << 5),
        user_id:          (1 << 4),
        app_id:           (1 << 3),
        cluster_id:       (1 << 2),
      }
    end
    
    attach_function :amqp_channel_open,     [ConnectionState, Channel],                                                             ChannelOpenOk.ptr,     **opts
    attach_function :amqp_channel_flow,     [ConnectionState, Channel, Boolean],                                                    ChannelFlowOk.ptr,     **opts
    attach_function :amqp_exchange_declare, [ConnectionState, Channel, Bytes.val, Bytes.val, Boolean, Boolean, Table.val],          ExchangeDeclareOk.ptr, **opts
    attach_function :amqp_exchange_delete,  [ConnectionState, Channel, Bytes.val, Boolean],                                         ExchangeDeleteOk.ptr,  **opts
    attach_function :amqp_exchange_bind,    [ConnectionState, Channel, Bytes.val, Bytes.val, Bytes.val, Table.val],                 ExchangeBindOk.ptr,    **opts
    attach_function :amqp_exchange_unbind,  [ConnectionState, Channel, Bytes.val, Bytes.val, Bytes.val, Table.val],                 ExchangeUnbindOk.ptr,  **opts
    attach_function :amqp_queue_declare,    [ConnectionState, Channel, Bytes.val, Boolean, Boolean, Boolean, Boolean, Table.val],   QueueDeclareOk.ptr,    **opts
    attach_function :amqp_queue_bind,       [ConnectionState, Channel, Bytes.val, Bytes.val, Bytes.val, Table.val],                 QueueBindOk.ptr,       **opts
    attach_function :amqp_queue_purge,      [ConnectionState, Channel, Bytes.val],                                                  QueuePurgeOk.ptr,      **opts
    attach_function :amqp_queue_delete,     [ConnectionState, Channel, Bytes.val, Boolean, Boolean],                                QueueDeleteOk.ptr,     **opts
    attach_function :amqp_queue_unbind,     [ConnectionState, Channel, Bytes.val, Bytes.val, Bytes.val, Table.val],                 QueueUnbindOk.ptr,     **opts
    attach_function :amqp_basic_qos,        [ConnectionState, Channel, :uint32, :uint16, Boolean],                                  BasicQosOk.ptr,        **opts
    attach_function :amqp_basic_consume,    [ConnectionState, Channel, Bytes.val, Bytes.val, Boolean, Boolean, Boolean, Table.val], BasicConsumeOk.ptr,    **opts
    attach_function :amqp_basic_cancel,     [ConnectionState, Channel, Bytes.val],                                                  BasicCancelOk.ptr,     **opts
    attach_function :amqp_basic_recover,    [ConnectionState, Channel, Boolean],                                                    BasicRecoverOk.ptr,    **opts
    attach_function :amqp_tx_select,        [ConnectionState, Channel],                                                             TxSelect.ptr,          **opts
    attach_function :amqp_tx_commit,        [ConnectionState, Channel],                                                             TxCommit.ptr,          **opts
    attach_function :amqp_tx_rollback,      [ConnectionState, Channel],                                                             TxRollback.ptr,        **opts
    attach_function :amqp_confirm_select,   [ConnectionState, Channel],                                                             ConfirmSelect.ptr,     **opts
    
    attach_function :init_amqp_pool,        [Pool.ptr, :size_t],            :void,    **opts
    attach_function :recycle_amqp_pool,     [Pool.ptr],                     :void,    **opts
    attach_function :empty_amqp_pool,       [Pool.ptr],                     :void,    **opts
    attach_function :amqp_pool_alloc,       [Pool.ptr, :size_t],            :pointer, **opts
    attach_function :amqp_pool_alloc_bytes, [Pool.ptr, :size_t, Bytes.ptr], :void,    **opts
    
    attach_function :amqp_cstring_bytes,    [:string],     Bytes.val, **opts
    attach_function :amqp_bytes_malloc_dup, [Bytes.val],   Bytes.val, **opts
    attach_function :amqp_bytes_malloc,     [:size_t],     Bytes.val, **opts
    attach_function :amqp_bytes_free,       [Bytes.val],   :void,     **opts
    
    attach_function :amqp_new_connection, [], ConnectionState, **opts
    attach_function :amqp_get_sockfd,         [ConnectionState],                   :int,   **opts
    attach_function :amqp_set_sockfd,         [ConnectionState, :int],             :void,  **opts
    attach_function :amqp_tune_connection,    [ConnectionState, :int, :int, :int], Status, **opts
    attach_function :amqp_get_channel_max,    [ConnectionState],                   :int,   **opts
    attach_function :amqp_get_frame_max,      [ConnectionState],                   :int,   **opts
    attach_function :amqp_get_heartbeat,      [ConnectionState],                   :int,   **opts
    attach_function :amqp_destroy_connection, [ConnectionState],                   Status, **opts
    
    attach_function :amqp_handle_input,                     [ConnectionState, Bytes.val, Frame.ptr], Status,  **opts
    attach_function :amqp_release_buffers_ok,               [ConnectionState],                       Boolean, **opts
    attach_function :amqp_release_buffers,                  [ConnectionState],                       :void,   **opts
    attach_function :amqp_maybe_release_buffers,            [ConnectionState],                       :void,   **opts
    attach_function :amqp_maybe_release_buffers_on_channel, [ConnectionState, Channel],              :void,   **opts
    attach_function :amqp_send_frame,                       [ConnectionState, Frame.ptr],            Status,  **opts
    
    attach_function :amqp_table_entry_cmp, [:pointer, :pointer], :int, **opts
    
    attach_function :amqp_open_socket, [:string, :int], Status, **opts
    
    attach_function :amqp_send_header,               [ConnectionState],                                    Status,  **opts
    attach_function :amqp_frames_enqueued,           [ConnectionState],                                    Boolean, **opts
    attach_function :amqp_simple_wait_frame,         [ConnectionState, Frame.ptr],                         Status,  **opts
    attach_function :amqp_simple_wait_frame_noblock, [ConnectionState, Frame.ptr, Timeval.ptr],            Status,  **opts
    attach_function :amqp_simple_wait_method,        [ConnectionState, Channel, MethodNumber, Method.ptr], Status,  **opts
    attach_function :amqp_send_method,               [ConnectionState, Channel, MethodNumber, :pointer],   Status,  **opts
    
    attach_function :amqp_simple_rpc,            [ConnectionState, Channel, MethodNumber, :pointer, :pointer],                  RpcReply.val, **opts
    attach_function :amqp_simple_rpc_decoded,    [ConnectionState, Channel, MethodNumber, MethodNumber, :pointer],              :pointer,     **opts
    attach_function :amqp_get_rpc_reply,         [ConnectionState],                                                             RpcReply.val, **opts
    attach_function :amqp_login,                 [ConnectionState, :string, :int, :int, :int, SaslMethod, :varargs],            RpcReply.val, **opts
    attach_function :amqp_login_with_properties, [ConnectionState, :string, :int, :int, :int, Table.ptr, SaslMethod, :varargs], RpcReply.val, **opts
    attach_function :amqp_channel_close,         [ConnectionState, Channel, :int],                                              RpcReply.val, **opts
    attach_function :amqp_connection_close,      [ConnectionState, :int],                                                       RpcReply.val, **opts
    
    attach_function :amqp_basic_publish, [ConnectionState, Channel, Bytes.val, Bytes.val, Boolean, Boolean, BasicProperties.ptr, Bytes.val], Status, **opts
    
    attach_function :amqp_basic_get,     [ConnectionState, Channel, Bytes.val, Boolean],        Status, **opts
    attach_function :amqp_basic_ack,     [ConnectionState, Channel, :uint64, Boolean],          Status, **opts
    attach_function :amqp_basic_reject,  [ConnectionState, Channel, :uint64, Boolean],          Status, **opts
    attach_function :amqp_basic_nack,    [ConnectionState, Channel, :uint64, Boolean, Boolean], Status, **opts
    
    attach_function :amqp_data_in_buffer, [ConnectionState], Boolean, **opts
    
    attach_function :amqp_error_string,  [:int], :string, **opts
    attach_function :amqp_error_string2, [:int], :string, **opts
    
    attach_function :amqp_decode_table, [Bytes.val, Pool.ptr, Table.ptr, :pointer], Status, **opts
    attach_function :amqp_encode_table, [Bytes.val, Table.ptr, :pointer],           Status, **opts
    attach_function :amqp_table_clone,  [Table.ptr, Table.ptr, Pool.ptr],       Status, **opts
    
    class Message < ::FFI::Struct
      layout :properties, BasicProperties,
             :body,       Bytes,
             :pool,       Pool
    end
    
    attach_function :amqp_read_message,    [ConnectionState, Channel, Message.ptr, :int], RpcReply.val, **opts
    attach_function :amqp_destroy_message, [Message.ptr],                                 :void,        **opts
    
    class Envelope < ::FFI::Struct
      layout :channel,      Channel,
             :consumer_tag, Bytes,
             :delivery_tag, :uint64,
             :redelivered,  Boolean,
             :exchange,     Bytes,
             :routing_key,  Bytes,
             :message,      Message
    end
    
    attach_function :amqp_consume_message,  [ConnectionState, Envelope.ptr, Timeval.ptr, :int], RpcReply.val, **opts
    attach_function :amqp_destroy_envelope, [Envelope.ptr],                                     :void,        **opts
    
    class ConnectionInfo < ::FFI::Struct
      layout :user,     :string,
             :password, :string,
             :host,     :string,
             :vhost,    :string,
             :port,     :int,
             :ssl,      Boolean
    end
    
    attach_function :amqp_default_connection_info, [ConnectionInfo.ptr],                   :void,    **opts
    attach_function :amqp_parse_url,               [:pointer, ConnectionInfo.ptr],         Status,   **opts
    attach_function :amqp_socket_open,             [:pointer, :string, :int],              Status,   **opts
    attach_function :amqp_socket_open_noblock,     [:pointer, :string, :int, Timeval.ptr], Status,   **opts
    attach_function :amqp_socket_get_sockfd,       [:pointer],                             :int,     **opts
    attach_function :amqp_get_socket,              [ConnectionState],                      :pointer, **opts
    attach_function :amqp_get_server_properties,   [ConnectionState],                      Table,    **opts
    attach_function :amqp_get_client_properties,   [ConnectionState],                      Table,    **opts
    
    attach_function :amqp_tcp_socket_new,        [ConnectionState], :pointer, **opts
    attach_function :amqp_tcp_socket_set_sockfd, [:pointer, :int],  :void,    **opts
    
    begin # SSL support is optional
      attach_function :amqp_ssl_socket_new,             [ConnectionState],                      :pointer, **opts
      attach_function :amqp_ssl_socket_set_cacert,      [:pointer, :string],                    Status,   **opts
      attach_function :amqp_ssl_socket_set_key,         [:pointer, :string, :string],           Status,   **opts
      attach_function :amqp_ssl_socket_set_key_buffer,  [:pointer, :string, :pointer, :size_t], Status,   **opts
      attach_function :amqp_ssl_socket_set_verify,      [:pointer, Boolean],                    :void,    **opts
      attach_function :amqp_set_initialize_ssl_library, [Boolean],                              :void,    **opts
      @has_ssl = true
    rescue LoadError
      @has_ssl = false
    end
    def self.has_ssl?; @has_ssl; end
  end
end
