require 'rake'
require 'rake/extensiontask'

module Rake

  # Create a build task that will generate a Ruby wrapper extension from
  # SWIG interface definition(s).  Requires SWIG[http://www.swig.org] version 1.3.x.
  #
  # See ExtensionTask for more information.
  #
  # Example (from RDBXML):
  #   # dbxml.i -> dbxml_wrap.cc -> dbxml_wrap.o -> dbxml.so
  #   Rake::SWIGExtensionTask.new :dbxml do |t|
  #     # keep it all under ext/
  #     t.dir = 'ext'
  #     # dbxml.i includes dbxml_ruby.i so rebuild if it changes
  #     t.deps[:dbxml] << :dbxml_ruby
  #     # link in dbxml libraries
  #     t.link_libs += ['db', 'db_cxx', 'dbxml', 'xquery', 'xerces-c', 'pathan']
  #   end
  #
  # Author::    Steve Sloan (mailto:steve@finagle.org)
  # Copyright:: Copyright (c) 2006 Steve Sloan
  # License::   GPL
  class SWIGExtensionTask < ExtensionTask

    # An Array of interface filenames (Symbol or String) to build and link into
    # the extension.
    attr_accessor :ifaces

    # A Hash of interface filenames and their dependencies, i.e. files which
    # are not built or linked, but cause the corresponding interface to be
    # rebuild if any of them change.
    attr_accessor :deps

    # Defaults:
    # - lib_name: name.so
    # - ifaces: name.i
    # - deps: <none>
    # - dir: .
    # - link_libs: <none>
    def set_defaults
      super
      @objs ||= []
      @ifaces ||= [name.to_sym]
      @deps ||= Hash.new []
   end

    def define_tasks
      for iface in @ifaces
        deps = @deps[iface]
        iface = filepath(iface, :swigext)
        src = iface.sub(/\.#{env[:swigext]}$/, env[:swig_cppext])

        deps = [deps]  unless deps.kind_of? Enumerable
        if deps and deps.any?
          file src => deps.collect { |dep| filepath(dep, :swigext) } << iface
        end
        CLEAN.include src

        @objs << src.sub(/\.[^.]+$/, '.'+env[:objext])
      end
      super
    end

    # Add rule for generating C++ wrapper code (_wrap.cc) from SWIG interface definition (.i).
    def define_rules
      verify_swig_version
      super
      Rake::Task.create_rule(
        /#{env[:swig_cppext]}$/ => [proc {|t| t.sub /#{env[:swig_cppext]}$/, '.'+env[:swigext] }]
      )  do |r|
        sh_cmd :swig, :swig_flags, {'-I' => :swig_includedirs}, {'-I' => :includedirs},
                '-o', r.name, r.sources
      end
    end

    ExtensionTask.env = {
      :swig => 'swig',
      :swigext => 'i',
      :swig_cppext => '_wrap.cc',
      :swig_flags => ['-ruby', '-c++'],
      :swig_includedirs => ['.']
    }.update(ExtensionTask.env)

  protected

    # Raise an exception unless we have SWIG version 1.3 or later.
    def verify_swig_version
      @@swig_version ||= IO.popen "#{env[:swig]} -version 2>&1" do |swig|
        banner = swig.readlines.reject { |l| l.strip.empty? }
        banner = banner[0].match(/swig version ([^ ]+)/i)
        banner and banner[1]
      end
      unless @@swig_version and @@swig_version >= '1.3'
        raise "Need SWIG version 1.3 or later (have #{@@swig_version || 'none'})"
      end
    end
  end

end
