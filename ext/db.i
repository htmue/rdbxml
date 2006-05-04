%module db
%include "exception.i"
%include "typemaps.i"

%exception {
  try {
    $action
  } catch ( DbException &ex ) {
    static VALUE rb_DBException = rb_define_class("DBException", rb_eStandardError);
    rb_raise( rb_DBException, ex.what() );
  }
}

%ignore DbMpoolFile::get_transactional;
%include "db_cxx.h"

%{
#include "db_cxx.h"
%}

typedef unsigned int u_int32_t;
typedef int int32_t;

