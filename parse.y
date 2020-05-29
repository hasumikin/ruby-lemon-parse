%fallback
  ON_NONE
  KW
  ON_SP
  SEMICOLON
  PERIOD
  ON_OP
  ON_TSTRING_SINGLE
  EMBDOC
  EMBDOC_BEG
  EMBDOC_END
  EMBEXPR_BEG
  EMBEXPR_END
  IVAR
  GVAR
  CHAR
  TLAMBDA
  SYMBEG
  COMMENT
  LPAREN
  RPAREN
  LBRACKET
  RBRACKET
  LBRACE
  RBRACE
  WORDS_BEG
  WORDS_SEP
  QWORDS_BEG
  SYMBOLS_BEG
  QSYMBOLS_BEG
  LABEL
  FLOAT
  .

%extra_context { ParserState *p }

%token_type { char* }
%default_type { Node* }

%include {
  #include <stdlib.h>
  #include <stdint.h>
  #include <string.h>
  #include "parse_header.h"
  #include "parse.h"
  #include "atom_helper.h"
}

%ifdef LEMON_MMRBC
  %include {
    #ifdef MRBC_ALLOC_LIBC
      #define LEMON_ALLOC(size) malloc(size)
      #define LEMON_FREE(ptr)   free(ptr)
    #else
      void *mmrbc_alloc(size_t size);
      void mmrbc_free(void *ptr);
      #define LEMON_ALLOC(size) mmrbc_alloc(size)
      #define LEMON_FREE(ptr)   mmrbc_free(ptr)
    #endif /* MRBC_ALLOC_LIBC */
  }
%endif

%ifndef LEMON_MMRBC
  %include {
    #define LEMON_ALLOC(size) malloc(size)
    #define LEMON_FREE(ptr)   free(ptr)
  }
%endif

