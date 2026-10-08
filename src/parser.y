/*
  Parser for ALGOL-C

  - Type synthesis and symbol table entries for variable and function declarations
  - Type checking for variables used in expressions
  - Error reporting when input doesn't match the expected format
  - check_params() verifies that call arguments match a function's formal parameters
  - Temp variables are allocated on the stack for intermediate values and function calls
*/

%{
#include "symtable.h"
#include "ast.h"
#include "emit.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern int yylex();
extern int mydebug;
extern int linecount;
 
int LEVEL = 0; //how may compound statements deep we are in 
int maxoffset; //total number of words a function has
int OFFSET = 0; //how many words weve seen at a GLOBAL score or INSIDE a function
int GOFFSET = 0; //holder for global offset when we enter and exit a funtion def

void yyerror (char *s)  /* Called by yyparse on error */
{
  printf ("%s at line %d\n", s, linecount);
}

%}
/*  defines the start symbol, what values come back from LEX and how the operators are associated  */

%start Program

/*  defines the precedence and associativity of operators  */
%union{
	int value;
	char* string;
        ASTnode * node;
        enum DataTypes datatype;
        enum OPERATORS operator;
}
/*  defines the type of the values returned from LEX and used in the grammar  */

%token <string> T_ID T_STRING
%token <value> T_NUM

%token  T_BOOLEAN T_INT T_READ T_RETURN  T_VOID T_WRITE
%token  T_BEGIN T_END T_AND T_OR T_TRUE T_FALSE T_NOT
%token  T_EQ T_GE T_GT T_LE T_LT T_NE
%token  T_IF T_ELSE T_WHILE T_ENDIF T_DO T_THEN

%type <node> Declaration Declaration_List Var_Declaration Var_List Fun_Declaration VARIABLE        
%type <node> Compound_Stmt Local_Declarations Statement_List Statement
%type <node> Expression_Stmt Selection_Stmt Iteration_Stmt Assignment_Stmt Return_Stmt Read_Stmt Write_Stmt
%type <node> Factor Term Additive_Expression Simple_Expression
%type <node> Expr Params Param_List Param 
%type <node> CALL Args Arg_list

%type <datatype> Type_Specifier
%type <operator> Rel_Op

%type <operator> Add_Op Mult_Op

%%	/* end specs, begin rules */

/*-------------------------------------- START OF GRAMMAR RULES ------------------------------------------------ */

Program : Declaration_List
        { program = $1;
        }
	;

/*  create nodes for declaration and declaration_list  */
Declaration_List    : Declaration
                        {$$ = ASTCreateNode(A_DECLARATION_LIST);
                         $$->s1 = $1;
                        }
                    | Declaration Declaration_List
                        {$$ = ASTCreateNode(A_DECLARATION_LIST);
                         $$->s1 = $1;
                         $$->s2 = $2;
                        }
                    ;

Declaration : Var_Declaration 
                {$$ = $1;}
            | Fun_Declaration 
                {$$ = $1;}
            ;

Var_Declaration : Type_Specifier Var_List ';'  //parent to var_list that cares about type
                {
                  $$ = $2;
                  ASTnode* p;
                  p = $2;
                 while(p != NULL){
                    p -> symbol -> Declared_Type = $1;
                    p = p -> s1; //move to next variable in the list
                 }
                 $$ = $2;} //return the list of variables
                ;

