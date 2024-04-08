grammar PL;

@header {
import backend.*;
}

@members {
    void display(String text){
        System.out.println(text);
    }
}

program returns [Expr expr] : 
        { List <Expr> statements = new ArrayList<Expr>(); }
        (statement 
            { statements.add($statement.expr);} 
        )+ EOF
        { $expr = new Block (statements);}
        ;

statement returns [Expr expr]
    : assignment (';')*                  { $expr = $assignment.expr; }
    | forLoop                            { $expr = $forLoop.expr; }
    | whileLoop                          { $expr = $whileLoop.expr; }
    | ifelse                             { $expr = $ifelse.expr; }
    | expression (';')*                  { $expr = $expression.expr; }
    | functionDeclaration                { $expr = $functionDeclaration.expr; }
    ;

assignment returns [Expr expr]
    : ID '=' expression               { $expr = new Assign($ID.text, $expression.expr); }
    ;

expression returns [Expr expr]
    : funcName=ID '(' p=parameterList ')'     { $expr = new Invoke($funcName.text, $p.returnParams);}
    | BINARY                                  { $expr = new BinaryLiteral($BINARY.text); }
    | BOOLEAN                                 { $expr = new BooleanLiteral($BOOLEAN.text); }
    | NUMERIC                                 { $expr = new IntLiteral($NUMERIC.text); }
    | STRING                                  { $expr = new StringLiteral($STRING.text); }
    | ID                                      { $expr = new Deref($ID.text); }
    | 'print(' expression ')'                 { $expr = new Print($expression.expr); }
    | '(' expression ')'                      { $expr = $expression.expr; }
    | '!' expression                          { $expr = new NotExpr($expression.expr); }
    | a=expression '||' b=expression          { $expr = new OrExpr($a.expr, $b.expr); }
    | a=expression '&&' b=expression          { $expr = new AndExpr($a.expr, $b.expr); }
    | a=expression '^^' b=expression          { $expr = new XorExpr($a.expr, $b.expr); }
    | a=expression '+' b=expression           { $expr = new Arithmetics(Operator.Add, $a.expr, $b.expr); }
    | a=expression '-' b=expression           { $expr = new Arithmetics(Operator.Sub, $a.expr, $b.expr); }
    | a=expression '++' b=expression          { $expr = new ConcatExpr($a.expr, $b.expr); }
    | a=expression '*' b=expression           { $expr = new Arithmetics(Operator.Mul, $a.expr, $b.expr); }
    | a=expression '/' b=expression           { $expr = new Arithmetics(Operator.Div, $a.expr, $b.expr); }
    | a=expression '<=' b=expression          { $expr = new Compare(Comparator.LE, $a.expr, $b.expr); }
    | a=expression '>=' b=expression          { $expr = new Compare(Comparator.GE, $a.expr, $b.expr); }
    | a=expression '==' b=expression          { $expr = new Compare(Comparator.EQ, $a.expr, $b.expr); }
    | a=expression '!=' b=expression          { $expr = new Compare(Comparator.NE, $a.expr, $b.expr); }
    | a=expression '<' b=expression           { $expr = new Compare(Comparator.LT, $a.expr, $b.expr); }
    | a=expression '>' b=expression           { $expr = new Compare(Comparator.GT, $a.expr, $b.expr); }
    | a=expression '&' b=expression           { $expr = new Bitwise(BitwiseEx.AND, $a.expr, $b.expr); }
    | a=expression '|' b=expression           { $expr = new Bitwise(BitwiseEx.OR, $a.expr, $b.expr); }
    | a=expression '^' b=expression           { $expr = new Bitwise(BitwiseEx.XOR, $a.expr, $b.expr); }
    | a=expression '<<' b=expression          { $expr = new Bitwise(BitwiseEx.LS, $a.expr, $b.expr); }
    | a=expression '>>' b=expression          { $expr = new Bitwise(BitwiseEx.RS, $a.expr, $b.expr); }
    | '~' a=expression                        { $expr = new Bitwise(BitwiseEx.NOT, $a.expr, $a.expr); }
    ;

