# ALGOL-C Compiler

A compiler front end for **ALGOL-C**, a small C-like language with ALGOL-style blocks, written in C with Flex and Bison. It targets MIPS assembly.

## Features

- **Lexer** (`src/lexer.l`): keywords, identifiers, integer and string literals, relational operators, and `//` comments
- **Parser** (`src/parser.y`): an LALR grammar covering declarations, functions, blocks, and statements and expressions
- **Abstract syntax tree** (`src/ast.c`): built during parsing, with a pretty-printer
- **Symbol table** (`src/symtable.c`): nested scopes with levels, stack offsets, and scope cleanup on block exit
- **Semantic analysis**:
  - type checking of expressions and assignments
  - checks that every identifier is declared and that scalars, arrays, and functions are used correctly
  - checks that a call's arguments match the function's parameters in count and type
- **Runtime layout**: stack offsets for locals, and temporaries for intermediate values and call arguments
- **Code generation** (`src/emit.c`): writes the skeleton of the MIPS assembly output (in progress)

## The language

```c
int y, Z[100];

int f(int b)
begin
  int x[10];
  x[0] = b + f(5 + x[2] * b);
end

int main(int arg1, int arg2[])
begin
  write f(arg1 + arg2[8] + y);
end
```

- Types: `int`, `boolean`, `void`, and one-dimensional arrays
- Blocks: `begin ... end`, which can be nested and can declare their own locals
- Control flow: `if ... then ... [else ...] endif` and `while ... do ...`
- I/O: `read x;` and `write expr;`
- Operators: `+ - * /`, `and`, `or`, `not`, and `== != < <= > >=`

## Build and run

You need `gcc`, `flex`, and `bison`.

```sh
make                                  # builds ./algolc
./algolc -o out < examples/scopes.al  # writes out.asm
./algolc -d -o out < examples/scopes.al   # debug: also prints the symbol table
```

To run the generated assembly, use a MIPS simulator such as [MARS](https://github.com/dpetersanderson/MARS).

## Project layout

```
src/
  lexer.l        Flex tokenizer
  parser.y       Bison grammar, semantic actions, and the program's main()
  ast.c/.h       AST node definitions and printer
  symtable.c/.h  scoped symbol table
  emit.c/.h      MIPS emitter
examples/
  scopes.al      sample program with nested scopes, arrays, and recursion
```

## Acknowledgments

The AST and symbol table skeletons are based on starter code by Shaun Cooper.