Var_List    : T_ID   //CHECK T_IDS, ask questons before creating node
              {if(Search($1, LEVEL, 0) == NULL){
                //if symbol is not present, insert it into the table!
                 
              {$$ = ASTCreateNode(A_VARDEC);
                $$-> name = $1;
                $$ -> value = 0;
                $$ -> symbol = Insert($1, A_UNKNOWN, SYM_SCALAR, LEVEL, 1, OFFSET);
                OFFSET += 1;
              }}
              else{
                yyerror($1);
                yyerror("Error: Already defined variable");
                exit(1);
              }
                
                }
            | T_ID '['T_NUM']' 
            {if(Search($1, LEVEL, 0) == NULL){
                //if symbol is not present, insert it into the table!

              $$ = ASTCreateNode(A_VARDEC);
              $$ -> name = $1;
              $$-> value = $3; //points to a value (t_num)
              $$ -> symbol = Insert($1, A_UNKNOWN, SYM_ARRAY, LEVEL, $3, OFFSET);
              OFFSET += $3;
            }
              else{
                yyerror($1);
                yyerror("Error: Already defined variable");
                exit(1);}}

            | T_ID ',' Var_List  
            {if(Search($1, LEVEL, 0) == NULL){
                //if symbol is not present, insert it into the table!
                $$ = ASTCreateNode(A_VARDEC);
              $$ -> name = $1;
              $$ -> s1 = $3;
              $$ -> symbol = Insert($1, A_UNKNOWN, SYM_SCALAR, LEVEL, 1, OFFSET);
              OFFSET += 1;} 
              else{
                yyerror($1);
                yyerror("Error: Already defined variable");
                exit(1);}}

            | T_ID '['T_NUM']' ',' Var_List 
            {
              if(Search($1, LEVEL, 0) == NULL){
                //if symbol is not present, insert it into the table!
              $$ = ASTCreateNode(A_VARDEC);
              $$ -> name = $1;
              $$ -> value = $3; 
              $$ -> s1 = $6; //points to next variable in the list (recursion)
              $$ -> symbol = Insert($1, A_UNKNOWN, SYM_ARRAY, LEVEL, $3, OFFSET);
              OFFSET += $3;}
            else{
              yyerror($1);
              yyerror("Error: Already defined variable");
              exit(1);}}
            ;

Type_Specifier  : T_INT { $$ = A_INTTYPE;}
                | T_BOOLEAN { $$ = A_BOOLEANTYPE;}
                | T_VOID     { $$ = A_VOIDTYPE;}
                ;

Fun_Declaration : Type_Specifier T_ID  '(' 
          { //check to see if function name is known, if it is, bard
            //else, insert in smbol table
            //manage offset of value
             if(Search($2, LEVEL, 0) == NULL){
               Insert($2, $1, SYM_FUNCTION, LEVEL, 0, 0);
               GOFFSET = OFFSET;
               OFFSET = 2;  // Start at 2 for function
               maxoffset = OFFSET;

             }else{
              yyerror($2);
              yyerror("Error: Function name already defined");
              exit(1);
             }
            
          } Params ')' 
          {
            //update symble table with param
            //allows us to have recursive functions
            Search($2, LEVEL, 1) -> fparms = $5;
          }
            Compound_Stmt
           {$$ = ASTCreateNode(A_FUNDEC);
            $$-> name = $2;
            $$-> datatype = $1; 
            $$ -> s1 = $5; //  params 
            $$ -> s2 = $8;
            $$ -> symbol = Search($2,LEVEL,0);
            $$ -> symbol -> offset = maxoffset;
            }
           ;

Params  : T_VOID
        {$$ = NULL;} //no parameters
        | Param_List
        {$$ = $1;}   //list of parameters
        ;

Param_List  : Param
            {$$ = $1;}
            | Param ',' Param_List
                { $$ = ASTCreateNode(A_PARAM_LIST); // create a node to hold the param list
                  $$ -> s1 = $1;
                  $$ -> s2 = $3;}
            ;
Param   : Type_Specifier T_ID
        { 
          $$ = ASTCreateNode(A_PARAM);
          $$ -> datatype = $1;
          $$ -> name = $2;

          if(Search($2, 1, 0) == NULL){
          $$ -> symbol = Insert($2, $1, SYM_SCALAR, 1, 1, OFFSET);
          OFFSET += 1;
          }else{
            yyerror($2);
            yyerror("Error: Parameter name already used");
            exit(1);
          }}

        | Type_Specifier T_ID '['']'
        { $$ = ASTCreateNode(A_PARAM);
          $$ -> datatype = $1;
          $$ -> name = $2;
          $$ -> value = 1;
          if(Search($2, 1, 0) == NULL){
          // insert parameters at level 1 
          $$ -> symbol = Insert($2, $1, SYM_ARRAY, 1, 1, OFFSET);
          OFFSET += 1;
          }else{
            yyerror($2);
            yyerror("Error: Parameter name already used");
            exit(1);
          }} 
        ;

