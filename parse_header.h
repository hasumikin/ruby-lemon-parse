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

#ifndef NDEBUG
inline static char *atom_name(AtomType n)
{
  switch(n) {
    case(ATOM_NONE              ): return "ATOM_NONE";
    case(ATOM_program           ): return "ATOM_program";
    case(ATOM_command           ): return "ATOM_command";
    case(ATOM_string_add        ): return "ATOM_string_add";
    case(ATOM_string_content    ): return "ATOM_string_content";
    case(ATOM_args_new          ): return "ATOM_args_new";
    case(ATOM_args_add          ): return "ATOM_args_add";
    case(ATOM_args_add_block    ): return "ATOM_args_add_block";
    case(ATOM_self              ): return "ATOM_self";
    case(ATOM_at_int            ): return "ATOM_at_int";
    case(ATOM_stmts_add         ): return "ATOM_stmts_add";
    case(ATOM_string_literal    ): return "ATOM_string_literal";
    case(ATOM_binary            ): return "ATOM_binary";
    case(ATOM_stmts_new         ): return "ATOM_stmts_new";
    case(ATOM_at_ident          ): return "ATOM_at_ident";
    case(ATOM_at_tstring_content): return "ATOM_at_tstring_content";
    case(NODE_BLOCK_ARG         ): return "NODE_BLOCK_ARG";
    default: return "\e[37;41;1m\"UNDEFINED\"\e[m";
  }
}
#endif /* !NDEBUG */

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
  int error_count;
} ParserState;

bool hasCar(Node *n);

bool hasCdr(Node *n);

#endif
