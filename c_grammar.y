%{
#include <stdlib.h>
#include <stdio.h>
#include "myhead.h"
int yylex(void);
//void type_mis_chk(expr,expr);
//void yyerror(char *);
//map<char*, symtab*> varSymTab;
symtab ** stackTable;
int _index123=0,first_time=0;
int str_type_no=50, first_type=0,dec_type;
int start_main=0,_blockIndex=-1,func_call_flag=-1,un_decl_flag=0, _in_if_block=0,_check_assignment=0;
int *_entryIndex;
int _last_checked_index=-1,_left_paren_func=0,_right_paren_func=0;

int lineno=1;
%}


%union
{
    int dtype;//data types
    symtab *symb;//pointer to symbol table
    expr ex;
    double numval;//handle to values
    int blockno;
}



%token <symb>IDENTIFIER 
%token <ex>CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN 
%token <dtype> TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%type <ex> primary_expression argument_expression_list
%type <dtype> type_specifier struct_or_union_specifier enum_specifier type_qualifier storage_class_specifier parameter_declaration
%type <dtype> declaration_specifiers specifier_qualifier_list type_name 
%type <symb> init_declarator_list init_declarator declarator direct_declarator 
%type <ex> postfix_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression 
%type <ex> relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_or_expression 
%type <ex> logical_and_expression conditional_expression assignment_expression expression constant_expression initializer initializer_list
%type <blockno> '{'
%start translation_unit
%%

primary_expression
	: IDENTIFIER                          {//if(($1)->sp_type == 0)
				               //      if(DEBUG)printf("Error:Id %s is Undeclared\n",$1->lexeme);
                                               if(un_decl_flag==0){ 
                                               if($1->token==1)
			                             ($$).exp.etype=($1)->sp_type;
                                               else
                                                      {$$.symb=$1;func_call_flag=0;}}}
	| CONSTANT                            {($$).exp.etype=($1).exp.etype;}
	| STRING_LITERAL
	| '(' expression ')'                  {($$).exp.etype=($2).exp.etype;}
	;

postfix_expression
	: primary_expression                                                       {if(un_decl_flag==0){ if(func_call_flag==-1)
                                                                                            $$.exp.etype=$1.exp.etype;
                                                                                    else
                                                                                           {$$.symb=$1.symb;func_call_flag=-1;}}}
	| postfix_expression '[' expression ']'                                    {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;
                                                                                   if(get_last_type_spec($3.exp.etype)==15||get_last_type_spec($3.exp.etype)==16) 
                                                                                          printf("\nLine no %d--> Error:Array index must be integral\n",lineno);
                                                                                   else if(get_last_type_spec($3.exp.etype)==11)
                                                                                           printf("\nLine no %d--> Warning:Array index is char\n",lineno);}}
	| postfix_expression '(' ')'                                               {if(un_decl_flag==0){ $$.exp.etype=($1.symb)->sp_type;
                                                                                   if($1.symb->no_arg!=_last_checked_index)
                                                                                          printf("\nLine no %d--> Error: No of arguments mismatch\n",lineno);
                                                                                   _last_checked_index=-1;}} 
	| postfix_expression '(' argument_expression_list ')'                      {if(un_decl_flag==0){ $$.exp.etype=($1.symb)->sp_type;
                                                                                   if($1.symb->no_arg!=_last_checked_index)
                                                                                        printf("\nLine no %d--> Error: No of arguments mismatch\n",lineno);
                                                                                   _last_checked_index=-1;}}
	| postfix_expression '.' IDENTIFIER                                        {$$.exp.etype=$1.exp.etype;}    // consider later
	| postfix_expression PTR_OP IDENTIFIER                                     {$$.exp.etype=$1.exp.etype;}    // consider later
	| postfix_expression INC_OP                                                {$$.exp.etype=$1.exp.etype;}
	| postfix_expression DEC_OP                                                {$$.exp.etype=$1.exp.etype;}
	;

