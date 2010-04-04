#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <assert.h>
#include <ruby.h>
#include "list.h"

typedef struct list_t{
  int allocated_size;
  int assigned_size;
  list_data_t* data;
} list_t;


list new_list(int size)
{
    list new_list = (list) ALLOC(list_t);
    list_data_t* data = (list_data_t*) ALLOC_N(list_data_t, size);

    new_list->allocated_size = size;
    new_list->assigned_size = 0;
    new_list->data = data;

    return new_list;
}

void delete_list(list l)
{
    xfree(l->data);
}

void list_add(list l, list_data_t item)
{
    if (l->assigned_size >= l->allocated_size)
    {
        int new_allocated_size = l->allocated_size*2;
        list_data_t* new_data = (list_data_t*) ALLOC_N(list_data_t, new_allocated_size);
        int i;
        for (i=0; i<l->allocated_size; i++)
        {
            new_data[i] = l->data[i]; 
        }
        xfree(l->data);
        l->data = new_data;
        l->allocated_size = new_allocated_size;
    }

    l->data[l->assigned_size] = item;
    l->assigned_size++; 
}

list_data_t list_get(list l, int index)
{
    assert(index < l->allocated_size);
    return l->data[index];
}

int list_size(list l)
{
    return l->assigned_size;
}

list_data_t* list_data(list l)
{
    return l->data;
}
