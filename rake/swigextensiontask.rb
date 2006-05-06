require 'rake'
require 'rake/extensiontask'

module Rake

  # Create a build task that will generate a Ruby wrapper extension from
  # a SWIG interface definition.  Requires SWIG[http://www.swig.org] version 1.3.x.
  #
  # See ExtensionTask for more information.
  #
  # Example (from RDBXML):
  #   # dbxml.i -> dbxml_wrap.cc -> dbxml_wrap.o -> dbxml.so
  #   Rake::SWIGExtensionTask.new :dbxml do |t|
  #     # keep it all under ext/
  #     t.dir = 'ext'
  #     # dbxml.i includes dbxml_ruby.i -- rebuild if it changes
  #     t.deps << 'dbxml_ruby.i'
  #     # link in dbxml libraries
  #     t.link_libs += ['db', 'db_cxx', 'dbxml', 'xquery', 'xerces-c', 'pathan']
  #   end
  #
  # Author::    Steve Sloan (mailto:steve@finagle.org)
  # Copyright:: Copyright (c) 2006 Steve Sloan
  # License::   GPL
  class SWIGExtensionTask < ExtensionTask
    # Defaults:
    # - lib_name: name.so
    # - objs: name_wrap.o
    # - deps: name.i
    # - dir: .
    def set_defaults
      super
      @lib_name = (Symbol === name) ? "#{name}.#{env[:dlext]}" : name
      @objs = ["#{name}_wrap".to_sym]
      @deps = ["#{name}.i"]
    end

    # Add rule for generating C++ wrapper code (_wrap.cc) from SWIG interface definition (.i).
    def define_rules
      verify_swig_version
      Rake::Task.create_rule( '_wrap.cc' => [proc {|t| t.gsub /_wrap\.cc$/, '.i' }] )  do |r|
        sh_cmd :swig, :swig_flags, {'-I' => :swig_includedirs}, {'-I' => :includedirs},
                '-o', r.name, r.sources
      end
      super
    end

  protected

    # Raise an exception unless we have SWIG version 1.3 or later.
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
