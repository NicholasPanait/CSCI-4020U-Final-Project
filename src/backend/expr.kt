package backend

abstract class Expr {
    abstract fun eval(runtime:Runtime):Data
}

class NoneExpr(): Expr() {
    override fun eval(runtime:Runtime) = None
}

class IntLiteral(val lexeme:String): Expr() {
    override fun eval(runtime:Runtime): Data = IntData(Integer.parseInt(lexeme))
    override fun toString(): String = lexeme
}

class BinaryLiteral(val lexeme:String): Expr() {
    override fun eval(runtime:Runtime): Data = BinaryData(Integer.parseInt(lexeme.drop(2)))
    override fun toString(): String = lexeme
}

class StringLiteral(val lexeme:String): Expr() {
    override fun eval(runtime:Runtime): Data = StringData(lexeme.replace("\"", ""))
    override fun toString(): String = lexeme
}

class BooleanLiteral(val lexeme:String): Expr() {
    override fun eval(runtime:Runtime): Data = BooleanData(lexeme.equals("true"))
    override fun toString(): String = lexeme
}

class Assign(val symbol:String, val expr:Expr): Expr() {
    override fun eval(runtime:Runtime): Data
    = expr.eval(runtime).apply {
        runtime.symbolTable.put(symbol, this)
    }
}

class NotExpr(val expr: Expr) : Expr() {
    override fun eval(runtime: Runtime): Data {
        val bool = expr.eval(runtime)

        if (bool is BooleanData) {
            return BooleanData(!(bool.value))
        }
        else {
            throw Exception("You must pass a Boolean operand")
        }
    }
}

class OrExpr(val expr1: Expr, val expr2: Expr) : Expr() {
    override fun eval(runtime: Runtime): Data {
        val left = expr1.eval(runtime)
        val right = expr2.eval(runtime)

        if (left is BooleanData && right is BooleanData) {
            return BooleanData(left.value || right.value)
        }
        else {
            throw Exception("You must pass 2 Boolean operands")
        }
    }
}

class AndExpr(val expr1: Expr, val expr2: Expr) : Expr() {
    override fun eval(runtime: Runtime): Data {
        val left = expr1.eval(runtime)
        val right = expr2.eval(runtime)

        if (left is BooleanData && right is BooleanData) {
            return BooleanData(left.value && right.value)
        }
        else {
            throw Exception("You must pass 2 Boolean operands")
        }
    }
}

class XorExpr(val expr1: Expr, val expr2: Expr) : Expr() {
    override fun eval(runtime: Runtime): Data {
        val left = expr1.eval(runtime)
        val right = expr2.eval(runtime)

        if (left is BooleanData && right is BooleanData) {
            if (left.value != right.value){
                return BooleanData(true)
            }
            else{
                return BooleanData(false)
            }
        }
        else {
            throw Exception("You must pass 2 Boolean operands")
        }
    }
}

class Deref(val name:String): Expr() {
    override fun eval(runtime:Runtime):Data {
        val data = runtime.symbolTable[name]
        if(data == null) {
            throw Exception("$name is not assigned.")
        }
        return data
    }
}

class Print(val output:Expr):Expr() {
    override fun eval(runtime:Runtime):Data {
        System.out.println(output.eval(runtime))
        return None
    }
}

class Block(val exprList: List<Expr>): Expr() {
    override fun eval(runtime:Runtime): Data {
        var result:Data = None
        exprList.forEach {
            result = it.eval(runtime)
        }
        return result
    }
}

class ConcatExpr(val expr1: Expr, val expr2: Expr) : Expr() {
    override fun eval(runtime: Runtime): Data {
        val left = expr1.eval(runtime)
        val right = expr2.eval(runtime)

        if (left is StringData && right is StringData) {
            return StringData(left.value + right.value)
        } else {
            throw Exception("Both operands must be strings")
        }
    }
}

enum class Operator {
    Add,
    Sub,
    Mul,
    Div
}

class Arithmetics(val op:Operator, val left:Expr, val right:Expr): Expr() {
    override fun eval(runtime:Runtime): Data {
        val x = left.eval(runtime)
        val y = right.eval(runtime)
        if(x is IntData && y is IntData) {
            return IntData(
                when(op) {
                    Operator.Add -> x.value + y.value
                    Operator.Sub -> x.value - y.value
                    Operator.Mul -> x.value * y.value
                    Operator.Div -> {
                        if(y.value != 0) {
                            x.value / y.value
                        } else {
                            throw Exception("cannot divide by zero")
                        }
                    }
                }
            )
        }
        else if(x is StringData && y is IntData) {
            if(op != Operator.Mul){
                throw Exception("cannot use + - / with a String and Int")
            }
            var count = 1
            var result = x.value
            while (count < y.value) {
                result += x.value
                count++
            }
            return StringData(result)
        }
        else if(x is IntData && y is StringData) {
            if(op != Operator.Mul){
                throw Exception("cannot use + - / with a String and Int")
            }
            var count = 1
            var result = y.value
            while (count < x.value) {
                result += y.value
                count++
            }
            return StringData(result)
        }
        else if (x is BinaryData && y is BinaryData) {
            val intx = x.toString().toInt(2)
            val inty = y.toString().toInt(2)
            return BinaryData (
                when(op) {
                    Operator.Add -> Integer.toBinaryString(intx + inty).toInt()
                    Operator.Sub -> Integer.toBinaryString(intx - inty).toInt()
                    Operator.Mul -> Integer.toBinaryString(intx * inty).toInt()
                    Operator.Div -> {
                        if(inty != 0) {
                            Integer.toBinaryString(intx / inty).toInt()
                        } else {
                            throw Exception("cannot divide by zero")
                        }
                    }
                }
            )
        }
        throw Exception("cannot handle non-integer")
    }
}

