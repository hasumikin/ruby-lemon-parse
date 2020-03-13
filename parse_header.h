#ifndef LEMON_PARSE_HEADER_H_
#define LEMON_PARSE_HEADER_H_

#include <stdbool.h>

typedef enum atom_type {
  ATOM_NONE = 0,

  ATOM_program = 1,
  ATOM_command,
  ATOM_string_add,
  ATOM_string_content,
  ATOM_args_new,
  ATOM_args_add,
  ATOM_args_add_block,
  ATOM_self,
  ATOM_at_int,
  ATOM_stmts_add,
  ATOM_string_literal,
  ATOM_binary,
  ATOM_stmts_new,
  ATOM_at_ident,
  ATOM_at_tstring_content,

  NODE_BLOCK_ARG // FIXME
} AtomType;

typedef enum {
  ATOM,
  CONS,
  LITERAL
} NodeType;

typedef struct node Node;

typedef struct {
  struct node *car;
  struct node *cdr;
} Cons;

typedef struct {
  AtomType type;
} Atom;

typedef struct {
  char *name;
} Value;

struct node {
  NodeType type;
  union {
    Atom atom;
    Cons cons;
    Value value;
  };
};

typedef struct literal_store
{
  char *str;
  struct literal_store *prev;
} LiteralStore;

typedef struct parser_state {
  /* see mruby/include/mruby/compile.h */
  Node *cells;
  Node *locals;
  Node *root;
  LiteralStore *literal_store;
} ParserState;

bool hasCar(Node *n);

bool hasCdr(Node *n);

#endif