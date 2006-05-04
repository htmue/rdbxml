require 'test/unit'
require 'db'
require 'dbxml'

include Dbxml

class DBXMLTest < Test::Unit::TestCase
  def setup
    @dir = File.join( File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.db' )
    Dir.mkdir @dir  unless File.exists? @dir
    @name = "test document ##{rand(10000)}"
    @content = '<test>This is a test</test>'
  end

  def test_create_environment
    @env = Db::DbEnv.new 0
    assert_not_nil @env

    @env.open @dir, DB_CREATE | DB_INIT_LOCK | DB_INIT_LOG | DB_INIT_MPOOL | DB_INIT_TXN, 0
  end

  def test_create_manager
    test_create_environment  unless @env
    @db = XmlManager.new @env, 0
    assert_not_nil @db

    @db.setDefaultContainerType XmlContainer::WholedocContainer
  end

  def test_open_container
    test_create_manager  unless @db
    @docs = @db.openContainer 'test', DB_CREATE
    assert_not_nil @docs
  end

  def test_put_doument
    test_open_container  unless @docs
    assert_not_nil @docs

    @docs.putDocument @name, @content, @db.createUpdateContext, 0

    doc = @docs.getDocument @name
    assert_not_nil doc
    assert_equal doc.getName, @name
    assert_equal doc.getContentAsString, @content
  end

end
