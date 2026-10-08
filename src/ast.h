/*   Abstract syntax tree code

 Header file   
 Original AST skeleton by Shaun Cooper.

*/

#include<stdio.h>
#include<stdlib.h>

#ifndef AST_H
#define AST_H
extern int mydebug;

/* define the enumerated types for the AST.  THis is used to tell us what 
sort of production rule we came across */

enum ASTtype {
   A_DECLARATION_LIST,
   A_VARDEC,
   A_FUNDEC,
   A_EXPR,
   A_EXPR_STMT,
   A_COMPOUNDSTMT,
   A_SELECT,
   A_STMT_LIST,
   A_WRITE,
   A_NUM,
   A_VARIABLE,
   A_ASSIGNSTMT,
   A_ITERATION,
   A_RETURN,
   A_PARAM_LIST,
   A_PARAM,
   A_READ,
   A_STRING,
   A_CALL,
   A_ARG_LIST,
   A_BOOLEAN
};

enum DataTypes {
   A_INTTYPE,
   A_VOIDTYPE,
   A_BOOLEANTYPE,
   A_STRINGTYPE,
   A_UNKNOWN
};

enum OPERATORS {
   A_PLUS, 
   A_MINUS,
   A_TIMES,
   A_ASSIGN,
   A_DIVIDE,
   A_LE,
   A_LT,
   A_GT,
   A_GE,
   A_EQ,
   A_NE,
   A_AND,
   A_OR,
   A_NOT
};

/* define a type AST node which will hold pointers to AST structs that will
   allow us to represent the parsed code 
*/
typedef struct ASTnodetype
{
     enum ASTtype nodetype;
     enum OPERATORS operator;
     enum DataTypes datatype;
     char * name;
     int value;
     ///.. missing
     struct ASTnodetype *s1,*s2 ; /* used for holding IF and WHILE components -- not very descriptive */
     struct SymbTab * symbol; 
} ASTnode;

/* uses malloc to create an ASTnode and passes back the heap address of the newley created node */
ASTnode *ASTCreateNode(enum ASTtype mytype);

void PT(int howmany);

int check_params( ASTnode * F, ASTnode *A);

extern ASTnode *program; // pointer to the tree

/*  Print out the abstract syntax tree */
void ASTprint(int level,ASTnode *p);

#endif // of AST_H
