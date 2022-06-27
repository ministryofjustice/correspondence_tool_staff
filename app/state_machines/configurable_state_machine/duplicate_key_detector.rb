module ConfigurableStateMachine

  class DuplicateKeyDetector

    class KeyRegister

      attr_reader :line_numbers

      def initialize
        @keys = []
        @line_numbers = {}
      end

      def add(key, line_number)
        @keys << key
        @line_numbers[key] = line_number
      end

      def empty?
        @keys.empty?
      end

      def any?
        @keys.any?
      end

      def duplicate?(key)
        key.in?(@keys)
      end

    end

    TABSIZE = 2

    def initialize(filename)
      @filename = filename
      @current_key = ''
      @seen_keys = KeyRegister.new
      @duplicate_keys = KeyRegister.new
      @current_indent = -2
    end

    def run
      line_number = 0
      File.open(@filename, 'r') do |fp|
        while !fp.eof do
          line = fp.readline
          line_number += 1
          next if comment_line?(line)
          check_key(line, line_number)
        end
      end
    end

    def dupes?
      @duplicate_keys.any?
    end

    def dupe_details
      lines = []
      @duplicate_keys.line_numbers.each do |key, line_number|
        lines <<  " #{key} on line #{line_number} duplicates line #{@seen_keys.line_numbers[key]}"
      end
      lines
    end

    private

    def comment_line?(line)
      line =~ /^\s*#/
    end

    def check_key(line, line_number)
      if line =~ /^(\s*)(\S+:)/
        indent = $1.length
        line_key = $2
        full_key = full_key_for_line(indent, line_key)
        if @seen_keys.duplicate?(full_key)
          @duplicate_keys.add(full_key, line_number)
        else
          @seen_keys.add(full_key, line_number)
        end
      end

    end

    def full_key_for_line(indent, line_key)
      if indent > @current_indent
        @current_key += line_key
      else
        num_key_segments = indent / TABSIZE
        key_segments = @current_key.split(':')
        base_key = key_segments.slice(0, num_key_segments).join(':')
        @current_key = base_key + ':' + line_key
      end
      @current_indent = indent
      @current_key
    end
  end
end