comparison returns [Expr expr]
    : a=expression '<=' b=expression           { $expr = new Compare(Comparator.LE, $a.expr, $b.expr); }
    | a=expression '>=' b=expression           { $expr = new Compare(Comparator.GE, $a.expr, $b.expr); }
    | a=expression '==' b=expression           { $expr = new Compare(Comparator.EQ, $a.expr, $b.expr); }
    | a=expression '!=' b=expression           { $expr = new Compare(Comparator.NE, $a.expr, $b.expr); }
    | a=expression '<' b=expression            { $expr = new Compare(Comparator.LT, $a.expr, $b.expr); }
    | a=expression '>' b=expression            { $expr = new Compare(Comparator.GT, $a.expr, $b.expr); }
    ;
    
bitwise returns [Expr expr]
    : a=expression '&' b=expression           { $expr = new Bitwise(BitwiseEx.AND, $a.expr, $b.expr); }
    | a=expression '|' b=expression           { $expr = new Bitwise(BitwiseEx.OR, $a.expr, $b.expr); }
    | a=expression '^' b=expression           { $expr = new Bitwise(BitwiseEx.XOR, $a.expr, $b.expr); }
    | a=expression '<<' b=expression          { $expr = new Bitwise(BitwiseEx.LS, $a.expr, $b.expr); }
    | a=expression '>>' b=expression          { $expr = new Bitwise(BitwiseEx.RS, $a.expr, $b.expr); }
    | a=expression '~' b=expression           { $expr = new Bitwise(BitwiseEx.NOT, $a.expr, $b.expr); }
    ;

ifelse returns [Expr expr] :
    { List<Expr> trueStatements = new ArrayList<Expr>(); }
    { List<Expr> falseStatements = new ArrayList<Expr>(); }
    'if' '(' comparison ')' '{' (ifStatement=statement {trueStatements.add($ifStatement.expr);})+ '}' ('else' '{' (elseStatement=statement {falseStatements.add($elseStatement.expr);})+ '}' )*
    { $expr = new Ifelse($comparison.expr, new Block(trueStatements), new Block(falseStatements)); }
    ;

forLoop returns [Expr expr] : 
    { List <Expr> stmts = new ArrayList<Expr>(); }
    'for' '(' name=ID ' in ' lowerBound=NUMERIC '..' upperBound=NUMERIC ')' '{' 
        (statement 
            { stmts.add($statement.expr);} 
        )+
    '}'
    { $expr = new ForLoop($name.text, $lowerBound.text, $upperBound.text, stmts);};
    
whileLoop returns [Expr expr] : 
    { List <Expr> stmts = new ArrayList<Expr>(); }
    'while' '(' comparison ')' '{' 
        (statement 
            { stmts.add($statement.expr);} 
        )+
    '}'
    { $expr = new WhileLoop($comparison.expr, stmts);};
    
functionDeclaration returns [Expr expr]
    : {List<Expr> funcStatements = new ArrayList<Expr>();} 
    'function' name=ID '(' params=parameterList ')' '{' (statement {funcStatements.add($statement.expr);})* '}' {$expr = new Declare($name.text, $params.returnParams, new Block(funcStatements));}
    ;

parameterList returns [List<Expr> returnParams]
    : { List <Expr> params = new ArrayList<Expr>(); }
      (a=(ID|STRING) {params.add(new StringLiteral($a.text)); } | (expression {params.add($expression.expr);}))
      ((',' b=(ID|STRING) { params.add(new StringLiteral($b.text)); }) | (',' expression {params.add($expression.expr);}))* 
      {$returnParams = params;}
    | a=NUMERIC { List <Expr> params = new ArrayList<Expr>(); params.add(new IntLiteral($a.text)); } (',' b=(ID|STRING) { params.add(new IntLiteral($b.text)); })* {$returnParams = params;}
    ;

BINARY : '0b' ('0' | '1')+;
NUMERIC : ('0' .. '9')+;
STRING : '"' ( '\\"' | ~'"' )* '"';
BOOLEAN : 'true' | 'false';
ID : ('a' .. 'z' | 'A' .. 'Z' | '_') ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_')*;
COMMENT : '/*' .*? '*/' -> skip;
WHITESPACE : (' ' | '\t' | '\r' | '\n')+ -> skip;
