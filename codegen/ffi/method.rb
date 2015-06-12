
require_relative '../generator.rb'


module CodeGen
  module FFI
    class Method
      
      def self.list_from_c_header(filename)
        list = []
        string = File.read(filename)
        string.scan(from_c_scan_regexp) { |a,b,c| list << from_c(a,b,c) }
        list
      end
      
      def self.from_c_scan_regexp
        /\/\*\*\s*([\w-]+)\.([\w-]+) method fields \*\/[^{]+{([^{]+)}/
      end
      
      def self.from_c(proto_class, proto_method, raw_fields)
        obj = new
        obj.name = "#{proto_class.tr('-','_')}_#{proto_method.tr('-','_')}"
        
        obj.fields = []
        raw_fields.scan(/(\w+) (\w+);/) { |c_type, name|
          type = case c_type
          when "amqp_table_t";   "Table"
          when "amqp_bytes_t";   "Bytes"
          when "amqp_boolean_t"; "Boolean"
          else; ":#{c_type.sub(/_t$/, '')}"
          end
          obj.fields << [name, type]
        }
        
        obj
      end
      
      attr_accessor :name
      attr_accessor :fields
      
      def dirname
        File.expand_path("../../lib/rabbitmq/ffi/gen", File.dirname(__FILE__))
      end
      
      def basename
        "#{name}.rb"
      end
      
      def filename
        File.join(dirname, basename)
      end
      
      def const_name
        name.to_s.gsub(/((?:\A\w)|(?:_\w))/) { |x| x[-1].upcase }
      end
      
      def generate_file!
        g = Generator.new
        generate_class_header g
        generate_layout       g
        generate_id_methods   g
        generate_apply_method g
        generate_to_h_method  g
        generate_free_method  g
        generate_class_footer g
        
        FileUtils.mkdir_p dirname
        File.open filename, 'w' do |file|
          file.write g.to_s
        end
      end
      
      def generate_class_header(g)
        g.line; g.push_indent; g.add("module RabbitMQ")
        g.line; g.push_indent; g.add("module FFI")
        g.line; g.push_indent; g.add("class #{const_name} < ::FFI::Struct")
      end
      
      def generate_class_footer(g)
        g.pop_indent; g.line("end")
        g.pop_indent; g.line("end")
        g.pop_indent; g.line("end")
        g.line
      end
      
      def generate_layout(g)
        g.line("layout(")
        g.list(fields, ",", auto_lines: true) { |name, type|
          g.add(":#{[name, type].join ", "}")
        }
        g.add(")")
        g.line
      end
      
      def generate_id_methods(g)
        ["self.id", "id"].each do |method|
          g.line("def #{method}"); g.push_indent
          g.line(":#{name}")
          g.pop_indent; g.line("end")
          g.line
        end
      end
      
      def generate_apply_method(g)
        param_fields  = self.fields.reject { |name, type| name == "method_id"}
                                   .map    { |name, type| name == "class_id" ? "method" : name }
        assign_fields = self.fields.reject { |name, type| ["method_id", "class_id", "dummy"].include?(name) }
        
        g.line("def apply(")
        g.list(param_fields, ", ", auto_lines: false) { |name, type|
          g.add("#{name}: nil")
        }
        g.add(")")
        g.push_indent
        
        if fields.map(&:first).include?("class_id")
          g.line("if method"); g.push_indent
          g.line("method_id = FFI::MethodNumber[method.to_sym]")
          g.line("self[:class_id] = method_id >> 16")
          g.line("self[:method_id] = method_id & 0xFFFF")
          g.pop_indent; g.line("end")
        end
        
        assign_fields.each do |name, type|
          next if name == "dummy"
          g.line("self[:#{name}] = ")
          
          case type
          when "Bytes";   g.add("Bytes.from_s(#{name}.to_s)")
          when "Table";   g.add("Table.from(#{name})")
          when "Boolean"; g.add("#{name}")
          else;           g.add("Integer(#{name})")
          end
          
          g.add(type == "Boolean" ? " unless #{name}.nil?" : " if #{name}")
        end
        
        g.line("self")
        g.pop_indent
        g.line("end")
        g.line
      end
      
      def generate_to_h_method(g)
        g.line("def to_h(free=false)")
        g.push_indent
        g.line("{")
        
        use_fields = self.fields.reject { |name, type| ["method_id", "dummy"].include?(name) }
        g.list(use_fields, ",", auto_lines: true) do |name, type|
          if name == "class_id"
            g.add("method: FFI::MethodNumber[self[:method_id] + (self[:class_id] << 16)]")
          else
            g.add("#{name}: ")
            
            case type
            when "Bytes";   g.add("self[:#{name}].to_s(free)")
            when "Table";   g.add("self[:#{name}].to_h(free)")
            else;           g.add("self[:#{name}]")
            end
          end
        end
        
        g.add("}")
        g.pop_indent
        g.line("end")
        g.line
      end
      
      def generate_free_method(g)
        g.line("def free!")
        g.push_indent
        
        fields.each do |name, type|
          case type
          when "Bytes"; g.line("self[:#{name}].free!")
          when "Table"; g.line("self[:#{name}].free!")
          end
        end
        
        g.pop_indent
        g.line("end")
        g.line
      end
    end
  end
end