argument_expression_list
	: assignment_expression                                                    {if(un_decl_flag==0){ push_parameters($<ex>-1.symb,$1.exp.etype);}}
	| argument_expression_list ',' assignment_expression                       {if(un_decl_flag==0){ push_parameters($<ex>-1.symb,$3.exp.etype);}}
	;

unary_expression
	: postfix_expression              {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| INC_OP unary_expression         {if(un_decl_flag==0){ $$.exp.etype=$2.exp.etype;}}
	| DEC_OP unary_expression         {if(un_decl_flag==0){ $$.exp.etype=$2.exp.etype;}}
	| unary_operator cast_expression  {if(un_decl_flag==0){ $$.exp.etype=$2.exp.etype;}}
	| SIZEOF unary_expression         {if(un_decl_flag==0){ $$.exp.etype=$2.exp.etype;}}
	| SIZEOF '(' type_name ')'        {if(un_decl_flag==0){ $$.exp.etype=$3;}}   
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression                                                {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| '(' type_name ')' cast_expression                               {$$.exp.etype=$2;}  
	;

multiplicative_expression
	: cast_expression                                                 {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| multiplicative_expression '*' cast_expression                   {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}
	| multiplicative_expression '/' cast_expression                   {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}
	| multiplicative_expression '%' cast_expression                   {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}} 
	;

additive_expression
	: multiplicative_expression                                       {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| additive_expression '+' multiplicative_expression               {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}
	| additive_expression '-' multiplicative_expression               {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}
	;

shift_expression
	: additive_expression                                             {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| shift_expression LEFT_OP additive_expression                    {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	| shift_expression RIGHT_OP additive_expression                   {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

relational_expression
	: shift_expression                                                {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| relational_expression '<' shift_expression                      {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	| relational_expression '>' shift_expression                      {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	| relational_expression LE_OP shift_expression                    {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	| relational_expression GE_OP shift_expression                    {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

equality_expression
	: relational_expression                                          {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| equality_expression EQ_OP relational_expression                {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	| equality_expression NE_OP relational_expression                {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

and_expression
	: equality_expression                                           {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| and_expression '&' equality_expression                        {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;    

exclusive_or_expression
	: and_expression                                                {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| exclusive_or_expression '^' and_expression                    {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

inclusive_or_expression
	: exclusive_or_expression                                      {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| inclusive_or_expression '|' exclusive_or_expression          {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

logical_and_expression
	: inclusive_or_expression                                     {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| logical_and_expression AND_OP inclusive_or_expression       {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

logical_or_expression
	: logical_and_expression                                      {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| logical_or_expression OR_OP logical_and_expression          {if(un_decl_flag==0){ $$.exp.etype=type_conv($1.exp.etype,$3.exp.etype);}}

	;

conditional_expression
	: logical_or_expression                                              {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| logical_or_expression '?' expression ':' conditional_expression    {if(un_decl_flag==0){ $$.exp.etype=type_conv(type_conv($1.exp.etype,$3.exp.etype),$5.exp.etype);}}

	;

assignment_expression
	: conditional_expression                                            {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| unary_expression assignment_operator assignment_expression        {if(un_decl_flag==0){ $$.exp.etype=type_error($1.exp.etype,$3.exp.etype);}}  
	;

assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| SUB_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

expression
	: assignment_expression                                          {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	| expression ',' assignment_expression                           {}
	;

constant_expression
	: conditional_expression                                         {if(un_decl_flag==0){ $$.exp.etype=$1.exp.etype;}}
	;

declaration
	: declaration_specifiers ';'                                {decl_flag=-1;un_decl_flag=0;}
	| declaration_specifiers init_declarator_list ';'           {decl_flag=-1;un_decl_flag=0;if(_right_paren_func==1)
                                                                       {popSymbolTable();_left_paren_func=0;_right_paren_func=0;}}    
	;

declaration_specifiers
	: storage_class_specifier                                  {$$=$1;dec_type=$$;}
	| storage_class_specifier declaration_specifiers           {$$=$2*100+$1;dec_type=$$;}
	| type_specifier                                           {$$=$1;dec_type=$$;}  
	| type_specifier declaration_specifiers                    {$$=$2*100+$1;dec_type=$$;}
	| type_qualifier                                           {$$=$1;dec_type=$$;}
	| type_qualifier declaration_specifiers                    {$$=$2*100+$1;dec_type=$$;}
	;

init_declarator_list
	: init_declarator                                         {if($1->sp_type==0)
                                                                            $1->sp_type=$<dtype>0; 
                                                                  //else
                                                                  //          if($1->token==1)
                                                                  //                 if(DEBUG)printf("\nLine no %d--> Redeclaration error\n",lineno); 
                                                                  if(DEBUG)printf("\nLine no %d--> Id %s has type %d\n",lineno,$1->lexeme,$1->sp_type);}
	| init_declarator_list COMMA init_declarator                {$1=$$; 
                                                                   if($3->sp_type==0)
                                                                        $3->sp_type=$<dtype>0;
                                                                   //else
                                                                   //     if($3->token==1) 
                                                                   //         if(DEBUG)printf("\nLine no %d--> Redeclaration error\n",lineno); 
                                                                   if(DEBUG)printf("\nLine no %d--> Id %s has type %d\n",lineno,$3->lexeme,$3->sp_type);}
	;

COMMA   : ','                    {decl_flag=0;un_decl_flag=0;}
        ;

init_declarator
	: declarator                                               {$$=$1;}               
	| declarator EQL initializer                               {$$=$1;if(un_decl_flag==0){type_error(dec_type,$3.exp.etype);}} 
	;

EQL     : '='                    {decl_flag=-1;}
        ;                

storage_class_specifier
	: TYPEDEF                {$$=20;}
	| EXTERN                 {$$=21;}
	| STATIC                 {$$=22;} 
	| AUTO                   {$$=23;}
	| REGISTER               {$$=24;}
	;

type_specifier
	: VOID                   {$$=10;}
	| CHAR                   {$$=11;}
	| SHORT                  {$$=12;}
	| INT                    {$$=13;}
	| LONG                   {$$=14;}
	| FLOAT                  {$$=15;}
	| DOUBLE                 {$$=16;}
	| SIGNED                 {$$=17;}
	| UNSIGNED               {$$=18;}
	| struct_or_union_specifier {$$=$1;}
	| enum_specifier {$$=$1;}
	| TYPE_NAME      //  consider later
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'         {$$=str_type_no; str_type_no++;}
	| struct_or_union '{' struct_declaration_list '}'                    {$$=str_type_no; str_type_no++;}
	| struct_or_union IDENTIFIER                                         {$$=str_type_no; str_type_no++;}
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list       {$$=$2*100+$1;}
	| type_specifier                                {$$=$1;}
	| type_qualifier specifier_qualifier_list       {$$=$2*100+$1;}
	| type_qualifier                                {$$=$1;}
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'                 {$$=str_type_no; str_type_no++;}
	| ENUM IDENTIFIER '{' enumerator_list '}'      {$$=str_type_no; str_type_no++;}
	| ENUM IDENTIFIER                              {$$=str_type_no; str_type_no++;}   
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST            {$$=30;}
	| VOLATILE         {$$=31;}  
	;

declarator
	: pointer direct_declarator         {$$=$2;}
	| direct_declarator                 {$$=$1;} 
	;

direct_declarator
	: IDENTIFIER                                        {$$=$1;}
	| '(' declarator ')'                                {}  
	| direct_declarator '[' constant_expression ']'     {if(get_last_type_spec($3.exp.etype)==15||get_last_type_spec($3.exp.etype)==16) 
                                                                  printf("\nLine no %d--> Error:Array index must be integral\n",lineno);
                                                            else if(get_last_type_spec($3.exp.etype)==11)
                                                                  printf("\nLine no %d--> Warning:Array index is char\n",lineno);}
	| direct_declarator '[' ']'
	| direct_declarator M parameter_type_list ')'     {   if($1->sp_type==0)
								     $1->sp_type=$<dtype>0;
								$1->token=2;
							             if(DEBUG)printf("\nLine no %d--> function: name %s,ret type %d, no  of args=%d Parameter types are:",lineno,$1->lexeme,$1->sp_type,$1->no_arg);
                                                            arg_node *p=$1->arg_list; 
                                                            while(p!=NULL)
                                                                    {if(DEBUG)printf("%d\t",p->arg_type);p=p->next;}
							    if(_last_checked_index!=-1&&$1->no_arg!=_last_checked_index)
                                                                    printf("\nLine no %d--> Error: No of arguments mismatch",lineno);
                                                            _last_checked_index = -1; _right_paren_func=1;}
	| direct_declarator '(' identifier_list ')'         {} 
	| direct_declarator M ')'                         {if($1->sp_type==0)
                                                                $1->sp_type=$<dtype>0;
                                                            $1->token=2;
							     if(DEBUG)printf("\nLine no %d--> function: name %s,ret type %d, no  of args=%d",lineno,$1->lexeme,$1->sp_type,$1->no_arg);                                       
                                                             if(_last_checked_index!=-1&&$1->no_arg!=_last_checked_index)
                                                                    printf("\nLine no %d--> Error: No of arguments mismatch",lineno);
                                                            _last_checked_index = -1; _right_paren_func=1; } 
	;
M 	:  '('                     {_left_paren_func=1;pushSymbolTable();}
	;
pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list  {}                   
	| parameter_list ',' ELLIPSIS {}
	;

parameter_list
	: parameter_declaration                              {if(_last_checked_index == -1)($<symb>0)->no_arg++;push_parameters($<symb>0,$1);}
	| parameter_list ',' parameter_declaration           {if(_last_checked_index == -1)($<symb>0)->no_arg++;push_parameters($<symb>0,$3);}
	;

parameter_declaration
	: declaration_specifiers declarator                  {$$=$1;
                                                              if($2->sp_type==0)
                                                                      $2->sp_type=$1;
                                                              //else
                                                              //        if(DEBUG)printf("\nLine no %d--> Redeclaration error\n",lineno);   
                                                               }
	| declaration_specifiers abstract_declarator         {$$=$1;}
	| declaration_specifiers                             {$$=$1;}
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list                           {$$=$1;}
	| specifier_qualifier_list abstract_declarator       {$$=$1;}
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expression ']'   {if(get_last_type_spec($3.exp.etype)==15||get_last_type_spec($3.exp.etype)==16) 
                                                                           printf("\nLine no %d--> Error:Array index must be integral\n",lineno);
                                                                   else if(get_last_type_spec($3.exp.etype)==11)
                                                                           printf("\nLine no %d--> Warning:Array index is char\n",lineno);}
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expression               {$$=$1;}                
	| '{' initializer_list '}'            {$$=$2;}
	| '{' initializer_list ',' '}'        {$$=$2;} 
	;

initializer_list
	: initializer                         {$$=$1;} 
	| initializer_list ',' initializer    {$$=$3;}
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' statement_list '}'
	| '{' declaration_list '}'
	| '{' declaration_list statement_list '}'
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

statement_list
	: statement
	| statement_list statement
	;

expression_statement
	: ';'               {decl_flag=-1;un_decl_flag=0;}
	| expression ';'    {decl_flag=-1;un_decl_flag=0;}
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	;

jump_statement
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement         {if($2->sp_type==0)
                                                                          { 
									         $2->sp_type=$1; $2->token=2;
                                                                          }
                                                                        else
                                                                             {
                                                                             if($2->sp_type!=$1)
										{
											printf("\nLine no %d--> Error: Function return type mismatch\n",lineno);
										}}
                                                                      
									_last_checked_index = -1;
									}
	| declarator declaration_list compound_statement
	| declarator compound_statement
	;

%%
#include <stdio.h>

extern char yytext[];
extern int column;

void yyfinalize()
{
    /*
    if(DEBUG)printf("> Variables created:\n");
    map<char*, symtab*>::iterator iter;   
    for(iter = varSymTab.begin(); iter != varSymTab.end(); iter++)
    {
       if(DEBUG)printf("%s -> %d\n",(iter->first),(iter->second->value));
    }
    varSymTab.clear();*/
}



int main()
{
   yyparse();
   yyfinalize();
   return 1;
}

int type_conv(int type1,int type2)
{
    if(type1==1614||type2==1614)
            return 1614;
    else  
         {
           if(type1==16||type2==16)
               return 16;
           else  
           {
                 if(type1==15||type2==15)
                       return 15;
                 else  
                 {
                       if(get_last_type_spec(type1)==11||get_last_type_spec(type1)==12)              //Integral promotion
                               type1=int_promo(type1);
                       if(get_last_type_spec(type2)==11||get_last_type_spec(type2)==12)             //Integral promotion 
                               type2=int_promo(type2);
                       if(type1==131418||type2==131418)
                               return 131418;
                       else  
                       {
                                if((type1==1314&&type2==1318)||(type2==1314&&type1==1318))
                                               return 1314;
                                else
                                {
                                           if(type1==1314||type2==1314)
                                                   return 1314;
                                           else  
                                           {
                                                    if(type1==1318||type2==1318)
                                                               return 1318;
                                                    else
                                                    {
                                                               return 13;
                                                    }
                                           } 
                                }
                       }
                 }
             }
         } 

}

int get_last_type_spec(int k)
{
   int p=0;
   while(k!=0)
   {
          p=k%100;
          k=k/100;
   }
   return p;
} 

int int_promo(int k)
{
   int p=0,q=0;
   //printf("k=%d",k);
   while(k/100!=0)
   {
         p=k%100;
         k=k/100;
         q=q*100+p;
   }
   q=q*100+13;
   k=0;
   while(q!=0)
   {
         p=q%100;
         q=q/100;
         k=k*100+p;
   }
   //printf("k=%d",k);
   return k;
}

char * typeName(int type)
{
   char *tname=(char *)malloc(30*sizeof(char)); 
   while(type!=0)
   {
        switch(type%100)
        {
	case 20: 
		tname=strcat(tname," TYPEDEF");
		break;
	case 21: 
		tname=strcat(tname," EXTERN");
		break;
	case 22: 
		tname=strcat(tname," STATIC");
		break;
	case 23: 
		tname=strcat(tname," AUTO");
		break;
	case 24: 
		tname=strcat(tname," REGISTER");
		break;
	case 10: 
		tname=strcat(tname," VOID");
		break;
	case 11: 
		tname=strcat(tname," CHAR");
		break;
	case 12: 
		tname=strcat(tname," SHORT");
		break;
	case 13: 
		tname=strcat(tname," INT");
		break;
	case 14: 
		tname=strcat(tname," LONG");
		break;
	case 15: 
		tname=strcat(tname," FLOAT");
		break;
	case 16: 
		tname=strcat(tname," DOUBLE");
		break;
	case 17: 
		tname=strcat(tname," SIGNED");
		break;
	case 18: 
		tname=strcat(tname," UNSIGNED");
		break;
	case 30: 
		tname=strcat(tname," CONST");
		break;
	case 31: 
		tname=strcat(tname," VOLATILE");
		break;
        }
        type=type/100;
   }
   return tname; 
}  

    
int type_error(int type1,int type2)
{
    if(type1==15 && type2!=15)
       {printf("\nLine no %d-->Warning: Type conversion from %s to %s may change the value of RHS\n",lineno,typeName(type2),typeName(type1));}
    else if(type1==16 && !(type2==16 || type2==15))
           {printf("\nLine no %d-->Warning: Type conversion from %s to %s may change the value of RHS\n",lineno,typeName(type2),typeName(type1));}
       
   else if (get_last_type_spec(type1)<get_last_type_spec(type2))
      {printf("\nLine no %d-->Warning: Type conversion from %s to %s may change the value of RHS\n",lineno,typeName(type2),typeName(type1));}
    
   return (type1);
}

yyerror(s)
char *s;
{
	fflush(stdout);
	if(DEBUG)printf("\n%*s\n%*s\n", column, "^", column, s);
}