Compound_Stmt   : T_BEGIN {LEVEL++;} 
                  Local_Declarations Statement_List T_END
                {$$ = ASTCreateNode(A_COMPOUNDSTMT);
                 $$ ->s1 = $3;
                 $$ -> s2 = $4;
                 if(OFFSET > maxoffset){
                  maxoffset = OFFSET;
                 }
                 Display();
                 OFFSET -= Delete(LEVEL);
                 LEVEL--;
                 }
                ;

Local_Declarations  : Var_Declaration Local_Declarations
                        {$$ = ASTCreateNode(A_DECLARATION_LIST);
                         $$ -> s1 = $1;
                         $$ -> s2 = $2;}
                    | /*empty*/
                    {$$ = NULL;} //tree is done when NULL
                    ;

Statement_List  :  /*empty by default */
                {$$ = NULL;}
                |Statement Statement_List
                {$$ = ASTCreateNode(A_STMT_LIST);
                 $$ -> s1 = $1;
                 $$ -> s2 = $2;}
                ;

Statement   : Expression_Stmt
            {$$ = $1;} 
            | Compound_Stmt
            {$$ = $1;} 
            | Selection_Stmt
            {$$ = $1;} 
            | Iteration_Stmt
            {$$ = $1;}
            | Assignment_Stmt
            {$$ = $1;}
            | Return_Stmt
            {$$ = $1;}
            | Read_Stmt
            {$$ = $1;}
            | Write_Stmt
            {$$ = $1;}
            ;

Expression_Stmt : Expr ';'
                {$$ = ASTCreateNode(A_EXPR_STMT);
                 $$ -> s1 = $1;}
                | ';'
                {$$ = NULL;} //empty statement
                ;

Selection_Stmt  : T_IF  Expr T_THEN Statement T_ENDIF // if-then
                {  $$ = ASTCreateNode(A_SELECT); //node to hold if and then statements
                   $$ -> s1 = $2;    
                   $$ -> s2 = $4;    
                   $$ -> value = 0;  // to signify there is no 'else' 
                }
                | T_IF  Expr T_THEN Statement T_ELSE Statement T_ENDIF  // if-then/else
                {  $$ = ASTCreateNode(A_SELECT);
                   $$ -> s1 = $2;    // condition
                   ASTnode * p = ASTCreateNode(A_STMT_LIST);   // node to hold if and then/else statements (because we're only using s1 and s2)
                   p -> s1 = $4;  
                   p -> s2 = $6;   
                   $$ -> s2 = p; 
                   $$ -> value = 1; // to signify there is an 'else' part
                }
                ;

Iteration_Stmt  : T_WHILE Expr T_DO Statement
                { $$ = ASTCreateNode(A_ITERATION);
                  $$ -> s1 = $2; //condition
                  $$ -> s2 = $4; //statement 
                }
                ;

Assignment_Stmt : VARIABLE '=' Expr ';'
                { 
                   $$ = ASTCreateNode(A_ASSIGNSTMT);
                  $$ -> s1 = $1;
                  $$ -> s2 = $3;
                  $$ -> operator = A_ASSIGN;

                  if($1 -> datatype != $3 -> datatype){
                  yyerror("Error: Must be the same datatype");
                  exit(1);
                  }
                  $$ ->datatype = $1->datatype;
                  $$ -> symbol = Insert(CreateTemp(), $$ -> datatype, SYM_SCALAR, LEVEL, 1, OFFSET);
                  OFFSET += 1;} 
                ;

Return_Stmt : T_RETURN Expr ';' //return with value
                { $$ = ASTCreateNode(A_RETURN);
                  $$-> s1 = $2;  
                }
            | T_RETURN ';' // no return value
                { $$ = ASTCreateNode(A_RETURN);
                  $$-> s1 = NULL; 
                }
            ;

Write_Stmt  : T_WRITE Expr ';'
                { $$ = ASTCreateNode(A_WRITE);
                  $$-> s1 = $2;  
                }

Read_Stmt   : T_READ VARIABLE ';'
                { $$ = ASTCreateNode(A_READ);
                  $$-> s1 = $2;}    // variable
                ;

