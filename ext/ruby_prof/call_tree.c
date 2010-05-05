#include "call_tree.h"
#include "list.h"

VALUE cCallTree;
int NULL_TIME = -1;

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
	char* file;
    list children;
    int call_count;
    prof_measure_t start_time;
    prof_measure_t time;
} call_tree_t;

static int match(call_tree_t* ct, VALUE klass, ID mid, char* file)
{
	return (klass == ct->klass) && (mid == ct->mid) && (strcmp(file, ct->file) == 0);
}


static VALUE call_tree_create(VALUE self, VALUE klass, ID mid, char* file)
{
    VALUE args[4] = {self, klass, mid, file};
    return rb_class_new_instance(4, &args[0], cCallTree);
}

/* CallTreeMethod */
/* :nodoc: */
VALUE call_tree_create_root()
{
    return call_tree_create(Qnil, rb_str_new2(""), rb_str_new2(""), "");
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


VALUE call_tree_create_thread(VALUE parent, VALUE thread_id, char* file, prof_measure_t time)
{
    VALUE thread = call_tree_create(parent, rb_str_new2(""), rb_str_new2(""), file);
	get_call_tree(thread)->start_time = time;
	printf("RTEST(thread): %d", RTEST(thread));
	return thread;
}

void init_call_tree()
{
    cCallTree = rb_define_class("CallTree", rb_cObject);
    rb_define_alloc_func(cCallTree, call_tree_alloc);
    rb_define_method(cCallTree, "initialize", call_tree_initialize, 4);
    rb_define_method(cCallTree, "initialize_copy", call_tree_initialize_copy, 3);
    rb_define_method(cCallTree, "[]", call_tree_fetch, 1);
    rb_define_method(cCallTree, "size", call_tree_size, 0);
    rb_define_method(cCallTree, "parent", call_tree_parent, 0);
    rb_define_method(cCallTree, "children", call_tree_children, 0);
    rb_define_method(cCallTree, "method", call_tree_method, 0);
    rb_define_method(cCallTree, "klass", call_tree_klass, 0);
    rb_define_method(cCallTree, "time", call_tree_time, 0);
    rb_define_method(cCallTree, "file", call_tree_file, 0);
    rb_define_method(cCallTree, "call_count", call_tree_call_count, 0);
    rb_define_method(cCallTree, "method_start", call_tree_method_start, 4);
    rb_define_method(cCallTree, "method_stop", call_tree_method_stop, 1);
}

VALUE call_tree_initialize(VALUE self, VALUE parent, VALUE klass, ID mid, char* file)
{
    call_tree_t* ct = get_call_tree(self);
    ct->mid = mid;
    ct->klass = klass;
    ct->parent = parent;
	ct->file = file;
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

VALUE call_tree_add(VALUE self, VALUE klass, ID mid, char* file)
{
    VALUE child = call_tree_create(self, klass, mid, file);
    list_add(get_call_tree(self)->children, child);
    return child;
}

VALUE call_tree_find_parent(VALUE self, VALUE klass, ID mid, char* file)
{
	if (NIL_P(self)) { return Qnil; }	
	call_tree_t* ct = get_call_tree(self);
		
    if (match(ct, klass, mid, file))
    {
        return self;
    }
 
	return call_tree_find_parent(ct->parent, klass, mid, file);
}

VALUE call_tree_method_start(VALUE self, VALUE klass, ID mid, char* file, prof_measure_t time)
{
    if (NIL_P(self)) { return self; }
    if (klass == cCallTree) { return self; }
	
	int is_recursive = 0;
    VALUE method_call = call_tree_find_child(self, klass, mid, file);
    if (NIL_P(method_call))
    {
	    method_call = call_tree_find_parent(self, klass, mid, file);
	    if (NIL_P(method_call))
	    {
           method_call = call_tree_add(self, klass, mid, file);
	    }
	    else
	    {
			is_recursive = 1;
	    }
    }
    else if (NIL_P(call_tree_find_parent(self, klass, mid, file)))
    {
        is_recursive = 1;
    }

	call_tree_t* ct = get_call_tree(method_call);
	if (!is_recursive || ct->start_time == NULL_TIME) 
	{ 
		ct->start_time = time;
    }
    ct->call_count++;
    return method_call;
}


VALUE call_tree_method_stop(VALUE self, prof_measure_t time)
{
    if (NIL_P(self)) { return self; }

    call_tree_t* ct = get_call_tree(self);

    if (NIL_P(call_tree_find_parent(ct->parent, ct->klass, ct->mid, ct->file))) 
    {
        prof_measure_t ct_time = ct->time;
	    prof_measure_t start_time = ct->start_time;
	    prof_measure_t diff = time - start_time;
	    ct_time += diff;
	    ct->time = ct_time;
		ct->start_time = NULL_TIME;
    }
    return ct->parent;
}

VALUE call_tree_find_child(VALUE self, VALUE klass, ID mid, char* file)
{
    list children = get_call_tree(self)->children;
    int size = list_size(children);

    int i;
    for (i=0; i < size; i++)
    {
        VALUE child = list_get(children, i);
        call_tree_t* ct = get_call_tree(child);
        if (match(ct, klass, mid, file)) 
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

VALUE call_tree_file(VALUE self)
{
	return rb_str_new2(get_call_tree(self)->file);
}