require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
load 'build.rake'

dbxml_dist = ENV['DBXML_DIST']
if dbxml_dist
  puts "Using DBXML installed in #{dbxml_dist}"
  Build::ExtensionTask.env.update(
    :swig_includedirs => [File.join( dbxml_dist, 'dbxml/dist/swig' ), '.'],
    :includedirs => File.join( dbxml_dist, 'install/include' ),
    :libdirs => File.join( dbxml_dist, 'install/lib' )
  )
else
  Build::ExtensionTask.env.update(
    :includedirs => '/usr/local/include',
    :libdirs => '/usr/local/lib'
  )
end

task :default => :all

desc "Build the interface extension"
task :all => [:db, :dbxml]

desc "Build the BDB interface extension"
Build::SWIGExtensionTask.new :db do |t|
  t.dir = 'ext'
  t.link_libs += ['db', 'db_cxx']
end

desc "Build the BDBXML interface extension"
Build::SWIGExtensionTask.new :dbxml do |t|
  t.dir = 'ext'
  t.deps << 'dbxml_ruby.i'
  t.link_libs += ['db', 'db_cxx', 'dbxml', 'xquery', 'xerces-c', 'pathan']
end

task :clean do |t|
  rm_rf Dir['test/*_test.db']
  rm_f Dir['ext/*_wrap.cc']
end

task :test => [:db, :dbxml]
Rake::TestTask.new do |t|
  t.libs << "ext"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :install => [:test, :clean] do end


GEM_VERSION = '0.1'
GEM_FILES = FileList[
  '[A-Z]*',
  'build.rake',
  'lib/**/*.rb',
  'ext/**/*.i',
  'test/**/*_test.rb'
]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rdbxml'
  s.version = GEM_VERSION
  s.date = Date.today.to_s
  s.authors = ["Steve Sloan"]
  s.summary = 'Provides wrappers for the BDBXML (and BDB) C++ APIs, plus pure Ruby extensions'
  s.description = <<-END
  END
  s.autorequire = 'rdbxml'
  s.has_rdoc = false
# s.extra_rdoc_files = ["README"]
  s.files = GEM_FILES.to_a.delete_if {|f| f.include?('.svn')}
  s.test_files = Dir["*_test.rb"]
  s.add_dependency 'rake', '> 0.7.0'

  s.extensions << './extconf.rb'
  s.require_paths << 'ext'
end
Rake::GemPackageTask.new spec

desc "Build the gem package"
task :gem => :package do
  system 'gem', 'query', File.join( 'pkg', spec.name + '.gem' )
end

#load 'publish.rf' if File.exist? 'publish.rf'

