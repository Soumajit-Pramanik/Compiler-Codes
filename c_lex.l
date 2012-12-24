%{
#include <stdio.h>
#include "myhead.h"
#include "y.tab.h"


int decl_flag=-1;
%}


D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*


%%
"/*"			{ comment(); }

"auto"			{  decl_flag=0;return(AUTO); }
"break"			{  return(BREAK); }
"case"			{  return(CASE); }
"char"			{  decl_flag=0;return(CHAR); }
"const"			{  decl_flag=0;return(CONST); }
"continue"		{  return(CONTINUE); }
"default"		{  return(DEFAULT); }
"do"			{  return(DO); }
"double"		{  decl_flag=0;return(DOUBLE); }
"else"			{  return(ELSE); }
"enum"			{  return(ENUM); }
"extern"		{  decl_flag=0;return(EXTERN); }
"float"			{  decl_flag=0;return(FLOAT); }
"for"			{  return(FOR); }
"goto"			{  return(GOTO); }
"if"			{  return(IF); }
"int"			{  decl_flag=0;return(INT); }
"long"			{  decl_flag=0;return(LONG); }
"register"		{  decl_flag=0;return(REGISTER); }
"return"		{  return(RETURN); }
"short"			{  decl_flag=0;return(SHORT); }
"signed"		{  decl_flag=0;return(SIGNED); }
"sizeof"		{  return(SIZEOF); }
"static"		{  decl_flag=0;return(STATIC); }
"struct"		{  return(STRUCT); }
"switch"		{  return(SWITCH); }
"typedef"		{  return(TYPEDEF); }
"union"			{  return(UNION); }
"unsigned"		{  decl_flag=0;return(UNSIGNED); }
"void"			{  decl_flag=0;return(VOID); }
"volatile"		{  decl_flag=0;return(VOLATILE); }
"while"			{  return(WHILE); }

{L}({L}|{D})*		{  if(DEBUG)printf("\nLex id is %s\n",yytext); yylval.symb=push_into_table(yytext,1); return(IDENTIFIER); }

0[xX]{H}+{IS}?		{  return(CONSTANT); }
0{D}+{IS}?		{  return(CONSTANT); }
{D}+{IS}?		{  (yylval.ex).exp.val=atof(yytext); (yylval.ex).exp.etype=13;  
                           if(DEBUG)printf("\nLex yylval is %g\n", (yylval.ex).exp.val);
                           return(CONSTANT); 
                        }
L?'(\\.|[^\\'])+'	{  return(CONSTANT); }

{D}+{E}{FS}?		{  return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{  (yylval.ex).exp.val=atof(yytext); 
                           (yylval.ex).exp.etype=15;  
                           if(DEBUG)printf("\nLex yylval is %g\n", (yylval.ex).exp.val);return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{  return(CONSTANT); }

L?\"(\\.|[^\\"])*\"	{  return(STRING_LITERAL); }

"..."			{  return(ELLIPSIS); }
">>="			{  return(RIGHT_ASSIGN); }
"<<="			{  return(LEFT_ASSIGN); }
"+="			{  return(ADD_ASSIGN); }
"-="			{  return(SUB_ASSIGN); }
"*="			{  return(MUL_ASSIGN); }
"/="			{  return(DIV_ASSIGN); }
"%="			{  return(MOD_ASSIGN); }
"&="			{  return(AND_ASSIGN); }
"^="			{  return(XOR_ASSIGN); }
"|="			{  return(OR_ASSIGN); }
">>"			{  return(RIGHT_OP); }
"<<"			{  return(LEFT_OP); }
"++"			{  return(INC_OP); }
"--"			{  return(DEC_OP); }
"->"			{  return(PTR_OP); }
"&&"			{  return(AND_OP); }
"||"			{  return(OR_OP); }
"<="			{  return(LE_OP); }
">="			{  return(GE_OP); }
"=="			{  return(EQ_OP); }
"!="			{  return(NE_OP); }
";"			{  return(';'); }
("{"|"<%")		{  if(_left_paren_func==0)
                                     yylval.blockno = pushSymbolTable(); 
			   else
                                     _right_paren_func=0;
                           return('{'); }
("}"|"%>")		{  popSymbolTable(); return('}'); }
","			{  return(','); }
":"			{  return(':'); }
"="			{  return('='); }
"("			{  return('('); }
")"			{  return(')'); }
("["|"<:")		{  return('['); }
("]"|":>")		{  return(']'); }
"."			{  return('.'); }
"&"			{  return('&'); }
"!"			{  return('!'); }
"~"			{  return('~'); }
"-"			{  return('-'); }
"+"			{  return('+'); }
"*"			{  return('*'); }
"/"			{  return('/'); }
"%"			{  return('%'); }
"<"			{  return('<'); }
">"			{  return('>'); }
"^"			{  return('^'); }
"|"			{  return('|'); }
"?"			{  return('?'); }

[ \t\v\f]		{  }
[\n]        {lineno++;}
.			{ /* ignore bad characters */ }

%%

yywrap()
{
	return(1);
}


comment()
{
	char c, c1;

loop:
	while ((c = input()) != '*' && c != 0)
		putchar(c);

	if ((c1 = input()) != '/' && c != 0)
	{
		unput(c1);
		goto loop;
	}

	if (c != 0)
		putchar(c1);
}


int column = 0;

void count()
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n')
			column = 0;
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			column++;

	//ECHO;
}



