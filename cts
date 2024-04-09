#!/usr/bin/env ruby

CTS_ROOT_DIR = File.dirname($PROGRAM_NAME)

if defined?(Rails) || ARGV.include?("-h") || ARGV.include?("--help")
  SKIP_RAILS = true
else
  exec(File.join(CTS_ROOT_DIR, "bin", "rails"), "runner", $PROGRAM_NAME, *ARGV)
end

RavenContextProvider.set_context if defined?(RavenContextProvider)

require "thor"

$LOAD_PATH << "lib"
require "cts/cli"

class Thor
  module Shell
    class Basic
      def print_wrapped(message, _options = {})
        stdout.puts message
      end
    end
  end
end

if File.expand_path($PROGRAM_NAME) == __FILE__
  CTS:Cli.start(ARGV)
end
