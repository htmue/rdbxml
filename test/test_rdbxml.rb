require 'test/unit'
require 'fileutils'
require 'rdbxml'

class XmlContainerTest < Test::Unit::TestCase
  def setup
    @dir = File.join( File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.db' )
    Dir.mkdir @dir  unless File.exists? @dir
    @env = RDBXML::env(@dir)

    @db = RDBXML::XmlManager.new @env, 0
    @db.setDefaultContainerType RDBXML::XmlContainer::WholedocContainer
    @container = 'test'
    @docs = @db['test']

    @doc_name = "Test#{rand(10000)}"
    @content = '<test>This is a test</test>'
  end

  def test_put_get_document
    assert_not_nil @docs

    @docs[@doc_name] = @content
    doc = @docs[@doc_name]
    assert_not_nil doc
    assert_equal doc.to_s, @content
  end

  def test_append_get_document
    assert_not_nil @docs

    doc = @db.createDocument
    doc.name, doc.content = @doc_name, @content
    @docs << doc

    doc = @docs[@doc_name]
    assert_not_nil doc
    assert_equal doc.to_s, @content
  end

  def test_update_document
    assert_not_nil @docs

    for content in [@content, @content.upcase]
      @docs[@doc_name] = content
      doc = @docs[@doc_name]
      assert_not_nil doc
      assert_equal doc.to_s, content
    end
  end

  def test_query
    xq = "count(collection('#{@container}')/*)"
    ctx = @db.createQueryContext
    q = @db.prepare xq, ctx
    res = q.execute ctx, 0
  end
end


class XmlDocumentTest < Test::Unit::TestCase
  def setup
    @dir = File.join( File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.db' )
    Dir.mkdir @dir  unless File.exists? @dir
    @env = RDBXML::env(@dir)
    @db = RDBXML::XmlManager.new @env, 0
    @docs = @db['test']
  end

  def test_metadata
    doc = @db.createDocument
    doc.name = "Test#{rand(10000)}"
    doc.content = '<test>This is a test</test>'
    doc.meta['created_at', 'http://nowhere.invalid/namespaces/foo'] = Time.now.to_s
    @docs << doc

    doc = @docs[doc.name]
    doc.meta.each do |name, val, uri|
      assert ['created_at', 'name'].include?(name)
    end
  end
end


class XmlResultsTest < Test::Unit::TestCase
  def setup
    @db = RDBXML::XmlManager.new
    @rng = 3..9
    @res = @db.query "(#{@rng.first} to #{@rng.last})"
  end

  def test_to_s
    assert_equal @rng.to_a.join("\n"), @res.to_s
  end

  def test_size
    assert_equal @rng.last - @rng.first + 1, @res.size
  end

  def test_to_a
    assert_equal @rng.to_a.first, @res.to_a.first
    assert_equal @rng.to_a, @res.to_a
  end

  def test_first
    assert_equal @rng.first, @res.first
    assert_equal @rng.first.to_s, @res.first.to_s
  end

  def test_each
    v = @rng.first
    @res.each do |r|
      assert_equal r, v
      v += 1
    end
  end
end

class XmlValueTest < Test::Unit::TestCase
  def setup
    @db = RDBXML::XmlManager.new
    @val = @db.query( '456.789' ).first
  end

  def test_equal
    assert_equal 456.789, @val
  end

  def test_to_s
    assert_equal '456.789', @val.to_s
  end

  def test_to_i
    assert_equal 456, @val.to_i
  end

  def test_to_f
    assert_equal 456.789, @val.to_f
  end
end
