require 'test/unit'
require 'fileutils'
require 'rdbxml'

class XmlValueTest < Test::Unit::TestCase
  def test_new_i
    v = XmlValue.new 123
    assert v.isNumber, v.getType
    assert !v.isString && !v.isBoolean && !v.isBinary && !v.isNode
    assert_equal v, 123
  end

  def test_new_f
    v = XmlValue.new 123.456
    assert v.isNumber
    assert !v.isString && !v.isBoolean && !v.isBinary && !v.isNode
    assert_equal v, 123.456
  end

  def test_new_s
    v = XmlValue.new 'foo'
    assert v.isString
    assert !v.isNumber && !v.isBoolean && !v.isBinary && !v.isNode
    assert_equal v, 'foo'
  end

  def test_new_b
    v = XmlValue.new true
    assert v.isBoolean
    assert !v.isNumber && !v.isString && !v.isBinary && !v.isNode
    assert_equal v, true

    v = XmlValue.new false
    assert v.isBoolean
    assert !v.isNumber && !v.isString && !v.isBinary && !v.isNode
    assert_equal v, false
  end

  def test_to_s
    assert_equal '123', XmlValue.new(123).to_s
    assert_equal '456.789', XmlValue.new(456.789).to_s
    assert_equal 'foo', XmlValue.new('foo').to_s
  end

  def test_to_i
    assert_equal 123, XmlValue.new(123).to_i
    assert_equal 456, XmlValue.new(456.789).to_i
    assert_raise(FloatDomainError) { XmlValue.new('foo').to_i }
  end

  def test_to_f
    assert_equal 123.0, XmlValue.new(123).to_f
    assert_equal 456.789, XmlValue.new(456.789).to_f
    assert XmlValue.new('foo').to_f.nan?
  end
end

class XmlQueryContextTest < Test::Unit::TestCase
  def setup
    @db = RDBXML::XmlManager.new
    @q = @db.create_query_context
  end

  def test_get_set_variable
    @q[:foo] = 'xyz'
    assert_equal 'xyz', @q[:foo].to_s
    assert_equal 'xyz', @db.query('$foo', :ctx => @q).to_s
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

class XmlDocumentTest < Test::Unit::TestCase
  def setup
    @dir = File.join( File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '.db' )
    Dir.mkdir @dir  unless File.exists? @dir
    @env = RDBXML::env @dir
    @db = @env.manager
    @docs = @db['test']
  end

  def test_metadata
    doc = @db.createDocument
    doc.name = "Test#{rand(10000)}"
    doc.content = '<test>This is a test</test>'
    doc.meta[:foo] = 123
    doc.meta['bar:stuff', 'http://nowhere.invalid/namespaces/bar'] = 'Some Stuff'
    doc.meta['baaz:stuff', 'http://nowhere.invalid/namespaces/baaz'] = 'Other Stuff'

    assert_equal doc.meta[:foo], 123
    assert_equal doc.meta['bar:stuff', 'http://nowhere.invalid/namespaces/bar'], 'Some Stuff'
    assert_equal doc.meta['baaz:stuff', 'http://nowhere.invalid/namespaces/baaz'], 'Other Stuff'
    @docs << doc

    doc = @docs[doc.name]
    assert_equal 4, doc.meta.size
    doc.meta[:foo] = nil
    doc.meta['bar:stuff', 'http://nowhere.invalid/namespaces/bar'] = nil
    doc.meta.delete 'baaz:stuff', 'http://nowhere.invalid/namespaces/baaz'

    assert_nil doc.meta[:foo]
    assert_nil doc.meta['bar:stuff', 'http://nowhere.invalid/namespaces/bar']
    assert_nil doc.meta['baaz:stuff', 'http://nowhere.invalid/namespaces/baaz']

#    @docs << doc
#    doc = @docs[doc.name]
#    assert_nil doc.meta[:foo]
#    assert_nil doc.meta['bar:stuff', 'http://nowhere.invalid/namespaces/bar']
#    assert_nil doc.meta['baaz:stuff', 'http://nowhere.invalid/namespaces/baaz']
#    assert_equal 1, doc.meta.size
  end
end

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
