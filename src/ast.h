/*   Abstract syntax tree code


 Header file   
 Original AST skeleton by Shaun Cooper.

*/

#include<stdio.h>
#include<malloc.h>

#ifndef AST_H
#define AST_H
extern int mydebug;

/* define the enumerated types for the AST.  THis is used to tell us what 
sort of production rule we came across */

enum ASTtype {
   A_PROGRAM,                           //0
   A_DECLARATION_LIST,                  //1 
   A_VARDEC,                            //2           
   A_FUNDEC,                            //3
   A_NUMBER,                            //4
   A_EXPR,                              //5
   A_EXPR_STMT,
   A_IFSTMT,                            //6
   A_COMPOUNDSTMT,                      //7
   A_SELECT,                            //8
   A_STMT_LIST,                         //9
   A_WRITE,                             //10
   A_FACTOR,                            //11
   A_NUM,                               //12
   A_VARIABLE,                          //13
   A_ASSIGNSTMT,                        //14
   A_IFSTMT_ELSE,                       //15
   A_ITERATION,                         //16
   A_RETURN,                            //17
   A_PARAM_LIST,                        //18
   A_PARAM,                             //19
   A_READ,                              //20
   A_STRING,                            //21
   A_CALL,                              //22
   A_ARG_LIST,                           //23
   A_BOOLEAN                            //24
	 
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