VARIABLE    : T_ID  //make sure its there, else barf
              {
                struct SymbTab *p;
                p = Search($1, LEVEL, 1); //variable to make searching more efficient
                if(p == NULL)
                {
                  yyerror($1);
                  yyerror("Error: Variable doesn't exist");
                  exit(1);
                }
                // if it's the wrong subtype, barf 
                if(p->SubType != SYM_SCALAR)
                {
                  yyerror($1);
                  yyerror("Error: Variable has wrong subtype");
                  exit(1);
                }
                // proceed if no errors 
                $$ = ASTCreateNode(A_VARIABLE);
                $$ -> name = $1;
                $$ -> symbol = p;
                $$ -> datatype = p -> Declared_Type;
              }

            | T_ID '[' Expr ']' // array with index
              {
                struct SymbTab *p;
                p = Search($1, LEVEL, 1);
                if(p == NULL)
                {
                  yyerror($1);
                  yyerror("Error: Variable doesn't exist in symbol table");
                  exit(1);
                }
                // make sure it's an array 
                if(p->SubType != SYM_ARRAY)
                {
                  yyerror($1);
                  yyerror("Error: Variable has wrong subtype, should be an array");
                  exit(1);
                }
                if ($3-> datatype != A_INTTYPE){
                  yyerror($1);
                  yyerror("Error: Array index should be an integer");
                  exit(1);
                }
                $$ = ASTCreateNode(A_VARIABLE);
                $$->name = $1;
                $$->s1 = $3; //index expression
                $$->symbol = p;
                $$ -> symbol = p;
                $$ -> datatype = p -> Declared_Type;
              }
            ;

Expr    : Simple_Expression
        {$$ = $1;}
        ;

Simple_Expression   : Additive_Expression
                        {$$ = $1;}
                    | Simple_Expression Rel_Op Additive_Expression
                    {
                      if($1->datatype != $3->datatype)
                      {
                        yyerror("Mismatching types on expression");
                        exit(1);
                      }
                     $$ = ASTCreateNode(A_EXPR);
                     $$ -> s1 = $1;
                     $$ -> s2 = $3;
                     $$ -> operator = $2;
                     $$ -> datatype = A_BOOLEAN;
                     $$ -> symbol = Insert(CreateTemp(), $$ -> datatype, SYM_SCALAR, LEVEL, 1, OFFSET);
                     OFFSET += 1;} 
                    ;

Rel_Op  : T_LE { $$ = A_LE; } 
        | T_LT { $$ = A_LT; } 
        | T_GT { $$ = A_GT; } 
        | T_GE { $$ = A_GE; }
        | T_EQ { $$ = A_EQ; }
        | T_NE { $$ = A_NE; }
        ;

Additive_Expression : Term
                    {$$ = $1;}
                    | Additive_Expression Add_Op Term
                    {
                      if($1->datatype != $3->datatype)
                      {
                        yyerror("Mismatching types on expression");
                        exit(1);
                      }

                     $$ = ASTCreateNode(A_EXPR);
                     $$ -> s1 = $1;
                     $$ -> s2 = $3;
                     $$ -> operator = $2;
                     $$ -> datatype = $1->datatype;
                     $$ -> symbol = Insert(CreateTemp(), $1->datatype, SYM_SCALAR, LEVEL, 1,OFFSET); 
                     OFFSET += 1;} 
                     
                    ;

Add_Op  : '+' {$$ = A_PLUS;}
        | '-' {$$ = A_MINUS;}
        ;

Term    : Factor
        {$$ = $1;}
        | Term Mult_Op Factor
        {
          if($1->datatype != $3->datatype){
            yyerror("Mismatching types on expression");
            exit(1);
          }
          $$ = ASTCreateNode(A_EXPR);
          $$ -> s1 = $1;
          $$ -> s2 = $3;
          $$ -> operator = $2;
          $$->datatype = $1->datatype;
          $$->symbol = Insert(CreateTemp(), $1->datatype, SYM_SCALAR, LEVEL, 1,OFFSET);
          OFFSET = OFFSET + 1;}
        ;

Mult_Op : '*' {$$ = A_TIMES;}
        | '/' {$$ = A_DIVIDE;}
        |T_AND {$$ = A_AND;}
        |T_OR {$$ = A_OR;}
        ;

