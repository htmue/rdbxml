require 'db'
require 'dbxml'

# = RDBXML -- Pure-Ruby DB XML interface
# This module provides Ruby-ish convenience functions for DBXML.  See the unit
# tests for usage examples.

module RDBXML
  include Dbxml

  class << self
    # Creates a BDB environment with files stored in +dir+, with the following options:
    # [:create] Create the environment if it doesn't exist (default: +true+)
    # [:lock] Use locking (default: +true+)
    # [:log] Use logging (default: +true+)
    # [:mpool] Use memory pool (default: +true+)
    # [:txn] Use transactions (default: +true+)
    def env( dir, opts = {} )
      opts = {
        :create => true,
        :lock => true,
        :log => true,
        :mpool => true,
        :txn => true,
      }.merge(opts)
      flags = {
        :create => Dbxml::DB_CREATE,
        :lock => Dbxml::DB_INIT_LOCK,
        :log => Dbxml::DB_INIT_LOG,
        :mpool => Dbxml::DB_INIT_MPOOL,
        :txn => Dbxml::DB_INIT_TXN,
      }.inject(0) { |flags, (key, val)|  flags|val  if opts[key] }

      env = Db::DbEnv.new 0
      env.open dir, flags, 0
      env
    end
  end
end

class Dbxml::XmlValue
  def to_i ;   self.to_f.to_i ; end

  def ==( that )
    if isNumber
      self.asNumber == that
    elsif isBoolean
      self.asBoolean == that
    else
      self.asString == that.to_s
    end
  end
end

class Dbxml::XmlResults
  include Enumerable

  def each( &block )
    self.reset
    while self.hasNext
      yield self.next
    end
  end

  def first
    self.reset
    self.hasNext ? self.next : nil
  end

  def to_s
    collect { |v| v.to_s }.join "\n"
  end
end

class Dbxml::XmlDocument
  @@namespaces = {}

  class MetaData
    include Enumerable

    def initialize(doc)
      @doc = doc
    end

    def [](name, ns = '')
      v = XmlValue.new
      @doc.getMetaData( ns, name.to_s, v ) ? v : nil
    end

    def []=(name, *args)
      opts = {}
      val = args.pop
      ns = args.shift || ''
      if val
        @doc.setMetaData ns, name.to_s, XmlValue.new(val)
      else
        delete name, ns
      end
    end

    def delete(name, ns = '')
#puts "removeMetaData: #{name.inspect}, #{ns.inspect}"
      @doc.removeMetaData ns, name.to_s
    end

    def each(&block)
      i = @doc.getMetaDataIterator
      while (xmd = i.next)
        yield xmd.get_name.to_sym, xmd.get_value, xmd.get_uri
      end
    end

    def size
      s = 0
      i = @doc.getMetaDataIterator
      while i.next  do  s += 1  end
      s
    end
  end

  def meta
    @Meta ||= MetaData.new(self)
  end

end

class Dbxml::XmlContainer
  include Enumerable

  # Returns the document named +name+, or +nil+ if it doesn't exist.
  def []( name )
    begin
      getDocument name.to_s
    rescue XmlException => ex
      raise unless ex.to_s =~ /document not found/i
      nil
    end
  end

  # Creates/updates the document named +name+ with +content+ (either String or XmlDocument).
  def []=( name, content )
    doc = nil
    if String === content
      doc = manager.createDocument
      doc.name = name
      doc.content = content
    elsif content.kind_of? XmlDocument
      doc = content
    else
      raise ArgumentError, "content must be a String or XmlDocument"
    end
    self << doc
  end

  # Creates/updates the document +doc+.
  def <<( doc )
    ctx = getManager.createUpdateContext
    begin
      putDocument doc, ctx, 0
    rescue XmlException => ex
      raise unless ex.to_s =~ /document exists/i
      d = self[doc.name]
      d.content = doc.content
      updateDocument d, ctx
    end
  end

  # Iterates over each document in the collection
  def each( &block )
    getAllDocuments.each(block)
  end
end

class Dbxml::XmlManager
  # Opens the container named +name+, creating it if it doesn't exist.
  def []( name )
    openContainer name.to_s, Dbxml::DB_CREATE
  end

  def query( xquery, opts = {}, &block )
    opts[:ctx] ||= create_query_context
    q = self.prepare xquery, opts[:ctx]
    res = q.execute( opts[:ctx], 0 )
#puts "#{xquery} -> #{res}"
    res.each(block)  if block_given?
    res
  end
end