%include {
  #include "parse_header.h"
///* parser structure */
//struct mrb_parser_state {
//  mrb_state *mrb;
//  struct mrb_pool *pool;
//  mrb_ast_node *cells;
//  const char *s, *send;
//#ifndef MRB_DISABLE_STDIO
//  FILE *f;
//#endif
//  mrbc_context *cxt;
//  mrb_sym filename_sym;
//  uint16_t lineno;
//  int column;
//
//  enum mrb_lex_state_enum lstate;
//  mrb_ast_node *lex_strterm; /* (type nest_level beg . end) */
//
//  unsigned int cond_stack;
//  unsigned int cmdarg_stack;
//  int paren_nest;
//  int lpar_beg;
//  int in_def, in_single;
//  mrb_bool cmd_start:1;
//  mrb_ast_node *locals;
//
//  mrb_ast_node *pb;
//  char *tokbuf;
//  char buf[MRB_PARSER_TOKBUF_SIZE];
//  int tidx;
//  int tsiz;
//
//  mrb_ast_node *all_heredocs; /* list of mrb_parser_heredoc_info* */
//  mrb_ast_node *heredocs_from_nextline;
//  mrb_ast_node *parsing_heredoc;
//  mrb_ast_node *lex_strterm_before_heredoc;
//
//  void *ylval;
//
//  size_t nerr;
//  size_t nwarn;
//  mrb_ast_node *tree;
//
//  mrb_bool no_optimize:1;
//  mrb_bool on_eval:1;
//  mrb_bool capture_errors:1;
//  struct mrb_parser_message error_buffer[10];
//  struct mrb_parser_message warn_buffer[10];
//
//  mrb_sym* filename_table;
//  uint16_t filename_table_length;
//  uint16_t current_filename_index;
//
//  struct mrb_jmpbuf* jmp;
//};

  static char*
  parser_strndup(ParserState *p, const char *s, size_t len)
  {
    char *b = (char *)LEMON_ALLOC(len+1);//TODO リテラルプールへ
    memcpy(b, s, len);
    b[len] = '\0';
    return b;
  }
  #undef strndup
  #define strndup(s,len) parser_strndup(p, s, len)

  static char*
  parser_strdup(ParserState *p, const char *s)
  {
    return parser_strndup(p, s, strlen(s));
  }
  #undef strdup
  #define strdup(s) parser_strdup(p, s)

  static Node*
  cons_gen(ParserState *p, Node *car, Node *cdr)
  {
    Node *c;
    //if (p->cells) {
    //  c = p->cells;
    //  p->cells = p->cells->cdr;
    //}
    //else {
    //  c = (Node *)parser_palloc(p, sizeof(Node));
    c = (Node *)LEMON_ALLOC(sizeof(Node));
    if (c == NULL) printf("Out Of Memory");
    c->type = CONS;
    //}
    c->cons.car = car;
    c->cons.cdr = cdr;
    //c->lineno = p->lineno;
    //c->filename_index = p->current_filename_index;
    /* beginning of next partial file; need to point the previous file */
    //if (p->lineno == 0 && p->current_filename_index > 0) {
    //  c->filename_index-- ;
    //}
    return c;
  }
  #define cons(a,b) cons_gen(p,(a),(b))

  static Node*
  atom(int t)
  {
    Node* a;
    a = (Node *)LEMON_ALLOC(sizeof(Node));
    if (a == NULL) printf("Out Of Memory");
    a->type = ATOM;
    a->atom.type = t;
    return a;
  }

  static Node*
  literal_gen(ParserState *p, const char *s)
  {
    Node* l;
    l = (Node *)LEMON_ALLOC(sizeof(Node));
    if (l == NULL) printf("Out Of Memory");
    l->type = LITERAL;
    l->value.name = strdup(s);
    return l;
  }
  #define literal(s) literal_gen(p, (s))

  static Node*
  list1_gen(ParserState *p, Node *a)
  {
    return cons(a, 0);
  }
  #define list1(a) list1_gen(p, (a))

static Node*
list2_gen(ParserState *p, Node *a, Node *b)
{
  return cons(a, cons(b,0));
}
#define list2(a,b) list2_gen(p, (a),(b))

static Node*
list3_gen(ParserState *p, Node *a, Node *b, Node *c)
{
  return cons(a, cons(b, cons(c,0)));
}
#define list3(a,b,c) list3_gen(p, (a),(b),(c))

static Node*
list4_gen(ParserState *p, Node *a, Node *b, Node *c, Node *d)
{
  return cons(a, cons(b, cons(c, cons(d, 0))));
}
#define list4(a,b,c,d) list4_gen(p, (a),(b),(c),(d))

static Node*
list5_gen(ParserState *p, Node *a, Node *b, Node *c, Node *d, Node *e)
{
  return cons(a, cons(b, cons(c, cons(d, cons(e, 0)))));
}
#define list5(a,b,c,d,e) list5_gen(p, (a),(b),(c),(d),(e))

static Node*
list6_gen(ParserState *p, Node *a, Node *b, Node *c, Node *d, Node *e, Node *f)
{
  return cons(a, cons(b, cons(c, cons(d, cons(e, cons(f, 0))))));
}
#define list6(a,b,c,d,e,f) list6_gen(p, (a),(b),(c),(d),(e),(f))

static Node*
append_gen(ParserState *p, Node *a, Node *b)
{
//  Node *c = a;
//  if (!a) return b;
//  while (c->cons.cdr) {
//    c = c->cons.cdr;
//  }
//  if (b) {
//    c->cons.cdr = b;
//  }
//  return a;
  return list3(atom(ATOM_args_add), a, b);
}
#define append(a,b) append_gen(p,(a),(b))
#define push(a,b) append_gen(p,(a),list1(b))

  #define nsym(x) ((Node*)(intptr_t)(x))
  #define nint(x) ((Node*)(intptr_t)(x))

/*
  static Node*
  locals_Node(ParserState *p)
  {
    //return p->locals->cons.car;
    //return p->locals ? p->locals->cons.car : NULL;
  }
*/
  /* (:scope (vars..) (prog...)) */
/*
  static Node*
  new_scope(ParserState *p, Node *body)
  {
    return cons(atom(ATOM_stmts_add), cons(locals_node(p), body));
  }
*/

  /* (:call a b c) */
  static Node*
  new_call(ParserState *p, Node *a, int b, Node *c, int pass)
  {
    //void_expr_error(p, a);
    //NODE_LINENO(n, a);
    Node *n;
    switch (b) {
      case PLUS:
        n = list4(atom(ATOM_binary), a, literal(":+"), c);
        break;
      case TIMES:
        n = list4(atom(ATOM_binary), a, literal(":*"), c);
        break;
    }
    return n;
  }

  /* (:begin prog...) */
  static Node*
  new_begin(ParserState *p, Node *body)
  {
    if (body) {
      Node *add;//, *new;
      //add = list1(atom(":stmts_add"));
      //new = list2(atom(":stmts_new"), body);
      //add->cons.cdr = new;
      add = list3(atom(ATOM_stmts_add), list1(atom(ATOM_stmts_new)), body);
      return add;
    }
    return cons(atom(ATOM_stmts_new), 0);//TODO ここおかしい
  }

  #define newline_node(n) (n)

  static Node*
  call_bin_op_gen(ParserState *p, Node *recv, int m, Node *arg1)
  {
    //Node *n = new_call(p, recv, m, list1(list1(arg1)), 1);
    Node *n = new_call(p, recv, m, arg1, 1);
    return n;
  }
  #define call_bin_op(a, m, b) call_bin_op_gen(p ,(a), (m), (b))

  /* (:sym) */
  static Node*
  new_sym(ParserState *p, const char *s)
  {
    Node* result = list2(atom(ATOM_symbol_literal), literal(s));
    return result;
  }

  /* (:int . i) */
  static Node*
  new_lit(ParserState *p, const char *s, AtomType a, int base, int suffix)
  { // TODO base は10進法などを表す
    Node* result = list2(atom(a), literal(s));
    return result;
  }

  /* nageted integer */
  static Node*
  new_neglit(ParserState *p, const char *s, AtomType a, int base, int suffix)
  {
    Node* result = list3(atom(ATOM_unary), literal("-") ,list2(atom(a), literal(s)));
    return result;
  }

  static Node*
  new_lvar(ParserState *p, const char *s)
  {
    return list2(atom(ATOM_var_field), list2(atom(ATOM_at_ident), literal(s)));
  }

  static Node*
  new_ivar(ParserState *p, const char *s)
  {
    return list2(atom(ATOM_var_field), list2(atom(ATOM_at_ivar), literal(s)));
  }

  static Node*
  new_gvar(ParserState *p, const char *s)
  {
    return list2(atom(ATOM_var_field), list2(atom(ATOM_at_gvar), literal(s)));
  }

  static Node*
  new_const(ParserState *p, const char *s)
  {
    return list2(atom(ATOM_var_field), list2(atom(ATOM_at_const), literal(s)));
  }

  static Node*
  new_asgn(ParserState *p, Node *lhs, Node *rhs)
  {
    return list3(atom(ATOM_assign), lhs, rhs);
  }

  /* (:self) */
  static Node*
  new_self(ParserState *p)
  {
    return list1(atom(ATOM_self));
  }

  /* (:fcall self mid args) */
  static Node*
  new_fcall(ParserState *p, Node *b, Node *c)
  {
    //Node *n = new_self(p);
    Node *n = list3(atom(ATOM_fcall), b, c);
    return n;
  }

  /* (:block_arg . a) */
  static Node*
  new_block_arg(ParserState *p, Node *a)
  {
    return cons((Node*)NODE_BLOCK_ARG, a);
  }

  /* (:dstr . a) */
  static Node*
  new_dstr(ParserState *p, Node *a)
  {
    return list2(atom(ATOM_string_literal), a);
    //return cons((Node*)NODE_DSTR, a);
  }
}

