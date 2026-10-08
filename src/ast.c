/*   Abstract syntax tree code

     This code is used to define an AST node,
    routine for printing out the AST
    defining an enumerated nodetype so we can figure out what we need to
    do with this.  The ENUM is basically going to be every non-terminal
    and terminal in our language.

    Original AST skeleton by Shaun Cooper.

    check_params(F, A): compares parameters to check if the actuals match the formals
        if both are NULL, return 1 (they match)
        if only one is NULL, they differ in length, return 0
        if the data types of the two nodes differ, return 0
        otherwise recurse on the next formal (A_PARAM_LIST -> s2) and next actual (A_ARG_LIST -> s2)
*/

#include<stdio.h>
#include<stdlib.h>
#include "ast.h"
#include "symtable.h"

ASTnode *program; // Define the global variable here

 

/*##############################[CREATE AST NODE FUNCTION]########################################//
                              pre:  given a type of node to create
                            post:   returns a pointer to the new node
    uses malloc to create an ASTnode and passes back the heap address of the newley created node                                 */

        ASTnode *ASTCreateNode(enum ASTtype mytype)
{
    ASTnode *p;
    if (mydebug) fprintf(stderr,"Creating AST Node \n");
    p=(ASTnode *)malloc(sizeof(ASTnode));
    p->nodetype=mytype;
    p->s1=NULL;
    p->s2=NULL;
    p->value=0; 
    return(p);
}

/*#############################[HELPER PRINT TAB FUNCTION]######################################################### 

                            pre:    given a positive number
                            post:   prints that # of spaces
 */

void PT(int howmany)
{
     for (int i = 0; i < howmany; i++) {
         printf("   ");
     }
}
//#############################[DATA TYPE TO STRING FUNCTION]#####################################//
/* 
                            pre:   a Data Type
                            post:  a character string for that type to print */

char * DataTypeToString(enum DataTypes mydatatype){ 
                                                    
    switch (mydatatype) {

           case A_VOIDTYPE:  return ("void");
                             break;

           case A_INTTYPE:  return ("int");
                            break;

           case A_BOOLEANTYPE:  return ("boolean");
                                break;

           case A_STRINGTYPE:  return ("string");
                               break;

           default: printf("Unknown type in DataTypeToString\n");
                     exit(1);
      } //of switch
}// of DataTypeToString()

/*###############################[ HELPER CHECK PARM FUNCTION ]###############################################*/

int check_params( ASTnode * F, ASTnode *A)
{
    if ((F== NULL) && ( A== NULL)) return 1; 
    if ((F== NULL) || (A == NULL)) return 0 ;
    if(F->datatype != A->datatype) return 0;
    ASTnode *nextF;
    if (F->nodetype == A_PARAM_LIST) {
        nextF = F->s2;
    } else {
        nextF = NULL;
    }

    ASTnode *nextA;
    if (A->nodetype == A_ARG_LIST) {
        nextA = A->s2;
    } else {
        nextA = NULL;
    }
    return check_params(nextF, nextA);
}

/*###############################[ AST PRINT FUNCTION ]###############################################

                            pre:    pointer to an ast tree
                            post:   prints out the tree nicely (ast print order)
                            prints out the abstract syntax tree                                                               */

