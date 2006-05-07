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

class Dbxml::XmlManager
  # Opens the container named +name+, creating it if it doesn't exist.
  def []( name )
    openContainer name.to_s, Dbxml::DB_CREATE
  end
end

class Dbxml::XmlContainer
  # Returns the document named +name+, or +nil+ if it doesn't exist.
  def []( name )
    begin
      getDocument name.to_s
    rescue XmlException => ex
      raise unless ex.to_s =~ /document not found/i
      nil
    end
  end

  # Creates/updates the document named +name+ with the string +content+.
  def []=( name, content )
    ctx = getManager.createUpdateContext
    begin
      putDocument name, content, ctx, 0
    rescue XmlException => ex
      raise unless ex.to_s =~ /document exists/i
      doc = getManager.createDocument
      doc.setName name
      doc.setContent content
      updateDocument doc, ctx
    end
  end
end

class Dbxml::XmlDocument
  # Returns the document XML as a string.
  def to_s
    getContentAsString
  end
end