%parse_accept {
#ifndef NDEBUG
  printf("Parse has completed successfully.\n");
#endif
}
%syntax_error {
#ifndef NDEBUG
  fprintf(stderr, "Syntax error\n");
#endif
  p->error_count++;
}
%parse_failure {
#ifndef NDEBUG
  fprintf(stderr, "Parse failure\n");
#endif
  p->error_count++;
}

%start_symbol program

%nonassoc LOWEST.
%nonassoc LBRACE_ARG.
%left PLUS MINUS.
%left DIVIDE TIMES.

program ::= top_compstmt(B).   {
//  if (!p->locals) p->locals = cons(atom(":program"),0);
  //if (!p->locals) {Node *a = cons(atom(":program"),0);}
  yypParser->p->root = list2(atom(ATOM_program), B); }
top_compstmt(A) ::= top_stmts(B) opt_terms. { A = B; }
top_stmts(A) ::= none. { A = new_begin(p, 0); }
top_stmts(A) ::= top_stmt(B). { A = new_begin(p, B); }
top_stmts(A) ::= top_stmts(B) terms top_stmt(C). {
  A = append(B, newline_node(C)); // TODO mrubyのparse.yではpushになっている。。。
  }
top_stmt ::= stmt.
//stmts(A) ::= stmt(B). { A = new_begin(B); }

