//MIPS code emitter for ALGOL-C

//functions to create proper mips code
//places mips code in designated file

#include "emit.h"
//PRE: PTR to astnode
// POST: all mips code directly and through helper functions print into file 'fp'
void EMIT(ASTnode * p, FILE* fp)
{
    fprintf(fp, " # ALGOL-C generated MIPS code\n");
    fprintf(fp, ".data    \n");
    fprintf(fp, ".align 2    \n");
    fprintf(fp, ".text    \n");
    fprintf(fp, ".global    \n");
}
