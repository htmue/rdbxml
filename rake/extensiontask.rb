require 'rake'
require 'rake/clean'
require 'rake/tasklib'

module Rake

  class ExtensionTask < Rake::TaskLib
    attr_accessor :name, :lib_name, :dir, :env, :deps, :objs, :link_libs

    def output_objs
      @objs.collect do |o|
        f = (Symbol === o) ? "#{o}.#{env[:objext]}" : o
        File.join( dir, f )
      end
    end

    def output_lib
      File.join( dir, lib_name )
    end

    def initialize( args, &blk )
      @env = @@DefaultEnv.dup
      @name, @objs = resolve_args(args)
      @dir = '.'
      @deps, @objs, @link_libs = [], [], []
      set_defaults
      yield self  if block_given?
      define_tasks
    end

    def set_defaults
      @lib_name = (Symbol === name) ? "#{name}.#{env[:dlext]}" : name
      @objs = [name.to_sym]
    end

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

    # Convenice function for cnstructing command lines for build tools
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