%module dbxml
%include "std_string.i"

%alias XmlManager::createQueryContext "create_query_context";

%alias XmlContainer::getManager "manager";

%alias XmlDocument::getContentAsString "to_s";
%alias XmlDocument::getName "name";
%alias XmlDocument::setName "name=";
%alias XmlDocument::getContent "content";
%alias XmlDocument::setContent "content=";

%alias XmlQueryContext::getNamespace "get_namespace";
%alias XmlQueryContext::setNamespace "set_namespace";
%alias XmlQueryContext::getDefaultCollection "default_collection";
%alias XmlQueryContext::setDefaultCollection "default_collection=";
%alias XmlQueryContext::getVariableValue "[]";
%alias XmlQueryContext::setVariableValue "[]=";

%alias XmlValue::asString "to_s";
%alias XmlValue::asNumber "to_f";
%alias XmlValue::asDocument "to_doc";

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
