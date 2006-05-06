require 'rake'
require 'rake/clean'
require 'rake/tasklib'

module Rake

  # Create a build task that will generate a Ruby extension (e.g. .so) from one or more
  # C (.c) or C++ (.cc, .cpp, .cxx) files, and is intended as a replcaement for mkmf.
  # It determines platform-specific settings (e.g. file extensions, compiler flags, etc.)
  # from rbconfig (note: examples assume *nix file extensions).
  #
  # *Note*: Strings vs Symbols
  # In places where filenames are expected (i.e. lib_name and objs), +String+s are used
  # as verbatim filenames, while, +Symbol+s have the platform-dependant extension
  # appended (e.g. '.so' for libraries and '.o' for objects).
  #
  # Example:
  #   desc "build sample extension"
  #   # build sample.so (from foo.{c,cc,cxx,cpp}, through foo.o)
  #   Rake::ExtensionTask.new :sample => :foo do |t|
  #     # all extension files under this directory
  #     t.dir = 'ext'
  #     # don't include, but rebuild library if it changes
  #     t.deps << 'config.h'
  #     # link libraries (libbar.so)
  #     t.link_libs << 'bar'
  #   end
  #
  # Author::    Steve Sloan (mailto:steve@finagle.org)
  # Copyright:: Copyright (c) 2006 Steve Sloan
  # License::   GPL
  class ExtensionTask < Rake::TaskLib
    # The name of the extension
    attr_accessor :name

    # The filename of the extension library file (e.g. 'extension.so')
    attr_accessor :lib_name

    # Object files to build and link into the extension.
    attr_accessor :objs

    # Depency files that aren't linked into the library, but cause it to be
    # rebuilt when they change.
    attr_accessor :deps

    # The directory where the extension files (source, output, and
    # intermediate) are stored.
    attr_accessor :dir

    # Environment configuration -- i.e. CONFIG from rbconfig, with a few other
    # settings, and converted to lowercase-symbols.
    attr_accessor :env

    # Additional link libraries
    attr_accessor :link_libs


    # List of paths to object files to build
    def output_objs
      @objs.collect do |o|
        f = (Symbol === o) ? "#{o}.#{env[:objext]}" : o
        File.join( dir, f )
      end
    end

    # Path to the output library file
    def output_lib
      File.join( dir, lib_name )
    end

    # Same arguments as Rake::define_task
    def initialize( args, &blk )
      @env = @@DefaultEnv.dup
      @name, @objs = resolve_args(args)
      set_defaults
      yield self  if block_given?
      define_tasks
    end

    # Generate default values.  This is called from initialize _before_ the
    # yield block.
    #
    # Defaults:
    # - lib_name: name.so
    # - objs: name.o
    # - dir: .
    def set_defaults
      @lib_name = (Symbol === name) ? "#{name}.#{env[:dlext]}" : name
      @objs = [name.to_sym]
      @dir = '.'
      @deps, @link_libs = [], []
    end

    # Defines the library task.
    def define_tasks
      task name => (deps.collect { |d| File.join( dir, d ) } << output_lib)  do end

      file output_lib => output_objs  do |t|
        sh_cmd :ldshared, {'-L' => :libdirs}, '-o', t.name, t.prerequisites,
                          {'-l' => link_libs}, :libs, :dlibs
      end

      CLEAN.include output_objs
      CLOBBER.include output_lib
      define_rules
    end

    # Defines C and C++ source-to-object rules, using the source extensions from env.
    def define_rules
      for ext in env[:c_exts]
        Rake::Task.create_rule '.'+env[:objext] => '.'+ext do |r|
          sh_cmd :cc, :cflags, :cppflags, {'-D' => :defines}, {'-I' => :includedirs}, {'-I' => :topdir},
                '-c', '-o', r.name, r.sources
        end
      end

      for ext in env[:cpp_exts]
        Rake::Task.create_rule '.'+env[:objext] => '.'+ext do |r|
          sh_cmd :cxx, :cxxflags, :cppflags, {'-D' => :defines}, {'-I' => :includedirs}, {'-I' => :topdir},
                '-o', r.name, '-c', r.sources
        end
      end
    end

    class << self
      # The default environment for all extensions.
      def env
        @@DefaultEnv
      end

      @@DefaultEnv = {
        :cxx => ENV['CXX'] || 'c++',
        :cxxflags => ENV['CXXFLAGS'] || '',

        :c_exts => ['c'],
        :cpp_exts => ['cc', 'cxx', 'cpp'],
        :swig => 'swig',
        :swig_flags => ['-ruby', '-c++'],
        :swig_includedirs => ['.'],

        :includedirs => [], #['/usr/local/include'],
        :libdirs => [], #['/usr/local/lib'],
      }
      Config::CONFIG.each { |k, v| @@DefaultEnv[k.downcase.to_sym] = v }
    end

  protected

    # Convenience function for cnstructing command lines for build tools.
    def optify( *opts )
      return optify(*opts.first)  if opts.size == 1 and opts.first.kind_of? Array
      opts.collect do |opt|
        case opt
          when String then  opt
          when Symbol then  optify env[opt]
          when Hash
            opt.collect do |k, v|
              v = env[v]  if v.kind_of? Symbol
              if v.kind_of? Array
                optify v.collect { |w| k.to_s + w.to_s }
              elsif v
                k.to_s + v.to_s
              end
            end
          else
            opt.to_s
        end
      end.join(' ')
    end

    def sh_cmd( cmd, *opts )
      sh optify( cmd, *opts )
    end

    # For some reason, Rake::TaskManager.resolve_args can't be found, so snarf it.
    def resolve_args(args)
      case args
      when Hash
        fail "Too Many Task Names: #{args.keys.join(' ')}" if args.size > 1
        fail "No Task Name Given" if args.size < 1
        task_name = args.keys[0]
        deps = args[task_name]
        deps = [deps] if (String===deps) || (Regexp===deps) || (Proc===deps)
      else
        task_name = args
        deps = []
      end
      [task_name, deps]
    end

  end

end