require 'test/unit'
require 'fileutils'
require 'rdbxml'

class RDBXMLTest < Test::Unit::TestCase

  def setup
    @dir = File.join( File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.db' )
    Dir.mkdir @dir  unless File.exists? @dir
    @env = RDBXML::env(@dir)

    @db = RDBXML::XmlManager.new @env, 0
    @db.setDefaultContainerType RDBXML::XmlContainer::WholedocContainer
    @docs = @db['test']

    @name = "test document ##{rand(10000)}"
    @content = '<test>This is a test</test>'
  end

  def test_put_get_document
    assert_not_nil @docs

    @docs[name] = @content
    doc = @docs[name]
    assert_not_nil doc
    assert_equal doc.to_s, @content
  end

  def test_update_document
    assert_not_nil @docs

    for content in [@content, @content.upcase]
      @docs[name] = content
      doc = @docs[name]
      assert_not_nil doc
      assert_equal doc.to_s, content
    end
  end

end
