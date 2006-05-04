require 'db'
require 'dbxml'

module RDBXML
  include Dbxml

  class Dbxml::XmlManager
    def []( name )
      openContainer name.to_s, Dbxml::DB_CREATE
    end
  end

  class Dbxml::XmlContainer
    def []( name )
      begin
        getDocument name.to_s
      rescue XmlException => ex
        raise unless ex.to_s =~ /document not found/i
        nil
      end
    end

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
    def to_s
      getContentAsString
    end
  end

  class << self
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
