%option noinput nounput
%{
   //  Lexical analyzer for ALGOL-C

int mydebug=0; // set to 1 to get debug output
int linecount=1; //

#include "ast.h"
#include "parser.tab.h"

%}

%%
int         {return(T_INT);}
void        {return(T_VOID);}
boolean     {return(T_BOOLEAN);}
return      {return(T_RETURN);}
write       {return(T_WRITE);}
begin       {return(T_BEGIN);}
end         {return(T_END);}
read        {return(T_READ);}
\".*\"      {yylval.string=strdup(yytext) ;  return(T_STRING);}
not         {return(T_NOT);}
true        {return(T_TRUE);}
false       {return(T_FALSE);}
and         {return(T_AND);}
or          {return(T_OR);}
if          {return(T_IF);}
else        {return(T_ELSE);}
while       {return(T_WHILE);}
endif       {return(T_ENDIF);}
do          {return(T_DO);}
then        {return(T_THEN);}
"//".*      {/* skip comment */} 
"=="         {return(T_EQ);}
">="          {return(T_GE);}
">"           {return(T_GT);}
"<="          {return(T_LE);}
"<"           {return(T_LT);}
"!="          {return(T_NE);}

[a-zA-Z][a-zA-Z0-9_]*		{if (mydebug) fprintf(stderr,"Letter found\n"); 
                       yylval.string = strdup(yytext); return(T_ID);/* return an identifier */ }
[0-9][0-9]*	{if (mydebug) fprintf(stderr,"Digit found\n"); 
                       yylval.value = atoi((const char *)yytext); return(T_NUM);}
[ \t]		{if (mydebug) fprintf(stderr,"Whitespace found\n");/* skip whitespace */ }
[=\-+*/%&|();,[\](\)] 	{ if (mydebug) fprintf(stderr,"return a token %c\n",*yytext); 
                       return (*yytext);/* return a single character token */ }
\n 		{ if (mydebug) fprintf(stderr,"cariage return %c\n",*yytext); 
                       linecount++;
                    }

%%

int yywrap(void)
{ return 1;}
