grammar PL;

@header {
import backend.*;
}

@members {
}

program returns [Expr expr] : 
        { List <Expr> statements = new ArrayList<Expr>(); }
        (statement 
            { statements.add($statement.expr);} 
        )+ EOF
        { $expr = new Block (statements);}
        ;

statement returns [Expr expr]
    : assignment (';')*                      { $expr = $assignment.expr; }
    | forLoop                                { $expr = $forLoop.expr; }
    | function                               { $expr = $function.expr; }
    | expression (';')*                      { $expr = $expression.expr; }
    | ifElse                                 { $expr = $ifElse.expr; }
    ;

assignment returns [Expr expr]
    : 'let'? ID '=' expression               { $expr = new Assign($ID.text, $expression.expr); }
    ;

forLoop returns [Expr expr] : 
    { List <Expr> statements = new ArrayList<Expr>(); }
    'for' '(' ID ' in ' Start=INTEGER '..' End=INTEGER ')' '{' 
        (statement 
            { statements.add($statement.expr);} 
        )+
    '}'
    { $expr = new ForLoop($ID.text, $Start.text, $End.text, statements);};
    
ifElse returns [Expr expr] : 
    { List <Expr> statementsT = new ArrayList<Expr>(); }
    { List <Expr> statementsF = new ArrayList<Expr>(); }
    'if' '(' expression ')' '{' 
        (statement 
            { statementsT.add($statement.expr);} 
        )+
    '}' ( 'else' '{'
        (statement
            { statementsF.add($statement.expr);}
        )+
    '}' )?
    { $expr = new Ifelse($expression.expr, new Block(statementsT), new Block(statementsF));};

expression returns [Expr expr]
    : ID '(' parameters ')'                  { $expr = new Invoke($ID.text, $parameters.list);}
    | '(' expression ')'                     { $expr = $expression.expr; }
    | INTEGER                                { $expr = new IntLiteral($INTEGER.text); }
    | STRING                                 { $expr = new StringLiteral($STRING.text); }
    | ID                                     { $expr = new Deref($ID.text); }
    | 'print(' expression ')'                { $expr = new Print($expression.expr); }
    | e1=expression '++' e2=expression       { $expr = new ConcatExpr($e1.expr, $e2.expr); }
    | e1=expression '+' e2=expression        { $expr = new Arithmetics(Operator.Add, $e1.expr, $e2.expr); }
    | e1=expression '-' e2=expression        { $expr = new Arithmetics(Operator.Sub, $e1.expr, $e2.expr); }
    | e1=expression '*' e2=expression        { $expr = new Arithmetics(Operator.Mul, $e1.expr, $e2.expr); }
    | e1=expression '/' e2=expression        { $expr = new Arithmetics(Operator.Div, $e1.expr, $e2.expr); }
    | e1=expression '<' e2=expression        { $expr = new Compare(Comparator.LT, $e1.expr, $e2.expr); }
    | e1=expression '<=' e2=expression       { $expr = new Compare(Comparator.LE, $e1.expr, $e2.expr); }
    | e1=expression '>' e2=expression        { $expr = new Compare(Comparator.GT, $e1.expr, $e2.expr); }
    | e1=expression '>=' e2=expression       { $expr = new Compare(Comparator.GE, $e1.expr, $e2.expr); }
    | e1=expression '==' e2=expression       { $expr = new Compare(Comparator.EQ, $e1.expr, $e2.expr); }
    | e1=expression '!=' e2=expression       { $expr = new Compare(Comparator.NE, $e1.expr, $e2.expr); }
    ;

function returns [Expr expr]:
    {List<Expr> statements = new ArrayList<Expr>();} 
    'function' ID '(' parameters ')' '{' 
        (statement
            { statements.add($statement.expr);}
        )* 
     '}'
     { $expr = new Declare($ID.text, $parameters.list, new Block(statements));}
    ;
    
parameters returns [List<Expr> list]
    : { List <Expr> statements = new ArrayList<Expr>(); }
    (
        ID {statements.add(new StringLiteral($ID.text)); } | (expression {statements.add($expression.expr);})
    )
    (
        (',' ID { statements.add(new StringLiteral($ID.text)); }) | (',' expression {statements.add($expression.expr);})
    )* 
      {$list = statements;}
    ;
    
INTEGER : ('0' .. '9')+;
STRING : '"' ( '\\"' | ~'"' )* '"';
BOOLEAN : 'true' | 'false';
ID : ('a' .. 'z' | 'A' .. 'Z' | '_') ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_')*;
COMMENT : '/*' .*? '*/' -> skip;
WHITESPACE : (' ' | '\t' | '\r' | '\n')+ -> skip;
