#!/usr/bin/env ruby
DBXML_DIST=ENV['DBXML_DIST'] || './dbxml-2.2.13'

# Build makefile that just calls rakefile
File.open( 'Makefile', 'w' ) do |mk|
  targets = ['all', 'clean', 'test', 'install']
  mk.puts ".PHONY: #{targets.join(' ')}\n"
  targets.each { |t|  mk.puts "#{t}:\n\t@rake $@\n" }
end


=begin
require 'mkmf2'

MAKEFILE_CONFIG['CC'].gsub! 'gcc', 'g++'
MAKEFILE_CONFIG['CPP'].gsub! 'gcc', 'g++'

###############################################################################

#b.libs += ['db-4.3', 'db_cxx-4.3', 'dbxml-2.2', 'xquery-1.2', 'xerces-c', 'pathan']

add_include_path File.join( DBXML_DIST, 'install', 'include' )
add_library_path File.join( DBXML_DIST, 'install', 'lib' )
require_library 'db', 'db_version', 'db.h'
require_library 'db_cxx', 'DbEnv::version', 'db_cxx.h'
declare_binary_library 'db', 'db_wrap.cc'

#add_include_path File.join( DBXML_DIST, 'install', 'include', 'dbxml' )
require_library 'xerces-c', 'XERCES_VERSIONSTR', 'xercesc/util/XercesVersion.hpp'
require_library 'pathan'
require_library 'xquery'
require_library 'dbxml', 'DBXML_VERSION_STRING', 'dbxml/DbXmlFwd.hpp'
declare_binary_library 'dbxml', 'dbxml_wrap.cc'


File.open( 'Makefile', 'a' ) { |mk|  mk.puts "DBXML_DIST=#{DBXML_DIST}", 'include Makefile.swig' }
=end