Factor  : '(' Expr ')' 
        {$$ = $2;} 
        | T_NUM
        {$$ = ASTCreateNode(A_NUM);
         $$-> value = $1;
         $$->datatype = A_INTTYPE;
        } 
        | T_STRING
        {$$ = ASTCreateNode(A_STRING);
         $$-> name = $1;}
        | VARIABLE
        {$$ = $1;} 
        | CALL
        {$$ = $1;} 
        | T_NOT Factor  
        {
          if($2->datatype != A_BOOLEANTYPE)
          {
            yyerror("Error: NOT operator expects boolean");
            exit(1);

          }
          $$ = ASTCreateNode(A_EXPR); 
          $$ -> operator = A_NOT;
          $$ -> s1 = $2;
          $$ -> datatype = $2 -> datatype;
        }
        | T_FALSE
        {$$ = ASTCreateNode(A_BOOLEAN);
         $$-> value = 0;
         $$->datatype = A_BOOLEANTYPE;}
        | T_TRUE
        {$$ = ASTCreateNode(A_BOOLEAN);
         $$-> value = 1;
         $$->datatype = A_BOOLEANTYPE;}
        ;

CALL    : T_ID '(' Args ')'
        { //check if its in the symtabble
          struct SymbTab *p;
          p = Search($1, 0, 0);
          if(p == NULL)
          {
            yyerror($1);
            yyerror("Error: Function doesn't exist in symbol table");
            exit(1);
          }
          if(p-> SubType != SYM_FUNCTION)
          {
            yyerror($1);
            yyerror("Error: This is not a function");
            exit(1);
          }
          //check to see if actual and formals match in length and type
          if(check_params(p->fparms,$3) == 0)
          {
            yyerror($1);
            yyerror("Error: Parameter usage is incorrect");
            exit(1);
          }
          $$ = ASTCreateNode(A_CALL);
          $$-> name = $1;
          $$-> s1 = $3;
          $$ -> symbol = p;
          $$ -> datatype = $$ -> symbol -> Declared_Type;
          }  
        ;

Args    : Arg_list
        {$$ = $1;}
        | 
        {$$ = NULL;} /*empty*/
        ;

Arg_list        : Expr ',' Arg_list
                { $$ = ASTCreateNode(A_ARG_LIST);
                  $$ -> s1 = $1;
                  $$ -> s2 = $3;
                  $$->name = CreateTemp();
                  $$->datatype = $1->datatype;
                  $$->symbol = Insert($$-> name, $1 -> datatype, SYM_SCALAR, LEVEL, 1, OFFSET);
                  OFFSET += 1;}
                | Expr
                {$$ = ASTCreateNode(A_ARG_LIST);
                 $$ = $1;
                 $$ -> s2 = NULL;
                 $$->name = CreateTemp();
                 $$->datatype = $1->datatype;
                 $$->symbol = Insert($$-> name, $1 -> datatype, SYM_SCALAR, LEVEL, 1, OFFSET);
                 OFFSET += 1;}
                ;
                
%%	
//--------------END OF GRAMMAR RULES------------------------------------------------------//

//-------------START OF MAIN PROGRAM------------------------------------------------------//
int main(int argc, char * argv[])
{ 
  FILE *fp = NULL;
  char s[100];

  for(int i = 1; i < argc; i++) 
  {
    if(strcmp("-d",argv[i]) == 0) mydebug = 1;

    if(strcmp("-o",argv[i]) == 0)
    {
       strcpy(s,argv[i+1]);
       strcat(s, ".asm");

       if(mydebug) printf("Opening file %s\n",s);
       fp = fopen(s,"w");

       if(fp == NULL)
       {
          printf("Unable to open %s\n", s);
          exit(1);
       } //end of if fopen

    } //end of strcmp
   
  } //end of loop 

  if(fp ==NULL){
    printf("No Filename provided, must use -o option\n");
    exit(1);}
    
    
    
  
  
  yyparse();
  
  if (mydebug) fprintf(stderr, "The input is syntactically correct\n");

  if (mydebug) Display();
  if (mydebug) ASTprint(0, program);

  EMIT(program,fp);
  exit(0);
}

  
