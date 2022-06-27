#!/usr/bin/env ruby

CTS_ROOT_DIR = File.dirname($0)

if defined?(Rails) || ARGV.include?('-h') || ARGV.include?('--help')
  SKIP_RAILS=true
else
  exec(File.join(CTS_ROOT_DIR, 'bin', 'rails'), 'runner', $0, *ARGV)
end

RavenContextProvider.set_context if defined?(RavenContextProvider)

require 'thor'

$: << 'lib'
require 'cts/cli'

class Thor
  module Shell
    class Basic
      def print_wrapped(message, _options = {})
        stdout.puts message
      end
    end
  end
end

if File.expand_path($0) == __FILE__
  CTS::CLI.start(ARGV)
end
