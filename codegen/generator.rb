
module CodeGen
  class Generator
    
    attr_reader :lines
    attr_reader :indents
    attr_accessor :indent_amount
    
    def initialize
      @lines = [""]
      @indents= [""]
      @indent_amount = 2
    end
    
    def to_s
      lines.join("\n")
    end
    
    def pop_indent
      indents.pop
    end
    
    def push_indent(amount=indent_amount)
      indents.push(indents.last + " " * amount)
    end
    
    def add(*strings)
      strings.each do |string|
        lines.last.concat(string)
      end
    end
    
    def line(*strings)
      lines.push(indents.last.dup)
      add(*strings)
    end
    
    def list(items, separator="", auto_lines:false, &block)
      return unless items.any?
      
      items = items.dup
      last_item = items.pop
      
      use_lines = items.any? && auto_lines
      use_lines && self.push_indent
      
      items.each do |item|
        use_lines && self.line
        block ? block.call(item) : add(item)
        add(separator)
      end
      use_lines && self.line
      block ? block.call(last_item) : add(last_item)
      
      use_lines && self.pop_indent
      use_lines && self.line
    end
    
  end
end
