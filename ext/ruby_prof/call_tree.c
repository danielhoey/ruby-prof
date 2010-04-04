#include "call_tree.h"
#include "list.h"
//#include "ruby_prof.h"



#define MARK() printf("%d\n", __LINE__);

// TODO: move this to a header file and share with ruby_prof.c (check on mac osx)
//prof_measure_t (*get_measurement)();
//double (*convert_measurement)(prof_measure_t);

VALUE cCallTree;

prof_measure_t g_create_time = 0;
double g_find_time = 0.0;

char * ValueToString(VALUE v) 
{
  if (NIL_P(v)) { return "nil"; }
  //if (RTEST(rb_obj_is_instance_of(v, cCallTree))) { return "CallTree"; }
  VALUE s = rb_funcall(v, rb_intern("to_s"), 0);
  return StringValuePtr(s);
}


static VALUE method_name_text(ID mid)
{
    char* name = rb_id2name(mid);
    if (name == NULL) return rb_str_new2("[No method]");
    else            return rb_str_new2(name);
}

typedef struct call_tree_t {
    ID mid;
    VALUE klass;
    VALUE parent;
    list children;
    int call_count;
    prof_measure_t start_time;
    prof_measure_t time;
} call_tree_t;

static VALUE call_tree_create(VALUE self, VALUE klass, ID mid)
{
    VALUE args[3] = {self, klass, mid};
    return rb_class_new_instance(3, &args[0], cCallTree);
}

/* CallTreeMethod */
/* :nodoc: */
VALUE call_tree_create_root()
{
    return call_tree_create(Qnil, rb_str_new2(""), rb_str_new2(""));
}

static int mark(st_data_t key, st_data_t value, st_data_t data)
{
    rb_gc_mark(value);
    return ST_CONTINUE;
}

static void call_tree_mark(call_tree_t* ct)
{
    rb_gc_mark(ct->klass);
    rb_gc_mark(ct->parent);

    //mark each of the children
    int i;
    for(i=0; i<list_size(ct->children); i++)
    {
        rb_gc_mark(list_get(ct->children, i));
    }
}

static void call_tree_free(call_tree_t* ct)
{
    delete_list(ct->children);
    xfree(ct);
}

static VALUE call_tree_alloc(VALUE klass)
{
    call_tree_t* call_tree_stuct;
    call_tree_stuct = ALLOC(call_tree_t);
    call_tree_stuct->children = new_list(10);
    return Data_Wrap_Struct(klass, call_tree_mark, call_tree_free, call_tree_stuct);
}

static call_tree_t* 
get_call_tree(VALUE c_call_tree)
{
    call_tree_t* ct;
    Data_Get_Struct(c_call_tree, call_tree_t, ct);
    return ct;
}

void init_call_tree()
{
    cCallTree = rb_define_class("CallTree", rb_cObject);
    rb_define_alloc_func(cCallTree, call_tree_alloc);
    rb_define_method(cCallTree, "initialize", call_tree_initialize, 3);
    rb_define_method(cCallTree, "initialize_copy", call_tree_initialize_copy, 3);
    rb_define_method(cCallTree, "[]", call_tree_fetch, 1);
    rb_define_method(cCallTree, "size", call_tree_size, 0);
    rb_define_method(cCallTree, "add", call_tree_add, 2);
    rb_define_method(cCallTree, "find_child", call_tree_find_child, 2);
    rb_define_method(cCallTree, "parent", call_tree_parent, 0);
    rb_define_method(cCallTree, "children", call_tree_children, 0);
    rb_define_method(cCallTree, "method", call_tree_method, 0);
    rb_define_method(cCallTree, "klass", call_tree_klass, 0);
    rb_define_method(cCallTree, "time", call_tree_time, 0);
    rb_define_method(cCallTree, "call_count", call_tree_call_count, 0);
    rb_define_method(cCallTree, "method_start", call_tree_method_start, 3);
    rb_define_method(cCallTree, "method_stop", call_tree_method_stop, 1);
}