stmt ::= expr.

expr ::= command_call.
expr ::= arg.

command_call ::= command.

command(A) ::= operation(B) command_args(C). [LOWEST] { A = new_fcall(p, B, C); }

command_args ::= call_args.

call_args(A) ::= args(B) opt_block_arg(C). { A = list3(atom(ATOM_args_add_block), B, C); }

block_arg(A) ::= AMPER arg(B). { A = new_block_arg(p, B); }
opt_block_arg(A) ::= COMMA block_arg(B). { A = B; }
opt_block_arg(A) ::= none. { A = 0; }

args(A) ::= arg(B). { A = list3(atom(ATOM_args_add), list1(atom(ATOM_args_new)), B); }
args(A) ::= args(B) COMMA arg(C). { A = append(B, C); }

arg(A) ::= lhs(B) E arg_rhs(C). { A = new_asgn(p, B, C); }
//arg(A) ::= arg(B) PLUS arg(C).   { A = call_bin_op(B, PLUS ,C); }
//arg(A) ::= arg(B) MINUS arg(C).  { A = call_bin_op(B, MINUS, C); }
//arg(A) ::= arg(B) TIMES arg(C).  { A = call_bin_op(B, TIMES, C); }
//arg(A) ::= arg(B) DIVIDE arg(C). { A = call_bin_op(B, DIVIDE, C); }
arg ::= primary.

arg_rhs ::= arg.

lhs ::= variable.

variable(A) ::= IDENTIFIER(B). { A = new_lvar(p, B); }
variable(A) ::= IVAR(B).       { A = new_ivar(p, B); }
variable(A) ::= GVAR(B).       { A = new_gvar(p, B); }
variable(A) ::= CONSTANT(B).   { A = new_const(p, B); }

primary ::= literal.
primary ::= string.
primary ::= var_ref.
primary(A) ::= LPAREN_ARG stmt(B) RPAREN. { A = B; }
primary ::= method_call.

method_call(A) ::= operation(B) paren_args(C). { A = new_fcall(p, B, C); }

paren_args(A) ::= LPAREN opt_call_args(B) RPAREN. { A = B; }

opt_call_args ::= none.
opt_call_args ::= call_args opt_terms.

literal ::= numeric.
literal ::= symbol.

var_ref ::= variable.

numeric(A) ::= INTEGER(B). { A = new_lit(p, B, ATOM_at_int, 10, 0); }
numeric(A) ::= FLOAT(B).   { A = new_lit(p, B, ATOM_at_float, 10, 0); }
numeric(A) ::= UMINUS_NUM INTEGER(B). { A = new_neglit(p, B, ATOM_at_int, 10, 0); }
numeric(A) ::= UMINUS_NUM FLOAT(B).   { A = new_neglit(p, B, ATOM_at_float, 10, 0); }

symbol(A) ::= basic_symbol(B). { A = new_sym(p, B); }

basic_symbol(A) ::= SYMBEG sym(B). { A = B; }

sym ::= fname.

fname ::= IDENTIFIER.
fname ::= CONSTANT.
fname ::= FID.

string ::= string_fragment.
//string ::= string string_fragment. { A = concat_string(p, B, C); }
string_fragment(A) ::= STRING_BEG string_rep(C) STRING_END. { A = new_dstr(p, list3(atom(ATOM_string_add), list1(atom(ATOM_string_content)), C)); }

string_rep ::= string_interp.
string_rep(A) ::= string_rep(B) string_interp(C). { A = append(B, C); }

string_interp(A) ::= STRING_MID(B). { A = list2(atom(ATOM_at_tstring_content), literal(B)); }

operation(A) ::= IDENTIFIER(B). { A = list2(atom(ATOM_at_ident), literal(B)); }
operation ::= CONSTANT.
operation ::= FID.

opt_terms ::= .
opt_terms ::= terms.
terms ::= term.
terms ::= terms term.

term ::= NL.
term ::= SEMICOLON.
none(A) ::= . { A = 0; }

