
require 'fileutils'

require_relative 'ffi/method.rb'

framing_header = "../ext/rabbitmq/rabbitmq-c/librabbitmq/amqp_framing.h"
framing_header = File.expand_path(framing_header, File.dirname(__FILE__))

methods = CodeGen::FFI::Method.list_from_c_header(framing_header)
methods.each(&:generate_file!)

ffi_gen_rb = "../lib/rabbitmq/ffi/gen.rb"
ffi_gen_rb = File.expand_path(ffi_gen_rb, File.dirname(__FILE__))

File.open ffi_gen_rb, 'w' do |file|
  methods.each do |method|
    file.write "\nrequire_relative 'gen/#{method.name}'"
  end
  file.write "\n"
end
