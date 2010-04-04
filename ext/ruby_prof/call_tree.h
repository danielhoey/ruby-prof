#ifndef CALL_TREE
#define CALL_TREE 

#include <ruby.h>
#include <st.h>
#include "measurement.h"

void init_call_tree();
VALUE call_tree_create_root();

VALUE call_tree_initialize(VALUE self, VALUE parent, VALUE klass, VALUE method);
VALUE call_tree_initialize_copy(VALUE copy, VALUE original);
VALUE call_tree_children(VALUE self);
VALUE call_tree_fetch(VALUE self, VALUE index);
VALUE call_tree_add(VALUE self, VALUE klass, VALUE method);
VALUE call_tree_size(VALUE self);
VALUE call_tree_find_child(VALUE self, VALUE klass, VALUE method);
VALUE call_tree_method_start(VALUE self, VALUE klass, ID mid, prof_measure_t time);
VALUE call_tree_method_stop(VALUE self, prof_measure_t time);
VALUE call_tree_to_s(VALUE self);

VALUE call_tree_parent(VALUE self);
VALUE call_tree_method(VALUE self);
VALUE call_tree_klass(VALUE self);
VALUE call_tree_time(VALUE self);
VALUE call_tree_call_count(VALUE self);

#endif