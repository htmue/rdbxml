require 'rake'
require 'rake/clean'
require 'rake/swigextensiontask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'date'

GEM_VERSION = '2.3.11'

dbxml_dist = ENV['DBXML_DIST']
if dbxml_dist
  puts "*** Using DBXML distribution in #{dbxml_dist}"
  Rake::ExtensionTask.env.update(
    :swig_includedirs => [File.join( dbxml_dist, 'dbxml/dist/swig' ), '.'],
    :includedirs => File.join( dbxml_dist, 'install/include' ),
    :libdirs => File.join( dbxml_dist, 'install/lib' )
  )
else
  Rake::ExtensionTask.env.update(
    :includedirs => '/usr/local/include',
    :libdirs => '/usr/local/lib'
  )
end

desc "Build the interface extension"
task :extensions => [:db, :dbxml]

desc "Build the BDB interface extension"
Rake::SWIGExtensionTask.new :db do |t|
  t.dir = 'ext'
  t.link_libs += ['db', 'db_cxx']
end

desc "Build the BDBXML interface extension"
Rake::SWIGExtensionTask.new :dbxml do |t|
  t.dir = 'ext'
  t.deps[:dbxml] << :dbxml_ruby
  t.link_libs += ['db', 'db_cxx', 'dbxml', 'xqilla', 'xerces-c']
end

task :test => :extensions
Rake::TestTask.new do |t|
  t.libs << "ext"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
  CLEAN.include 'test/test_*.db'
end

task :install => [:test, :clean] do end

docs = Rake::RDocTask.new :rdoc do |rdoc|
  rdoc.rdoc_dir = 'html'
  rdoc.title    = "RDBXML -- XML Databases for Ruby"
  rdoc.options += ['--line-numbers', '--inline-source', '--main', 'README', '--exclude', 'ext/*.c*']
  rdoc.rdoc_files.include 'README', 'MIT-LICENSE'
  rdoc.rdoc_files.include 'lib/**/*.rb'
  rdoc.rdoc_files.include 'docs/**/*.rb', 'docs/**/*.rdoc'
  rdoc.rdoc_files.include 'rake/**/*task.rb'
end

GEM_FILES = docs.rdoc_files + FileList[
  'Rakefile',
  'ext/**/*.i',
  'rake/**/*.rb',
  'test/**/test_*.rb',
]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rdbxml'
  s.version = GEM_VERSION
  s.date = Date.today.to_s
  s.authors = ["Steve Sloan"]
  s.summary = 'Provides wrappers for the BDB XML C++ APIs, plus pure Ruby extensions'
#  s.description =
  s.files = GEM_FILES.to_a.delete_if {|f| f.include?('.svn')}
  s.autorequire = 'rdbxml'
  s.test_files = Dir["test/test_*.rb"]
  s.add_dependency 'rake', '> 0.7.0'

  s.extensions << './extconf.rb'
  s.require_paths << 'ext'

  s.has_rdoc = true
  s.extra_rdoc_files = docs.rdoc_files.reject { |fn| fn =~ /\.rb$/ }.to_a
  s.rdoc_options = docs.options
end
Rake::GemPackageTask.new spec  do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => :extensions
task :all => :extensions

load 'publish.rf' if File.exist? 'publish.rf'
