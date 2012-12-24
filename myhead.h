#ifndef MYHEAD_H
#define MYHEAD_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define DEBUG 0


typedef struct 
{
    double val;
    int etype;
}expres;

typedef struct arg_node_temp
{
      int arg_type;
      struct arg_node_temp *next;
}arg_node;


typedef struct {
    char *lexeme;
    int sp_type;     //return type for func
    int token;  //1 for identifier  , 2 for function name
    double value;
    int init_flag;
    int no_arg;
    arg_node *arg_list;
}symtab;

typedef union {
                   expres exp;
                   symtab *symb;
              }expr;


extern symtab **stackTable;
//extern symtab * table;
extern int _index123,first_time;
extern int start_main,_blockIndex,decl_flag,_left_paren_func,_right_paren_func,un_decl_flag,_in_if_block;
extern int *_entryIndex;

extern int _last_checked_index;

symtab * push_into_table(char *,int);
void push_parameters(symtab *, int);
int get_type(char *);
int get_decl(char *);


int initializationStack();
int popSymbolTable();
int pushSymbolTable();

extern int lineno;
#endif