VALUE call_tree_initialize(VALUE self, VALUE parent, VALUE klass, ID mid)
{
    //printf("call_tree_initialize(%s, %s, %s)\n", ValueToString(parent), ValueToString(klass), rb_id2name(mid));
    call_tree_t* ct = get_call_tree(self);
    ct->mid = mid;
    ct->klass = klass;
    ct->parent = parent;
    ct->time = 0;
    ct->call_count = 0;
    return self;
}

VALUE call_tree_initialize_copy(VALUE copy, VALUE original)
{
    return copy;
}

VALUE call_tree_children(VALUE self)
{
    list children = get_call_tree(self)->children;
    return rb_ary_new4(list_size(children), list_data(children));
}

VALUE call_tree_fetch(VALUE self, VALUE index)
{
    return list_get(get_call_tree(self)->children, NUM2INT(index));
}

VALUE call_tree_size(VALUE self)
{
    return INT2NUM(call_tree_size2(self));
}

int call_tree_size2(VALUE self)
{
    list children = get_call_tree(self)->children;
    int i;
    int size = list_size(children);
    int total_size = size;
    for (i=0; i < size; i++)
    {
        total_size += call_tree_size2(list_get(children, i));
    }
    return total_size; 
}

VALUE call_tree_add(VALUE self, VALUE klass, ID mid)
{
    //printf("call_tree_add(%s, %s, %s)\n", ValueToString(self), ValueToString(klass), rb_id2name(mid));
    VALUE child = call_tree_create(self, klass, mid);
    list_add(get_call_tree(self)->children, child);
    return child;
}


VALUE call_tree_method_start(VALUE self, VALUE klass, ID mid, prof_measure_t time)
{
    if (NIL_P(self)) { return self; }

    //printf("method '[]' has id %d\n", rb_intern("[]"));
    //printf("method (%d) '%s' called\n", mid, rb_id2name(mid));
   
    if (klass == cCallTree)
    {
        printf("method '%s' called on CallTree class\n", rb_id2name(mid));
        return self;
    }

    //printf("call_tree_method_start(%s, %s, %s)\n", ValueToString(self), ValueToString(klass), rb_id2name(mid));

    VALUE method_call = call_tree_find_child(self, klass, mid);
    if (method_call == Qnil)
    {
        //printf("new node added to call tree\n");
        method_call = call_tree_add(self, klass, mid);
    }

    if (method_call == Qnil)
    {
        printf("method_call is nil!\n");
    }

    get_call_tree(method_call)->start_time = time;
    get_call_tree(method_call)->call_count++;
    return method_call;
}

VALUE call_tree_method_stop(VALUE self, prof_measure_t time)
{
    if (NIL_P(self)) { return self; }
    //printf("call_tree_method_stop(%s)\n", ValueToString(self));
    call_tree_t* ct = get_call_tree(self);
    prof_measure_t ct_time = ct->time;
    prof_measure_t start_time = ct->start_time;
    prof_measure_t diff = time - start_time;
    ct_time += diff;
    ct->time = ct_time;
    return ct->parent;
}

VALUE call_tree_find_child(VALUE self, VALUE klass, ID mid)
{
    //printf("call_tree_find(%s, %s, %s)\n", ValueToString(self), ValueToString(klass), rb_id2name(mid));
    list children = get_call_tree(self)->children;
    int size = list_size(children);

    int i;
    for (i=0; i < size; i++)
    {
        VALUE child = list_get(children, i);
        call_tree_t* ct = get_call_tree(child);
        if (klass == ct->klass && mid == ct->mid)
        {
            return child;
        }
    }
    return Qnil;
}

VALUE call_tree_method(VALUE self)
{
    return method_name_text(get_call_tree(self)->mid);
}

VALUE call_tree_klass(VALUE self)
{
    return get_call_tree(self)->klass;
}

VALUE call_tree_time(VALUE self)
{
    return rb_float_new(convert_measurement(get_call_tree(self)->time));
}

VALUE call_tree_call_count(VALUE self)
{
    return rb_int_new(get_call_tree(self)->call_count);
}

VALUE call_tree_parent(VALUE self)
{
    return get_call_tree(self)->parent;
}

/*
VALUE call_tree_to_s(VALUE self)
{
    return rb_str_new2("CallTree");
}
*/
