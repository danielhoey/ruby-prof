#include <ruby.h>

typedef struct list_t* list;
typedef VALUE list_data_t;

list new_list(int size);
void list_add(list l, list_data_t data);
list_data_t list_get(list l, int index);
int list_size(list l);
list_data_t* list_data(list l);
