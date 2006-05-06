require 'rake'
require 'rake/extensiontask'

module Rake

  # Create a build task that will generate a Ruby wrapper extension from
  # a SWIG (http://www.swig.org) interface definition.  Requires SWIG version 1.3.x.
  #
  # See ExtensionTask for more information.
  #
  # Example:
  #   Builds (under ext/) dbxml.so from dbxml.i (through dbxml_wrap.cc),
  # linking in various libraries.  Since dbxml.i includes dbxml_ruby.i, we
  # list it as a dependency (to rebuild the library if it changes).
  #
  #   Rake::SWIGExtensionTask.new :dbxml do |t|
  #     t.dir = 'ext'
  #     t.deps << 'dbxml_ruby.i'
  #     t.link_libs += ['db', 'db_cxx', 'dbxml', 'xquery', 'xerces-c', 'pathan']
  #   end
  #
  class SWIGExtensionTask < ExtensionTask
    # By default:
    # - dependencies: name.i
    # - objects: name_wrap.o
    def set_defaults
      @lib_name = (Symbol === name) ? "#{name}.#{env[:dlext]}" : name
      @objs = ["#{name}_wrap".to_sym]
      @deps = ["#{name}.i"]
    end

    # Add rule for generating C++ wrapper code (.cc) from SWIG interface definition (.i)
    def define_rules
      verify_swig_version
      Rake::Task.create_rule( '_wrap.cc' => [proc {|t| t.gsub /_wrap\.cc$/, '.i' }] )  do |r|
        sh_cmd :swig, :swig_flags, {'-I' => :swig_includedirs}, {'-I' => :includedirs},
                '-o', r.name, r.sources
      end
      super
    end

  protected

    # Raie an exception unless we have SWIG version 1.3 or later
    def verify_swig_version
      @@swig_version ||= IO.popen "#{env[:swig]} -version 2>&1" do |swig|
        banner = swig.readlines.reject { |l| l.strip.empty? }
        banner[0].match(/SWIG Version ([^ ]+)/i)[1]
      end
      unless @@swig_version >= '1.3'
        raise "Need SWIG version 1.3 or later (have #{@@swig_version[0]})"
      end
    end
  end

end
