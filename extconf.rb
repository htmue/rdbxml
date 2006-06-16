#!/usr/bin/env ruby
DBXML_DIST=ENV['DBXML_DIST'] || './dbxml-2.2.13'

# Build wrapper makefile that just calls rakefile
File.open( 'Makefile', 'w' ) do |mk|
  targets = ['all', 'clean', 'test', 'install']
  mk.puts ".PHONY: #{targets.join(' ')}\n"
  targets.each { |t|  mk.puts "#{t}:\n\t@rake $@\n" }
end
