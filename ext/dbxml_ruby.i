%module dbxml
%include "std_string.i"

%exception {
  try {
    $action
  } catch ( DbException &ex ) {
    static VALUE rb_DBException = rb_define_class("DBException", rb_eStandardError);
    rb_raise( rb_DBException, ex.what() );
  } catch ( DbXml::XmlException &ex ) {
    static VALUE rb_XmlException = rb_define_class("XmlException", rb_eStandardError);
    rb_raise( rb_XmlException, ex.what() );
  }
}
