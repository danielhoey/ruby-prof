#ifndef CALL_TREE
#define CALL_TREE 

#include <ruby.h>
#include <st.h>
#include "measurement.h"

void init_call_tree();
VALUE call_tree_create_root();
VALUE call_tree_create_thread(VALUE parent, char* thread_id, char* file, prof_measure_t time);

VALUE call_tree_initialize(VALUE self, VALUE parent, VALUE klass_text, VALUE method, char* file);
VALUE call_tree_initialize_copy(VALUE copy, VALUE original);
VALUE call_tree_children(VALUE self);
VALUE call_tree_fetch(VALUE self, VALUE index);
VALUE call_tree_add(VALUE self, ID klass, ID mid, char* file);
VALUE call_tree_size(VALUE self);
VALUE call_tree_find_child(VALUE self, ID klass, ID mid, char* file);
VALUE call_tree_method_start(VALUE self, VALUE klass_text, ID mid, char* file, prof_measure_t time);
VALUE call_tree_method_stop(VALUE self, prof_measure_t time);
void call_tree_method_pause(VALUE self, prof_measure_t time);
void call_tree_method_resume(VALUE self, prof_measure_t time);
VALUE call_tree_to_s(VALUE self);

VALUE call_tree_parent(VALUE self);
VALUE call_tree_method(VALUE self);
VALUE call_tree_klass(VALUE self);
VALUE call_tree_time(VALUE self);
VALUE call_tree_file(VALUE self);
VALUE call_tree_call_count(VALUE self);

#endif
