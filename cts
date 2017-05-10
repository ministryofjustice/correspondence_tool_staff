#!/usr/bin/env ruby

require 'thor'
require 'thor/rails'
require File.join(File.dirname(__FILE__), 'db', 'seeders', 'case_seeder')



CaseSeeder.start(ARGV)
