#include "ej1.h"

string_proc_list *string_proc_list_create(void)
{
	string_proc_list *lista;
	lista = malloc(sizeof(string_proc_list));
	lista->first = NULL;
	lista->last = NULL;
	return lista;
}

string_proc_node *string_proc_node_create(uint8_t type, char *hash)
{
	string_proc_node *node;
	node = malloc(sizeof(string_proc_node));
	node->hash = hash;
	node->type = type;
	node->next = NULL;
	node->previous = NULL;
	return node;
}

void string_proc_list_add_node(string_proc_list *list, uint8_t type, char *hash)
{
	string_proc_node *newnode = string_proc_node_create(type, hash);
	if (list->first == NULL)
	{
		list->first = newnode;
		list->last = newnode;
	}
	else
	{
		string_proc_node *oldnode = list->last;
		list->last = newnode;
		list->last->previous = oldnode;
		oldnode->next = list->last;
	}
}

char *string_proc_list_concat(string_proc_list *list, uint8_t type, char *hash)
{
	char *string = NULL;
	char *aux;
	string_proc_node *current_node = list->first;

	while (current_node != NULL)
	{
		if (current_node->type == type)
		{
			if (string == NULL)
			{
				string = malloc(strlen(current_node->hash) + 1);
				if (string == NULL)
					return NULL;
				strcpy(string, current_node->hash);
			}
			else
			{
				aux = string;
				string = str_concat(aux, current_node->hash);
				free(aux);
			}
		}
		current_node = current_node->next;
	}

	if (string == NULL)
	{
		if (hash != NULL)
		{
			string = malloc(strlen(hash) + 1);
			if (string == NULL)
				return NULL;
			strcpy(string, hash);
			return string;
		}
		return NULL;
	}

	if (hash != NULL)
	{
		aux = string;
		string = str_concat(hash, string);
		free(aux);
	}

	return string;
}

/** AUX FUNCTIONS **/

void string_proc_list_destroy(string_proc_list *list)
{

	/* borro los nodos: */
	string_proc_node *current_node = list->first;
	string_proc_node *next_node = NULL;
	while (current_node != NULL)
	{
		next_node = current_node->next;
		string_proc_node_destroy(current_node);
		current_node = next_node;
	}
	/*borro la lista:*/
	list->first = NULL;
	list->last = NULL;
	free(list);
}
void string_proc_node_destroy(string_proc_node *node)
{
	node->next = NULL;
	node->previous = NULL;
	node->hash = NULL;
	node->type = 0;
	free(node);
}

char *str_concat(char *a, char *b)
{
	int len1 = strlen(a);
	int len2 = strlen(b);
	int totalLength = len1 + len2;
	char *result = (char *)malloc(totalLength + 1);
	strcpy(result, a);
	strcat(result, b);
	return result;
}

void string_proc_list_print(string_proc_list *list, FILE *file)
{
	uint32_t length = 0;
	string_proc_node *current_node = list->first;
	while (current_node != NULL)
	{
		length++;
		current_node = current_node->next;
	}
	fprintf(file, "List length: %d\n", length);
	current_node = list->first;
	while (current_node != NULL)
	{
		fprintf(file, "\tnode hash: %s | type: %d\n", current_node->hash, current_node->type);
		current_node = current_node->next;
	}
}
