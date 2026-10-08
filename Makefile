CC      = gcc
CFLAGS  =
SRC     = src
BUILD   = build
TARGET  = algolc

OBJS = $(BUILD)/lex.yy.c $(BUILD)/parser.tab.c $(SRC)/ast.c $(SRC)/symtable.c $(SRC)/emit.c

all: $(TARGET)

$(TARGET): $(SRC)/lexer.l $(SRC)/parser.y $(SRC)/*.c $(SRC)/*.h
	mkdir -p $(BUILD)
	bison -d -o $(BUILD)/parser.tab.c $(SRC)/parser.y
	flex -o $(BUILD)/lex.yy.c $(SRC)/lexer.l
	$(CC) $(CFLAGS) -I$(SRC) -I$(BUILD) $(OBJS) -o $(TARGET)

example: $(TARGET)
	./$(TARGET) -d -o $(BUILD)/scopes < examples/scopes.al

clean:
	rm -rf $(BUILD) $(TARGET) *.asm

.PHONY: all example clean
