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

# Wraps and extends the XmlValue[http://www.sleepycat.com/xmldocs/api_cxx/XmlValue.html] class.
# === Aliases:
# to_s::   asString
# to_f::   asNumber
# to_doc:: asDocument (XmlDocument)
# to_i::   #to_f
class Dbxml::XmlValue
  def to_i # :nodoc:
    self.to_f.to_i
  end

  # Handles Numeric/Boolean/String comparisons
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

# Wraps the XmlResults[http://www.sleepycat.com/xmldocs/api_cxx/XmlResults_list.html] class as an
# enumerable collection of XmlValue or XmlDocument.
class Dbxml::XmlResults
  include Enumerable

  # Iterates across each result (as an XmlValue) in the set
  def each( &block ) # :yields: value
    self.reset
    while self.hasNext
      yield self.next
    end
  end

  # Iterates across each result (as an XmlDocument) in the set
  def each_doc( &block ) # :yields: document
    self.reset
    while self.hasNext
      yield self.nextDocument
    end
  end

  # Returns the first result as an XmlValue(or +nil+)
  def first
    self.reset
    self.hasNext ? self.next : nil
  end

  # Returns the first result as an XmlDocument (or +nil+)
  def first_doc
    self.reset
    self.hasNext ? self.nextDocument : nil
  end

  # Returns the result set as +newline+-joined strings
  def to_s
    collect { |v| v.to_s }.join "\n"
  end
end

# Wraps and extends the XmlQueryContext[http://www.sleepycat.com/xmldocs/api_cxx/XmlQueryContext_list.html] class.
# === Aliases
# namespace::   getNamespace/setNamespace[http://www.sleepycat.com/xmldocs/api_cxx/XmlQueryContext_setNamespace.html]
# collection::  getDefaultCollection/setDefaultCollection[http://www.sleepycat.com/xmldocs/api_cxx/XmlQueryContext_setDefaultCollection.html]
class Dbxml::XmlQueryContext
  # XmlQueryContext::getVariableValue[http://www.sleepycat.com/xmldocs/api_cxx/XmlQueryContext_setVariableValue.html]
  def []( name )
    getVariableValue name.to_s
  end
  # XmlQueryContext::setVariableValue[http://www.sleepycat.com/xmldocs/api_cxx/XmlQueryContext_setVariableValue.html]
  def []=( name, val ) # :nodoc:
    setVariableValue name.to_s, Dbxml::XmlValue.new(val)
  end
end

# Wraps and extends the XmlDocument[http://www.sleepycat.com/xmldocs/api_cxx/XmlDocument_list.html] class.
# === Aliases:
# name:: getName/setName[http://www.sleepycat.com/xmldocs/api_cxx/XmlDocument_setName.html]
# content:: getContent/setContent[http://www.sleepycat.com/xmldocs/api_cxx/XmlDocument_getContent.html]
# to_s:: #content
class Dbxml::XmlDocument
  # Represents the document metadata as an Enumerable collection
  class MetaData
    include Enumerable

    def initialize(doc)  #:nodoc:
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
        @doc.setMetaData ns, name.to_s, Dbxml::XmlValue.new(val)
      else
        delete name, ns
      end
    end

    def delete(name, ns = '')
#puts "removeMetaData: #{name.inspect}, #{ns.inspect}"
      @doc.removeMetaData ns, name.to_s
    end

    def each(&block) # :yields: name, value, uri
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

    def inspect
      all = {}
      self.each { |n, v|  all[n] = v }
      all.inspect
    end
  end

  # Returns the document metadata[http://www.sleepycat.com/xmldocs/api_cxx/XmlDocument_getMetaData.html]
  def meta
    @Meta ||= MetaData.new(self)
  end

end

# Wraps and extends the XmlContainer[http://www.sleepycat.com/xmldocs/api_cxx/XmlContainer_list.html] class.
# === Aliases
# manager:: getManager[http://www.sleepycat.com/xmldocs/api_cxx/XmlContainer_getManager.html]
class Dbxml::XmlContainer
  include Enumerable

  # Returns the document named +name+, or +nil+ if it doesn't exist.
  def []( name )
    begin
      getDocument name.to_s
    rescue Dbxml::XmlException => ex
      raise unless ex.err == Dbxml::XmlException::DOCUMENT_NOT_FOUND
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

  # Creates/updates the XmlDocument +doc+.
  def <<( doc )
    ctx = getManager.createUpdateContext
    begin
      putDocument doc, ctx, (doc.name.empty? ? Dbxml::DBXML_GEN_NAME : 0)
    rescue Dbxml::XmlException => ex
      raise unless ex.err == Dbxml::XmlException::UNIQUE_ERROR
      d = self[doc.name]
      d.content = doc.content
      updateDocument d, ctx
    end
  end

  # Iterates over each XmlDocument in the collection
  def each( &block ) # :yields: document
    getAllDocuments.each(block)
  end
end

# Wraps and extends the XmlManager[http://www.sleepycat.com/xmldocs/api_cxx/XmlManager_list.html] class.
# === Aliases
# create_query_context:: createQueryContext
class Dbxml::XmlManager
  # Opens the container named +name+, creating it if it doesn't exist.
  def []( name )
    openContainer name.to_s, Dbxml::DB_CREATE
  end

  # Runs the query +xquery+, creating a query context if necessary or using
  # +opts[:ctx]+ if passed.
  def query( xquery, opts = {}, &block ) # :yeilds: result
    opts[:ctx] ||= create_query_context
    q = self.prepare xquery, opts[:ctx]
    res = q.execute( opts[:ctx], 0 )
#puts "#{xquery} -> #{res}"
    res.each(block)  if block_given?
    res
  end
end

# Wraps and extends the [http://www.sleepycat.com/xmldocs/api_cxx/env_class.html] class.
class Db::DbEnv
  # Convenience function to instantiate a XmlManager which attaches to
  # this environment.
  def manager
    Dbxml::XmlManager.new self, 0
  end
end