void ASTprint(int level,ASTnode *p) // how far down the tree we are and pointer to the tree
{
   if (p == NULL ) return;
   if (level > 10) {
       printf("ERROR: Too deep recursion, possible circular reference!\n");
       return;
   }
   
    // when here p is not NULL
   switch (p->nodetype) {

//-------------------------------[DECLARATION/LIST NODE CASE]--------------------------------------------//    
        case A_DECLARATION_LIST:  //internal component
                    ASTprint(level,p->s1); 
                    ASTprint(level,p->s2);
                break;
//-------------------------------[STATEMENT/LIST NODE CASE]---------------------------------------//
        case A_STMT_LIST:  //internal component
                    ASTprint(level,p->s1); 
                    ASTprint(level,p->s2);
                break;
//-------------------------------[CALL NODE CASE]--------------------------------------------//
        case A_CALL:
                    PT(level);
                    printf("CALL %s(\n", p->name);
                    if (p->s1 != NULL) {
                        ASTprint(level + 1, p->s1);
                    }
                    PT(level);
                    printf(")\n");
                break;
//-------------------------------[ARG LIST NODE CASE]--------------------------------------------//
        case A_ARG_LIST:  //internal component - prints each argument
                    ASTprint(level, p->s1);
                    if (p->s2 != NULL) {
                        ASTprint(level, p->s2);
                    }
                break;

//-------------------------------[PARAM LIST NODE CASE]--------------------------------------------//
        case A_PARAM_LIST:  //internal component
                    if (p->s1 != NULL) {
                        ASTprint(level, p->s1);
                    }
                    if (p->s2 != NULL) {
                        ASTprint(level, p->s2); //print next
                    }
                break;
//-------------------------------[NUMBER NODE CASE]--------------------------------------------//
    case A_NUM:
            PT(level);
            printf("NUMBER: %d\n", p->value);
            break;

//-------------------------------[STRING NODE CASE]--------------------------------------------//
        case A_STRING:
                    PT(level);
            printf("STRING: %s\n", p->name);
                    break;
        
//-------------------------------[EXPRESSION STATEMENT NODE CASE]----------------------------------//
    case A_EXPR_STMT:
            PT(level);
            printf("EXPRESSION STATEMENT\n");
            ASTprint(level + 1, p->s1);
            break;
//-------------------------------[BOOLEAN NODE CASE]--------------------------------------------//
        case A_BOOLEAN:
                    PT(level);
                    if (p->value) {
                        printf("BOOLEAN: true\n");
                    } else {
                        printf("BOOLEAN: false\n");
                    }
                    break;
//-------------------------------[RETURN NODE CASE]-----------------------------------------------//
        case A_RETURN:  
                    PT(level);
                    printf("RETURN STATEMENT:\n"); 
                    if (p->s1 != NULL) {
                        ASTprint(level + 1, p->s1); 
                    } else {
                        PT(level + 1);
                        printf("void\n");
                    }
                break;
//-------------------------------[VARIABLE DECLARATION NODE CASE]---------------------------------//
        case A_VARDEC :  PT(level);
                    printf("VARIABLE DECLARED:  ");
                        printf("%s ", DataTypeToString(p->datatype)); //print datatype
                        printf("%s",p->name);
                        if (p->value > 0)
                        printf("[%d]",p->value);
                    printf(" -- AT LEVEL %d WITH OFFSET %d", p->symbol->level, p->symbol->offset);
            
                    printf("\n");
		            ASTprint(level,p->s1); 
                break;
//-------------------------------[FUNCTION DECLARATION NODE CASE]---------------------------------//            

        case A_FUNDEC:  
                    PT(level);
                    printf("FUNCTION DECLARED:  %s %s -- AT LEVEL %d WITH OFFSET %d\n(\n", 
                           DataTypeToString(p->datatype), p->name, p->symbol->level, p->symbol->offset);
                    if (p->s1 == NULL) {
                        printf("VOID)\n");
                    } else {
                        ASTprint(level + 1, p->s1); // params
                        printf(")\n");
                    }
                    ASTprint(level + 1,p->s2); // compound stmt
                break;
//-------------------------------[COMPOUND STATEMENT NODE CASE]-----------------------------------//

        case A_COMPOUNDSTMT:
                    PT(level);
                    printf(" BEGIN\n");
                    ASTprint(level + 1,p->s1); // local declarations (variables)
                    ASTprint(level + 1,p->s2); // statement list
                    PT(level);
                    printf(" END\n\n");
                    //symbol table
                break;
//-------------------------------[IF-THEN/-ELSE NODE CASES]---------------------------------------//
        case A_SELECT:
                    PT(level);
                    printf("IF STATEMENT:\n");
                    PT(level + 1);
                    printf("CONDITION:\n");
                    ASTprint(level + 2, p->s1); 
                    PT(level + 1);
                    printf("THEN:\n");
                    if (p->value == 0) {
                        // s1 = condition; s2 = then statement
                        ASTprint(level + 2, p->s2);
                        PT(level);
                        printf("ENDIF\n");
                    } else {
                        // s1 = condition; s2 = combined then/else statements
                        if (p->s2 != NULL) {
                            ASTprint(level + 2, p->s2->s1); 
                            PT(level + 1);
                            printf("ELSE:\n");
                            ASTprint(level + 2, p->s2->s2); 
                            PT(level);
                            printf("ENDIF\n");
                        }
                    }
                break;
//-------------------------------[WRITE NODE CASE]------------------------------------------------//
        case A_WRITE:
                    PT(level);
                    printf("WRITE:");
                    if(p->name != NULL) //if name is not null then its a string
                    {
                     ASTprint(level + 1,p->s1);
                    }
                    else
                    {
                        printf("\n");
                        ASTprint(level + 1,p->s1); // print expression
                    }
                    break;
                    
//-------------------------------[READ NODE CASE]------------------------------------------------//
        case A_READ:
                    PT(level);
                    printf("READ: ");
                    if(p->name != NULL) //if name is not null then its a string
                    {
                        printf("%s\n", p->name); //print name
                    }
                    else
                    {
                        printf("\n");
                        ASTprint(level + 1,p->s1); // print expression
                    }
                    break;

//------------------------------[EXPRESSION OP NODE CASES]-------------------------------------------//
        case A_EXPR:
                    PT(level);
                    printf("EXPRESSION OPERATOR: ");
                    switch (p->operator){
                        case A_PLUS: printf("+\n"); 
                                    break;
                        case A_MINUS: printf("-\n"); 
                                    break;
                        case A_TIMES: printf("*\n"); 
                                    break;
                        case A_DIVIDE: printf("/\n");
                                    break;  
                        case A_AND: printf("AND\n");
                                    break; 
                        case A_OR: printf("OR\n");
                                    break;   
                        case A_LT: printf("< (LESS THAN)\n");
                                    break;
                        case A_LE: printf("<= (LESS THAN OR EQUAL)\n");
                                    break;
                        case A_GT: printf("> (GREATER THAN)\n");
                                    break;
                        case A_GE: printf(">= (GREATER THAN OR EQUAL)\n");
                                    break;
                        case A_EQ: printf("== (EQUAL TO)\n");
                                    break;
                        case A_NE: printf("!= (NOT EQUAL)\n");
                                    break;
                        case A_NOT: printf("NOT\n");
                                    break;

                        default:printf("Unknown operator in A_EXPR ASTPRINT()\n");
                                printf("EXITING! FIX ME!\n");
                                exit(1);
                    } //interanl switch
                    ASTprint(level +1, p->s1);
                    ASTprint(level +1, p->s2);
                    break;
//------------------------------[VARIABLE NODE CASE]---------------------------------------------//
        case A_VARIABLE:
                    PT(level);
                    if (p->s1 != NULL) {
                        printf("VARIABLE: %s[\n", p->name);
                        ASTprint(level + 1, p->s1); // array index expression
                        PT(level);
                        printf("]\n");
                    } else {
                        printf("VARIABLE: %s\n", p->name);
                    }
                    break;
//------------------------------[ASSIGNMENT NODE CASES]------------------------------------------//
        case A_ASSIGNSTMT:
                    PT(level);
                    printf("ASSIGNMENT =\n");
                    ASTprint(level+1, p->s1); // variable
                    ASTprint(level+1, p->s2); // expression
                    break;
//------------------------------[PARAM NODE CASE]--------------------------------------------//
        case A_PARAM:
                    PT(level);
                    printf("PARAMETER:  %s %s", DataTypeToString(p->datatype), p->name);
                    if (p->value == -1){
                        printf("[]");
                    }
                    if (p->symbol != NULL) {
                        printf(" -- AT LEVEL %d WITH OFFSET %d", p->symbol->level, p->symbol->offset);
                    }
                    printf("\n");
                break;
//------------------------------[WHILE NODE CASE]-----------------------------------------------//
        case A_ITERATION:
                    PT(level);
                    printf("WHILE STATEMENT:\n");
                    PT(level + 1);
                    printf("CONDITION:\n");
                    ASTprint(level + 2, p->s1); 
                    PT(level + 1);
                    printf("DO:\n");
                    ASTprint(level + 2, p->s2);
                break;

//------------------------------[DEFAULT CASE (IF NOT DECLARED)]----------------------------------//
        default: printf("Unknown Type in ASTprint %d\n",p->nodetype);
                 printf("Exiting ASTprint Immediately.\n");
                 exit(1);

       } // of switch
}
//                                    END OF ASTprint