class ForLoop(val name: String, val start: String, val end: String, val exprList: List<Expr>): Expr() {
    override fun eval(runtime:Runtime):Data {
        val s = start.toInt()
        val e = end.toInt()
        Assign(name, IntLiteral(start)).eval(runtime)
        for (i in s .. e){
            Assign(name, IntLiteral("$i")).eval(runtime)
            exprList.forEach {
                it.eval(runtime)
            }
        }
        return None
    }
}

class Declare(val name: String, val params: List<Expr>, val body: Expr): Expr() {
    override fun eval(runtime:Runtime):Data {
        var p: List<String> = params.map{
            it.eval(runtime).toString()
        }.toList()
        return FuncData(name, p, body).also {
            runtime.symbolTable[name] = it
        }
    }
}

class Invoke(val name:String, val args:List<Expr>):Expr() {
    override fun eval(runtime:Runtime):Data {
        val func:Data? = runtime.symbolTable[name]
        if(func == null) {
            throw Exception("$name does not exist")
        }
        if(func !is FuncData) {
            throw Exception("$name is not a function.")
        }
        if(func.params.size != args.size) {
            throw Exception(
                "$name expects ${func.params.size} arguments "
                + "but received ${args.size}"
            )
        }
        val r = runtime.subscope(
            func.params.zip(args.map {it.eval(runtime)}).toMap()
        )
        return func.body.eval(r)
    }
}

enum class Comparator {
    LT,
    LE,
    GT,
    GE,
    EQ,
    NE,
}

class Compare(val comparator: Comparator, val left: Expr, val right: Expr ): Expr() {
    override fun eval(runtime:Runtime): Data {
        val x = left.eval(runtime)
        val y = right.eval(runtime)
        if(x is IntData && y is IntData) {
            return BooleanData(
                when(comparator) {
                    Comparator.LT -> x.value < y.value
                    Comparator.LE -> x.value <= y.value
                    Comparator.GT -> x.value > y.value
                    Comparator.GE -> x.value >= y.value
                    Comparator.EQ -> x.value == y.value
                    Comparator.NE -> x.value != y.value
                }
            )
        } else {
            throw Exception("Non-integer data in comparison")
        }
    }
}

fun Int.toBinaryString(): String {
    val paddingLength = 8 - Integer.toBinaryString(this).length
    return "0".repeat(paddingLength) + Integer.toBinaryString(this)
}

fun String.toBinaryInt(): Int {
    return Integer.parseInt(this, 2)
}

enum class BitwiseEx {
    AND,
    OR,
    XOR,
    LS,
    RS,
    NOT
}

class Bitwise(val op:BitwiseEx, val left:Expr, val right:Expr): Expr() {
    override fun eval(runtime:Runtime): Data {
        val x = left.eval(runtime)
        val y = right.eval(runtime)
        if(x is IntData && y is IntData) {
            return IntData(
                when (op) {
                    BitwiseEx.AND -> x.value and y.value
                    BitwiseEx.OR -> x.value or y.value
                    BitwiseEx.XOR -> x.value xor y.value
                    BitwiseEx.LS -> x.value shl y.value
                    BitwiseEx.RS -> x.value shr y.value
                    BitwiseEx.NOT -> x.value.inv() and 0xFF
                }
            )
        }
        val xb = x.toString().toInt(2)
        val yb = y.toString().toInt(2)
        return StringData(
            when (op) {
                BitwiseEx.AND -> (xb and yb).toBinaryString()
                BitwiseEx.OR -> (xb or yb).toBinaryString()
                BitwiseEx.XOR -> (xb xor yb).toBinaryString()
                BitwiseEx.LS -> (xb shl yb).toBinaryString()
                BitwiseEx.RS -> (xb shr yb).toBinaryString()
                BitwiseEx.NOT -> (xb.inv() and 0xFF).toBinaryString()
            }
        )
    }
}

class Ifelse(val cond:Expr, val trueExpr:Expr, val falseExpr:Expr ): Expr() {
    override fun eval(runtime:Runtime): Data {
        val cond_data = cond.eval(runtime)
        if(cond_data !is BooleanData) {
            throw Exception("need boolean data in if-else")
        }
        if(cond_data.value) {
            return trueExpr.eval(runtime)
        } else {
            return falseExpr.eval(runtime)
        }
    }
}

class WhileLoop(val cond:Expr, val exprList: List<Expr>): Expr() {
    override fun eval(runtime:Runtime): Data {
        var flag = cond.eval(runtime) as BooleanData
        var iter:Int = 1_000_000
        while(flag.value) {
            exprList.forEach {
                it.eval(runtime)
            }
            flag = cond.eval(runtime) as BooleanData
            if(iter == 0) {
                println("MAX_ITER reached")
                println(runtime)
                return None
            }
            iter --
        }
        return None
    }
}