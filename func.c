#include "myhead.h"
#include "y.tab.h"

symtab * push_into_table(char *lexeme1,int token1)
{
    int loopctr=0;
    initializationStack();
    symtab *table = stackTable[_blockIndex];
    /*if(first_time==0)
    {
        table=( symtab *)malloc(50*sizeof( symtab));
        first_time=1;
    }*/	
    int currentBlock = _blockIndex;
    if(decl_flag==0)
    {
       symtab *table_t = stackTable[currentBlock];
        if(DEBUG)printf("\nStart Searching block %d\n",currentBlock);
        for(loopctr=0;loopctr<_entryIndex[currentBlock];loopctr++)
        {
            if(strcmp(table_t[loopctr].lexeme,lexeme1)==0)
            {
		if(table_t[loopctr].token == 2)
			_last_checked_index = 0;
                else
                        printf("\nLine no %d--> Error:Repeated Declaration for %s\n",lineno,lexeme1);  
                return &(table_t[loopctr]);
            }       	
        }
       if(DEBUG)printf("\nCreating an entry for %s\n",lexeme1);
       table[_index123].lexeme=strdup(lexeme1);
       table[_index123].token = token1;
       table[_index123].sp_type=0;
       table[_index123].init_flag=0;
       table[_index123].value=0;
       table[_index123].no_arg=0;
       table[_index123].arg_list=NULL;
       _entryIndex[_blockIndex] = _index123+1;
       return &(table[_index123++]);

     }
     else
     {
         
	    while(currentBlock >= 0)
	    {
		symtab *table_t = stackTable[currentBlock];
		if(DEBUG)printf("\nLine no %d--> Start Searching block %d\n",lineno,currentBlock);
		for(loopctr=0;loopctr<_entryIndex[currentBlock];loopctr++)
		{
		    if(strcmp(table_t[loopctr].lexeme,lexeme1)==0)
		    {
			if(table_t[loopctr].token == 2)
				_last_checked_index = 0;
                        
		        return &(table_t[loopctr]);
		    }       	
		}
		currentBlock--;
	    }
	    printf("\nLine no %d--> Error:Undeclared identifier %s\n",lineno,lexeme1);
            un_decl_flag=1;
            return NULL;
            //exit(1);  	
    }
}

void push_parameters(symtab *sym, int type1)
{

arg_node *p;
int loopctr;
   if(_last_checked_index == -1)
{
   
   if(sym->arg_list==NULL)
    {
                 sym->arg_list=(arg_node *)malloc(sizeof(arg_node));
                 (sym->arg_list)->arg_type=type1;
                 (sym->arg_list)->next=NULL; 
    }
    else
       {
                 p=sym->arg_list;
                 while(p->next!=NULL)
                      p=p->next;
                 p->next=(arg_node *)malloc(sizeof(arg_node));
                 (p->next)->arg_type=type1;
                 (p->next)->next=NULL; 
       }
}
else
{
	p=sym->arg_list;
        for(loopctr=0;loopctr<_last_checked_index;loopctr++)
         {
            if(p!=NULL) 
               p=p->next;
         }
        _last_checked_index++;
        if(p==NULL){
             //if(DEBUG)printf("\nError :  No of arguments mismatch") ;
             return;
           }

     
        if(p->arg_type!=type1){
             printf("\nLine no %d--> Error :  parameter type mismatch",lineno) ;
		
           }
       
}
}


int get_type(char *lexeme1)
{
    int loopctr;
    int currentBlock = _blockIndex;
    while(currentBlock != 0)
    {
        symtab *table = stackTable[currentBlock];
        if(DEBUG)printf("\nStart Searching block %d\n",currentBlock);
        for(loopctr=0;loopctr<_index123;loopctr++)
        {
            if(strcmp(table[loopctr].lexeme,lexeme1)==0)
            {
                return table[loopctr].sp_type;
            }
        }
        if(DEBUG)printf("\nEnd Searching of block %d\n",currentBlock);
        currentBlock--;
    }
    return 0;
}

int get_decl(char *lexeme1)
{
    int loopctr;
    int currentBlock = _blockIndex;
    while(currentBlock != 0)
    {
        symtab *table = stackTable[currentBlock];
        if(DEBUG)printf("\nStart Searching block %d\n",currentBlock);
        for(loopctr=0;loopctr<_index123;loopctr++)
        {
            if(strcmp(table[loopctr].lexeme,lexeme1)==0)
            {
                return 1;
            }
        }
        if(DEBUG)printf("\nEnd Searching of block %d\n",currentBlock);
        currentBlock--;
    }
    return -1;
}



int initializationStack()
{
    if(start_main == 0)
    {
        stackTable = (symtab **)malloc(100*sizeof(symtab*));
        start_main = 1;
        _blockIndex = -1;
        _entryIndex = (int*)calloc(1000,sizeof(int));
        pushSymbolTable();
    }
    return 1;
}

int pushSymbolTable()
{
    symtab *symbolTable = (symtab*)malloc(100*sizeof(symtab));
    _entryIndex[_blockIndex] = _index123;
    _index123 = 0;
    if(DEBUG)printf("\nStart of block %d\n",_blockIndex+1);
    stackTable[++_blockIndex] = symbolTable;
    return _blockIndex;
}

int popSymbolTable()
{
    symtab * current = stackTable[_blockIndex];
    free(current);
    _entryIndex[_blockIndex] = 0;
    _blockIndex--;
    _index123 = _entryIndex[_blockIndex];
    if(DEBUG)printf("\nEnd of block %d\n",_blockIndex+1);
}