%code {
  void *pointerToMalloc(void){
    return malloc;
  }

  void *pointerToFree(void){
    return free;
  }

  ParserState *ParseInitState(void)
  {
    ParserState *p = LEMON_ALLOC(sizeof(ParserState));
    p->literal_store = LEMON_ALLOC(sizeof(LiteralStore));
    p->literal_store->str = NULL;
    p->literal_store->prev = NULL;
    p->error_count = 0;
    return p;
  }

  void freeLiteralStore(LiteralStore *literal_store)
  {
    if (literal_store == NULL) return;
    freeLiteralStore(literal_store->prev);
    LEMON_FREE(literal_store->str);
    LEMON_FREE(literal_store);
  }

  void ParserStateFree(ParserState *p) {
    freeLiteralStore(p->literal_store);
    LEMON_FREE(p);
  }

  void freeNode(Node *n) {
    //printf("before free cons: %p\n", n);
    if (n == NULL)
      return;
    if (n->type == CONS) {
      freeNode(n->cons.car);
      freeNode(n->cons.cdr);
    } else if (n->type == LITERAL) {
      LEMON_FREE(n->value.name);
    }
    //printf("after free cons: %p\n", n);
    LEMON_FREE(n);
  }

  void ParseFreeAllNode(yyParser *yyp) {
    freeNode(yyp->p->root);
  }

  LiteralStore *ParsePushLiteralStore(ParserState *p, char *s)
  {
    LiteralStore *ls = LEMON_ALLOC(sizeof(LiteralStore));
    ls->str = strdup(s);
    ls->prev = p->literal_store;
    p->literal_store = ls;
    return ls;
  }

#ifndef NDEBUG
  void showNode1(Node *n, bool isCar, int indent, bool isRightMost) {
    if (n == NULL) return;
    switch (n->type) {
      case CONS:
        if (isCar) {
          printf("\n");
          for (int i=0; i<indent; i++) {
            printf(" ");
          }
          printf("[");
        } else {
          printf(", ");
        }
        if (n->cons.car && n->cons.car->type != CONS && n->cons.cdr == NULL) {
          isRightMost = true;
        }
        break;
      case ATOM:
        printf("%s", atom_name(n->atom.type));
        if (isRightMost) {
          printf("]");
        }
        break;
      case LITERAL:
        printf("\e[31;1m\"%s\"\e[m", n->value.name);
        if (isRightMost) {
          printf("]");
        }
        break;
    }
    if (n->type == CONS) {
      showNode1(n->cons.car, true, indent+1, isRightMost);
      showNode1(n->cons.cdr, false, indent, isRightMost);
    }
  }

  void showNode2(Node *n) {
    if (n == NULL) return;
    switch (n->type) {
      case ATOM:
        printf("    atom:%p", n);
        printf("  value:%d\n", n->atom.type);
        break;
      case LITERAL:
        printf("    literal:%p", n);
        printf("  name:\"%s\"\n", n->value.name);
        break;
      case CONS:
        printf("cons:%p\n", n);
        printf(" car:%p\n", n->cons.car);
        printf(" cdr:%p\n", n->cons.cdr);
        showNode2(n->cons.car);
        showNode2(n->cons.cdr);
    }
  }

  void ParseShowAllNode(yyParser *yyp, int way) {
    if (way == 1) {
      showNode1(yyp->p->root, true, 0, false);
    } else if (way == 2) {
      showNode2(yyp->p->root);
    }
    printf("\n");
  }
#endif /* !NDEBUG */

  void *pointerToRoot(yyParser *yyp){
    return yyp->p->root;
  }

  bool hasCar(Node *n) {
    if (n->type != CONS)
      return false;
    if (n->cons.car) {
      return true;
    }
    return false;
  }

  bool hasCdr(Node *n) {
    if (n->type != CONS)
      return false;
    if (n->cons.cdr) {
      return true;
    }
    return false;
  }

  char *kind(Node *n){
    char *type;
    switch (n->type) {
      case ATOM:
        type = "a";
        break;
      case LITERAL:
        type = "l";
        break;
      case CONS:
        type = "c";
        break;
    }
    return type;
  }

  int atom_type(Node *n) {
    if (n->type != ATOM) {
      return ATOM_NONE;
    }
    return n->atom.type;
  }

  void *pointerToLiteral(Node *n) {
    return n->value.name;
  }

  void *pointerToCar(Node *n){
    return n->cons.car;
  }

  void *pointerToCdr(Node *n){
    return n->cons.cdr;
  }

}
