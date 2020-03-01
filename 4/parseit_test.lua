#!/usr/bin/env lua
-- parseit_test.lua
-- Glenn G. Chappell
-- 2020-02-24
--
-- For CS F331 / CSCE A331 Spring 2020
-- Test Program for Module parseit
-- Used in Assignment 4, Exercise 1

parseit = require "parseit"  -- Import parseit module


-- *********************************************
-- * YOU MAY WISH TO CHANGE THE FOLLOWING LINE *
-- *********************************************

EXIT_ON_FIRST_FAILURE = true
-- If EXIT_ON_FIRST_FAILURE is true, then this program exits after the
-- first failing test. If it is false, then this program executes all
-- tests, reporting success/failure for each.


-- *********************************************************************
-- Testing Package
-- *********************************************************************


tester = {}
tester.countTests = 0
tester.countPasses = 0

function tester.test(self, success, testName)
    self.countTests = self.countTests+1
    io.write("    Test: " .. testName .. " - ")
    if success then
        self.countPasses = self.countPasses+1
        io.write("passed")
    else
        io.write("********** FAILED **********")
    end
    io.write("\n")
end

function tester.allPassed(self)
    return self.countPasses == self.countTests
end


-- *********************************************************************
-- Utility Functions
-- *********************************************************************


function failExit()
    if EXIT_ON_FIRST_FAILURE then
        io.write("**************************************************\n")
        io.write("* This test program is configured to exit after  *\n")
        io.write("* the first failing test. To make it execute all *\n")
        io.write("* tests, reporting success/failure for each, set *\n")
        io.write("* variable                                       *\n")
        io.write("*                                                *\n")
        io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
        io.write("*                                                *\n")
        io.write("* to false, near the start of the test program.  *\n")
        io.write("**************************************************\n")

        -- Wait for user
        io.write("\nPress ENTER to quit ")
        io.read("*l")

        -- Terminate program
        os.exit(1)
    end
end


function endMessage(passed)
    if passed then
        io.write("All tests successful\n")
    else
        io.write("Tests ********** UNSUCCESSFUL **********\n")
        io.write("\n")
        io.write("**************************************************\n")
        io.write("* This test program is configured to execute all *\n")
        io.write("* tests, reporting success/failure for each. To  *\n")
        io.write("* make it exit after the first failing test, set *\n")
        io.write("* variable                                       *\n")
        io.write("*                                                *\n")
        io.write("*   EXIT_ON_FIRST_FAILURE                        *\n")
        io.write("*                                                *\n")
        io.write("* to true, near the start of the test program.   *\n")
        io.write("**************************************************\n")
    end
end


-- printValue
-- Given a value, print it in (roughly) Lua literal notation if it is
-- nil, number, string, boolean, or table -- calling this function
-- recursively for table keys and values. For other types, print an
-- indication of the type.
function printValue(...)
    if select("#", ...) ~= 1 then
        error("printValue: must pass exactly 1 argument")
    end
    local x = select(1, ...)  -- Get argument (which may be nil)

    if type(x) == "nil" then
        io.write("nil")
    elseif type(x) == "number" then
        io.write(x)
    elseif type(x) == "string" then
        io.write('"'..x..'"')
    elseif type(x) == "boolean" then
        if x then
            io.write("true")
        else
            io.write("false")
        end
    elseif type(x) ~= "table" then
        io.write('<'..type(x)..'>')
    else  -- type is "table"
        io.write("{ ")
        local first = true  -- First iteration of loop?
        for k, v in pairs(x) do
            if first then
                first = false
            else
                io.write(", ")
            end
            io.write("[")
            printValue(k)
            io.write("]=")
            printValue(v)
        end
        io.write(" }")
    end
end


-- printArray
-- Like printValue, but prints top-level tables as arrays.
-- Uses printValue.
function printArray(...)
    if select("#", ...) ~= 1 then
        error("printArray: must pass exactly 1 argument")
    end
    local x = select(1, ...)  -- Get argument (which may be nil)

    if type(x) ~= "table" then
        printValue(x)
    else
        io.write("{ ")
        local first = true  -- First iteration of loop?
        for k, v in ipairs(x) do
            if first then
                first = false
            else
                io.write(", ")
            end
            printValue(v)
        end
        io.write(" }")
    end
end


-- equal
-- Compare equality of two values. Returns false if types are different.
-- Uses "==" on non-table values. For tables, recurses for the value
-- associated with each key.
function equal(...)
    if select("#", ...) ~= 2 then
        error("equal: must pass exactly 2 arguments")
    end
    local x1, x2 = select(1, ...)  -- Get arguments (which may be nil)

    local type1 = type(x1)
    if type1 ~= type(x2) then
        return false
    end

    if type1 ~= "table" then
       return x1 == x2
    end

    -- Get number of keys in x1 & check values in x1, x2 are equal
    local x1numkeys = 0
    for k, v in pairs(x1) do
        x1numkeys = x1numkeys + 1
        if not equal(v, x2[k]) then
            return false
        end
    end

    -- Check number of keys in x1, x2 same
    local x2numkeys = 0
    for k, v in pairs(x2) do
        x2numkeys = x2numkeys + 1
    end
    return x1numkeys == x2numkeys
end


-- getCoroutineValues
-- Given coroutine f, returns array of all values yielded by f when
-- passed param as its parameter, in the order the values are yielded.
function getCoroutineValues(f, param)
    assert(type(f)=="function",
           "getCoroutineValues: f is not a function")
    local covals = {}  -- Array of values yielded by coroutine f
    local co = coroutine.create(f)
    local ok, value = coroutine.resume(co, param)
    while (coroutine.status(co) ~= "dead") do
        table.insert(covals, value)
        ok, value = coroutine.resume(co)
    end
    assert(ok, "Error in coroutine")
    return covals
end


-- *********************************************************************
-- Definitions for This Test Program
-- *********************************************************************


-- Symbolic Constants for AST
-- Names differ from those in assignment, to avoid interference.
local STMTxLIST    = 1
local PRINTxSTMT   = 2
local FUNCxDEF     = 3
local FUNCxCALL    = 4
local IFxSTMT      = 5
local WHILExSTMT   = 6
local RETURNxSTMT  = 7
local ASSNxSTMT    = 8
local STRLITxOUT   = 9
local CHARxCALL    = 10
local BINxOP       = 11
local UNxOP        = 12
local NUMLITxVAL   = 13
local BOOLLITxVAL  = 14
local INPUTxCALL   = 15
local SIMPLExVAR   = 16
local ARRAYxVAR    = 17


-- String forms of symbolic constants

symbolNames = {
  [1]="STMT_LIST",
  [2]="PRINT_STMT",
  [3]="FUNC_DEF",
  [4]="FUNC_CALL",
  [5]="IF_STMT",
  [6]="WHILE_STMT",
  [7]="RETURN_STMT",
  [8]="ASSN_STMT",
  [9]="STRLIT_OUT",
  [10]="CHAR_CALL",
  [11]="BIN_OP",
  [12]="UN_OP",
  [13]="NUMLIT_VAL",
  [14]="BOOLLIT_VAL",
  [15]="INPUT_CALL",
  [16]="SIMPLE_VAR",
  [17]="ARRAY_VAR",
}


-- printAST_parseit
-- Write an AST, in (roughly) Lua form, with numbers replaced by the
-- symbolic constants used in parseit, where possible.
-- See the Assignment description for the AST Specification.
function printAST_parseit(...)
    if select("#", ...) ~= 1 then
        error("printAST_parseit: must pass exactly 1 argument")
    end
    local x = select(1, ...)  -- Get argument (which may be nil)

    if type(x) == "nil" then
        io.write("nil")
    elseif type(x) == "number" then
        if symbolNames[x] then
            io.write(symbolNames[x])
        else
            io.write(x)
        end
    elseif type(x) == "string" then
        io.write('"'..x..'"')
    elseif type(x) == "boolean" then
        if x then
            io.write("true")
        else
            io.write("false")
        end
    elseif type(x) ~= "table" then
        io.write('<'..type(x)..'>')
    else  -- type is "table"
        io.write("{ ")
        local first = true  -- First iteration of loop?
        local maxk = 0
        for k, v in ipairs(x) do
            if first then
                first = false
            else
                io.write(", ")
            end
            maxk = k
            printAST_parseit(v)
        end
        for k, v in pairs(x) do
            if type(k) ~= "number"
              or k ~= math.floor(k)
              or (k < 1 and k > maxk) then
                if first then
                    first = false
                else
                    io.write(", ")
                end
                io.write("[")
                printAST_parseit(k)
                io.write("]=")
                printAST_parseit(v)
            end
        end
        io.write(" }")
    end
end


-- astEq
-- Checks equality of two ASTs, represented as in the Assignment 4
-- description. Returns true if equal, false otherwise.
function astEq(ast1, ast2)
    if type(ast1) ~= type(ast2) then
        return false
    end

    if type(ast1) ~= "table" then
        return ast1 == ast2
    end

    if #ast1 ~= #ast2 then
        return false
    end

    for k = 1, #ast1 do  -- ipairs is problematic
        if not astEq(ast1[k], ast2[k]) then
            return false
        end
    end
    return true
end


-- bool2Str
-- Given boolean, return string representing it: "true" or "false".
function bool2Str(b)
    if b then
        return "true"
    else
        return "false"
    end
end


-- checkParse
-- Given tester object, input string ("program"), expected output values
-- from parser (good, AST), and string giving the name of the test. Do
-- test & print result. If test fails and EXIT_ON_FIRST_FAILURE is true,
-- then print detailed results and exit program.
function checkParse(t, prog,
                    expectedGood, expectedDone, expectedAST,
                    testName)
    local actualGood, actualDone, actualAST = parseit.parse(prog)
    local sameGood = (expectedGood == actualGood)
    local sameDone = (expectedDone == actualDone)
    local sameAST = true
    if sameGood and expectedGood and sameDone and expectedDone then
        sameAST = astEq(expectedAST, actualAST)
    end
    local success = sameGood and sameDone and sameAST
    t:test(success, testName)

    if success or not EXIT_ON_FIRST_FAILURE then
        return
    end

    io.write("\n")
    io.write("Input for the last test above:\n")
    io.write('"'..prog..'"\n')
    io.write("\n")
    io.write("Expected parser 'good' return value: ")
    io.write(bool2Str(expectedGood).."\n")
    io.write("Actual parser 'good' return value: ")
    io.write(bool2Str(actualGood).."\n")
    io.write("Expected parser 'done' return value: ")
    io.write(bool2Str(expectedDone).."\n")
    io.write("Actual parser 'done' return value: ")
    io.write(bool2Str(actualDone).."\n")
    if not sameAST then
        io.write("\n")
        io.write("Expected AST:\n")
        printAST_parseit(expectedAST)
        io.write("\n")
        io.write("\n")
        io.write("Returned AST:\n")
        printAST_parseit(actualAST)
        io.write("\n")
    end
    io.write("\n")
    failExit()
end


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_simple(t)
    io.write("Test Suite: simple cases\n")

    checkParse(t, "", true, true, {STMTxLIST},
      "Empty program")
    checkParse(t, "end", true, false, nil,
      "Bad program: Keyword only #1")
    checkParse(t, "elif", true, false, nil,
      "Bad program: Keyword only #2")
    checkParse(t, "else", true, false, nil,
      "Bad program: Keyword only #3")
    checkParse(t, "bc", false, true, nil,
      "Bad program: Identifier only")
    checkParse(t, "123", true, false, nil,
      "Bad program: NumericLiteral only")
    checkParse(t, "'xyz'", true, false, nil,
      "Bad program: StringLiteral only #1")
    checkParse(t, '"xyz"', true, false, nil,
      "Bad program: StringLiteral only #2")
    checkParse(t, "<=", true, false, nil,
      "Bad program: Operator only")
    checkParse(t, "{", true, false, nil,
      "Bad program: Punctuation only")
    checkParse(t, "\a", true, false, nil,
      "Bad program: Malformed only #1")
    checkParse(t, "'", true, false, nil,
      "bad program: malformed only #2")
end


function test_print_stmt_no_expr(t)
    io.write("Test Suite: print statements - no expressions\n")

    checkParse(t, "print()", true, true,
      {STMTxLIST,{PRINTxSTMT}},
      "Print statement: no args")
    checkParse(t, "print()print()print()", true, true,
      {STMTxLIST,{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}},
      "3 print statements")
    checkParse(t, "print('abc')", true, true,
      {STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"'abc'"}}},
      "Print statement: StringLiteral")
    checkParse(t, "print('a','b','c',\"d\",'e')", true, true,
      {STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"'a'"},{STRLITxOUT,"'b'"},
        {STRLITxOUT,"'c'"},{STRLITxOUT,'"d"'},{STRLITxOUT,"'e'"}}},
      "Print statement: many StringLiterals")

    checkParse(t, "print", false, true, nil,
      "Bad print statement: no parens, no arguments")
    checkParse(t, "print 'a'", false, false, nil,
      "Bad print statement: no parens")
    checkParse(t, "print'a')", false, false, nil,
      "Bad print statement: no opening paren")
    checkParse(t, "print('a'", false, true, nil,
      "Bad print statement: no closing paren")
    checkParse(t, "print(end)", false, false, nil,
      "Bad print statement: keyword #1")
    checkParse(t, "print(print)", false, false, nil,
      "Bad print statement: keyword #2")
    checkParse(t, "print('a' 'b')", false, false, nil,
      "Bad print statement: missing comma")
    checkParse(t, "print(,'a')", false, false, nil,
      "Bad print statement: comma without preceding argument")
    checkParse(t, "print('a',)", false, false, nil,
      "Bad print statement: comma without following argument")
    checkParse(t, "print(,)", false, false, nil,
      "Bad print statement: comma alone")
    checkParse(t, "print('a',,'b')", false, false, nil,
      "Bad print statement: extra comma")
    checkParse(t, "print('a')end", true, false, nil,
      "Bad print statement: print followed by end")
    checkParse(t, "'a'", true, false, nil,
      "Bad program: (no print) string only")
end


function test_function_call_stmt(t)
    io.write("Test Suite: Function call statements\n")

    checkParse(t, "ff()", true, true,
      {STMTxLIST,{FUNCxCALL,"ff"}},
      "Function call statement #1")
    checkParse(t, "fffffffffffffffffffffffffffffffff()", true, true,
      {STMTxLIST,{FUNCxCALL,"fffffffffffffffffffffffffffffffff"}},
      "Function call statement #2")
    checkParse(t, "ff()gg()", true, true,
      {STMTxLIST,{FUNCxCALL,"ff"},{FUNCxCALL,"gg"}},
      "Two function call statements")
    checkParse(t, "ff", false, true, nil,
      "Bad function call statement: no parens")
    checkParse(t, "ff)", false, false, nil,
      "Bad function call statement: no left paren")
    checkParse(t, "ff(", false, true, nil,
      "Bad function call statement: no right paren")
    checkParse(t, "ff(()", false, false, nil,
      "Bad function call statement: extra left paren")
    checkParse(t, "ff())", true, false, nil,
      "Bad function call statement: extra right paren")
    checkParse(t, "ff()()", true, false, nil,
      "Bad function call statement: extra pair of parens")
    checkParse(t, "ff gg()", false, false, nil,
      "Bad function call statement: extra name")
    checkParse(t, "(ff)()", true, false, nil,
      "Bad function call statement: parentheses around name")
    checkParse(t, "ff(a)", false, false, nil,
      "Bad function call statement: argument - Idenitfier")
    checkParse(t, "ff('abc')", false, false, nil,
      "Bad function call statement: argument - StringLiteral")
    checkParse(t, "ff(2)", false, false, nil,
      "Bad function call statement: argument - NumericLiteral")
end


function test_func_def_no_expr(t)
    io.write("Test Suite: function definitions - no expressions\n")

    checkParse(t, "func s() end", true, true,
      {STMTxLIST,{FUNCxDEF,"s",{STMTxLIST}}},
      "Function definition: empty body")
    checkParse(t, "func end", false, false, nil,
      "Bad function definition: missing name")
    checkParse(t, "func &s end", false, false, nil,
      "Bad function definition: ampersand before name")
    checkParse(t, "func s end", false, false, nil,
      "Bad function definition: no parens")
    checkParse(t, "func s() end end", true, false, nil,
      "Bad function definition: extra end")
    checkParse(t, "func (s)() end", false, false, nil,
      "Bad function definition: name in parentheses")
    checkParse(t, "func s() print('abc') end", true, true,
      {STMTxLIST,{FUNCxDEF,"s",{STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"'abc'"}}}}},
      "Function definition: 1-statement body #1")
    checkParse(t, "func s() print('x') end", true, true, {STMTxLIST,{FUNCxDEF,"s",{STMTxLIST,{PRINTxSTMT,
        {STRLITxOUT,"'x'"}}}}},
      "Function definition: 1-statment body #2")
    checkParse(t, "func s() print() print() end", true, true,
      {STMTxLIST,{FUNCxDEF,"s",{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT}}}},
      "Function definition: 2-statment body")
    checkParse(t, "func sss() print() print() print() end", true, true,
      {STMTxLIST,{FUNCxDEF,"sss",{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT}}}},
      "Function definition: longer body")
    checkParse(t, "func s() func t() func u() print() end end func v()"
      .."print() end end", true, true,
      {STMTxLIST,{FUNCxDEF,"s",{STMTxLIST,{FUNCxDEF,"t",{STMTxLIST,
        {FUNCxDEF,"u",{STMTxLIST,{PRINTxSTMT}}}}},{FUNCxDEF,
        "v",{STMTxLIST,{PRINTxSTMT}}}}}},
      "Function definition: nested function definitions")
end


function test_while_stmt_simple_expr(t)
    io.write("Test Suite: while statements - simple expressions only\n")

    checkParse(t, "while 1 print()end", true, true,
      {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{PRINTxSTMT}}}},
      "While statement: simple")
    checkParse(t, "while 2 print()print()print()print()"
     .."print()print()print()print()print()print() end", true,
     true,
      {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"2"},{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}}}},
      "While statement: longer statement list")
    checkParse(t, "while 3 end", true, true,
      {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"3"},{STMTxLIST}}},
      "While statement: empty statement list")
    checkParse(t, "while 1 while 2 while 3 while 4 while 5 while 6 "
      .."while 7 print() end end end end end end end", true, true,
      {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{WHILExSTMT,
        {NUMLITxVAL,"2"},{STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"3"},
        {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"4"},{STMTxLIST,{WHILExSTMT,
        {NUMLITxVAL,"5"},{STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"6"},
        {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"7"},{STMTxLIST,
        {PRINTxSTMT}}}}}}}}}}}}}}}},
      "While statement: nested")

    checkParse(t, "while print() end", false, false, nil,
      "Bad while statement: no expr")
    checkParse(t, "while 1 print()", false, true, nil,
      "Bad while statement: no end")
    checkParse(t, "while 1 print() else print() end ",
      false, false, nil,
      "Bad while statement: has else")
    checkParse(t, "while 1 print() end end", true, false, nil,
      "Bad while statement: followed by end")
end


function test_if_stmt_simple_expr(t)
    io.write("Test Suite: if statements - simple expressions only\n")

    checkParse(t, "if 1 print() end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"1"},{STMTxLIST,
      {PRINTxSTMT}}}},
      "If statement: simple")
    checkParse(t, "if 2 end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"2"},{STMTxLIST}}},
      "If statement: empty statement list")
    checkParse(t, "if 3 print() else print() print() end", true,
      true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"3"},{STMTxLIST,{PRINTxSTMT}},
      {STMTxLIST,{PRINTxSTMT},{PRINTxSTMT}}}},
      "If statement: else")
    checkParse(t, "if 4 print() elif 5 print() print() else "
      .."print() print() print() end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"4"},{STMTxLIST,{PRINTxSTMT}},
        {NUMLITxVAL,"5"},{STMTxLIST,{PRINTxSTMT},{PRINTxSTMT}},
        {STMTxLIST,{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}}}},
      "If statement: elif, else")
    checkParse(t, "if a print() elif b print() print() elif c "
      .."print() print() print() elif d print() print()"
      .."print() print() elif e print() print() print() print()"
      .."print() else print() print() print() print() print()"
      .."print() end", true, true,
      {STMTxLIST,{IFxSTMT,{SIMPLExVAR,"a"},{STMTxLIST,{PRINTxSTMT}},
        {SIMPLExVAR,"b"},{STMTxLIST,{PRINTxSTMT},{PRINTxSTMT}},
        {SIMPLExVAR,"c"},{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT}},
        {SIMPLExVAR,"d"},{STMTxLIST,{PRINTxSTMT},{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT}},
        {SIMPLExVAR,"e"},{STMTxLIST,{PRINTxSTMT},{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}},{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},
        {PRINTxSTMT}}}},
      "If statement: multiple elif, else")
    checkParse(t, "if 1 print() elif 2 print() print() elif 3 "
      .."print() print() print() elif 4 print() print()"
      .."print() print() elif 5 print() print() print() print() "
      .."print() end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{PRINTxSTMT}},
        {NUMLITxVAL,"2"},{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT}},{NUMLITxVAL,"3"},{STMTxLIST,{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT}},{NUMLITxVAL,"4"},{STMTxLIST,
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}},
        {NUMLITxVAL,"5"},{STMTxLIST,{PRINTxSTMT},{PRINTxSTMT},
        {PRINTxSTMT},{PRINTxSTMT},{PRINTxSTMT}}}},
      "If statement: multiple elif, no else")
    checkParse(t, "if 1 elif 2 elif 3 elif 4 elif 5 else end",
      true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"1"},{STMTxLIST},{NUMLITxVAL,"2"},
        {STMTxLIST},{NUMLITxVAL,"3"},{STMTxLIST},{NUMLITxVAL,"4"},
        {STMTxLIST},{NUMLITxVAL,"5"},{STMTxLIST},{STMTxLIST}}},
      "If statement: multiple elif, else, empty statement lists")
    checkParse(t, "if 1 if 2 print() else print() end elif 3 if 4 "
      .."print() else print() end else if 5 print() else print() "
      .."end end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{IFxSTMT,
        {NUMLITxVAL,"2"},{STMTxLIST,{PRINTxSTMT}},{STMTxLIST,
        {PRINTxSTMT}}}},{NUMLITxVAL,"3"},{STMTxLIST,{IFxSTMT,
        {NUMLITxVAL,"4"},{STMTxLIST,{PRINTxSTMT}},{STMTxLIST,
        {PRINTxSTMT}}}},{STMTxLIST,{IFxSTMT,{NUMLITxVAL,"5"},
        {STMTxLIST,{PRINTxSTMT}},{STMTxLIST,{PRINTxSTMT}}}}}},
      "If statement: nested #1")
    checkParse(t, "if 1 if 2 if 3 if 4 if 5 if 6 if 7 print() end end "
      .."end end end end end", true, true,
      {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{IFxSTMT,
        {NUMLITxVAL,"2"},{STMTxLIST,{IFxSTMT,{NUMLITxVAL,"3"},
        {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"4"},{STMTxLIST,{IFxSTMT,
        {NUMLITxVAL,"5"},{STMTxLIST,{IFxSTMT,{NUMLITxVAL,"6"},
        {STMTxLIST,{IFxSTMT,{NUMLITxVAL,"7"},{STMTxLIST,
        {PRINTxSTMT}}}}}}}}}}}}}}}},
      "If statement: nested #2")
    checkParse(t, "while 1 if 2 while 3 end elif 4 while 5 if 6 end "
      .."end elif 7 while 8 end else while 9 end end end", true, true,
      {STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"1"},{STMTxLIST,{IFxSTMT,
        {NUMLITxVAL,"2"},{STMTxLIST,{WHILExSTMT,{NUMLITxVAL,"3"},
        {STMTxLIST}}},{NUMLITxVAL,"4"},{STMTxLIST,{WHILExSTMT,
        {NUMLITxVAL,"5"},{STMTxLIST,{IFxSTMT,{NUMLITxVAL,"6"},
        {STMTxLIST}}}}},{NUMLITxVAL,"7"},{STMTxLIST,{WHILExSTMT,
        {NUMLITxVAL,"8"},{STMTxLIST}}},{STMTxLIST,{WHILExSTMT,
        {NUMLITxVAL,"9"},{STMTxLIST}}}}}}},
      "While statement: nested while & if")

    checkParse(t, "if print() end", false, false, nil,
      "Bad if statement: no expr")
    checkParse(t, "if a print()", false, true, nil,
      "Bad if statement: no end")
    checkParse(t, "if a b print() end", false, false, nil,
      "Bad if statement: 2 expressions")
    checkParse(t, "if a print() else print() elif b print() end",
      false, false, nil,
      "Bad if statement: else before elif")
    checkParse(t, "if a print() end end", true, false, nil,
      "Bad if statement: followed by end")
end


function test_assn_stmt_simple_expr(t)
    io.write("Test Suite: assignment statements - simple expressions\n")

    checkParse(t, "abc=123", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"abc"},{NUMLITxVAL,"123"}}},
      "Assignment statement: NumericLiteral")
    checkParse(t, "abc=xyz", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR, "abc"},{SIMPLExVAR,"xyz"}}},
      "Assignment statement: identifier")
    checkParse(t, "abc[1]=xyz", true, true,
      {STMTxLIST,{ASSNxSTMT,{ARRAYxVAR,"abc",{NUMLITxVAL,"1"}},
        {SIMPLExVAR,"xyz"}}},
      "Assignment statement: array ref = ...")
    checkParse(t, "abc=true", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR, "abc"},{BOOLLITxVAL,"true"}}},
      "Assignment statement: boolean literal Keyword: true")
    checkParse(t, "abc=false", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR, "abc"},{BOOLLITxVAL,"false"}}},
      "Assignment statement: boolean literal Keyword: false")
    checkParse(t, "=123", true, false, nil,
      "Bad assignment statement: missing LHS")
    checkParse(t, "123=123", true, false, nil,
      "Bad assignment statement: LHS is NumericLiteral")
    checkParse(t, "end=123", true, false, nil,
      "Bad assignment statement: LHS is Keyword")
    checkParse(t, "abc 123", false, false, nil,
      "Bad assignment statement: missing assignment op")
    checkParse(t, "abc == 123", false, false, nil,
      "Bad assignment statement: assignment op replaced by equality")
    checkParse(t, "abc =", false, true, nil,
      "Bad assignment statement: RHS is empty")
    checkParse(t, "abc=end", false, false, nil,
      "Bad assignment statement: RHS is Keyword")
    checkParse(t, "abc=1 2", true, false, nil,
      "Bad assignment statement: RHS is two NumericLiterals")
    checkParse(t, "abc=1 end", true, false, nil,
      "Bad assignment statement: followed by end")

    checkParse(t, "x=true", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{BOOLLITxVAL,"true"}}},
      "Simple expression: true")
    checkParse(t, "x=false", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{BOOLLITxVAL,"false"}}},
      "Simple expression: true")
    checkParse(t, "x=foo()", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{FUNCxCALL,"foo"}}},
      "Simple expression: call")
    checkParse(t, "x=()", false, false, nil,
      "Bad expression: call without name")
    checkParse(t, "x=1and 2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: and")
    checkParse(t, "x=1 or 2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: or")
    checkParse(t, "x=1 + 2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: binary + (numbers with space)")
    checkParse(t, "x=1+2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: binary + (numbers without space)")
    checkParse(t, "x=a+2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {SIMPLExVAR,"a"},{NUMLITxVAL,"2"}}}},
      "Simple expression: binary + (var+number)")
    checkParse(t, "x=1+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {NUMLITxVAL,"1"},{SIMPLExVAR,"b"}}}},
      "Simple expression: binary + (number+var)")
    checkParse(t, "x=a+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}},
      "Simple expression: binary + (vars)")
    checkParse(t, "x=1+", false, true, nil,
      "Bad expression: end with +")
    checkParse(t, "x=1 - 2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: binary - (numbers with space)")
    checkParse(t, "x=1-2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: binary - (numbers without space)")
    checkParse(t, "x=1-", false, true, nil,
      "Bad expression: end with -")
    checkParse(t, "x=1*2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: * (numbers)")
    checkParse(t, "x=a*2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},
        {SIMPLExVAR,"a"},{NUMLITxVAL,"2"}}}},
      "Simple expression: * (var*number)")
    checkParse(t, "x=1*b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},
        {NUMLITxVAL,"1"},{SIMPLExVAR,"b"}}}},
      "Simple expression: * (number*var)")
    checkParse(t, "x=a*b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}},
      "Simple expression: * (vars)")
    checkParse(t, "x=1*", false, true, nil,
      "Bad expression: end with *")
    checkParse(t, "x=1/2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: /")
    checkParse(t, "x=1/", false, true, nil,
      "Bad expression: end with /")
    checkParse(t, "x=1%2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: % #1")
    checkParse(t, "x=1%true", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},
        {NUMLITxVAL,"1"},{BOOLLITxVAL,"true"}}}},
      "Simple expression: % #2")
    checkParse(t, "x=1%false", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},
        {NUMLITxVAL,"1"},{BOOLLITxVAL,"false"}}}},
      "Simple expression: % #3")
    checkParse(t, "x=1%", false, true, nil,
      "Bad expression: end with %")
    checkParse(t, "x=1==2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: == (numbers)")
    checkParse(t, "x=a==2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},
        {SIMPLExVAR,"a"},{NUMLITxVAL,"2"}}}},
      "Simple expression: == (var==number)")
    checkParse(t, "x=1==b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},
        {NUMLITxVAL,"1"},{SIMPLExVAR,"b"}}}},
      "Simple expression: == (number==var)")
    checkParse(t, "x=a==b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}},
      "Simple expression: == (vars)")
    checkParse(t, "x=1==", false, true, nil,
      "Bad expression: end with ==")
    checkParse(t, "x=1!=2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"!="},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: !=")
    checkParse(t, "x=1!=", false, true, nil,
      "Bad expression: end with !=")
    checkParse(t, "x=1<2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: <")
    checkParse(t, "x=1<", false, true, nil,
      "Bad expression: end with <")
    checkParse(t, "x=1<=2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<="},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: <=")
    checkParse(t, "x=1<=", false, true, nil,
      "Bad expression: end with <=")
    checkParse(t, "x=1>2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: >")
    checkParse(t, "x=1>", false, true, nil,
      "Bad expression: end with >")
    checkParse(t, "x=1>=2", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},
        {NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}}},
      "Simple expression: >=")
    checkParse(t, "x=+a", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{SIMPLExVAR,
        "a"}}}},
      "Simple expression: unary +")
    checkParse(t, "x=-a", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"-"},{SIMPLExVAR,
        "a"}}}},
      "Simple expression: unary -")
    checkParse(t, "x=1>=", false, true, nil,
      "Bad expression: end with >=")
    checkParse(t, "x=(1)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{NUMLITxVAL,"1"}}},
      "Simple expression: parens (number)")
    checkParse(t, "x=(a)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{SIMPLExVAR,"a"}}},
      "Simple expression: parens (var)")
    checkParse(t, "x=a[1]", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{ARRAYxVAR,"a",
        {NUMLITxVAL,"1"}}}},
      "Simple expression: array ref")
    checkParse(t, "x=(1", false, true, nil,
      "Bad expression: no closing paren")
    checkParse(t, "x=()", false, false, nil,
      "Bad expression: empty parens")
    checkParse(t, "x=a[1", false, true, nil,
      "Bad expression: no closing bracket")
    checkParse(t, "x=a 1]", true, false, nil,
      "Bad expression: no opening bracket")
    checkParse(t, "x=a[]", false, false, nil,
      "Bad expression: empty brackets")
    checkParse(t, "x=(x)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{SIMPLExVAR,"x"}}},
      "Simple expression: var in parens on RHS")
    checkParse(t, "(x)=x", true, false, nil,
      "Bad expression: var in parens on LHS")
    checkParse(t, "x[1]=(x[1])", true, true,
      {STMTxLIST,{ASSNxSTMT,{ARRAYxVAR,"x",{NUMLITxVAL,"1"}},
        {ARRAYxVAR,"x",{NUMLITxVAL,"1"}}}},
      "Simple expression: array ref in parens on RHS")
    checkParse(t, "(x[1])=x[1]", true, false, nil,
      "Bad expression: array ref in parens on LHS")

    checkParse(t, "x=call call f", false, false, nil,
      "Bad expression: consecutive call keywords")
    checkParse(t, "x=3()", true, false, nil,
      "Bad expression: call number")
    checkParse(t, "x=true()", true, false, nil,
      "Bad expression: call boolean")
    checkParse(t, "x=(x)()", true, false, nil,
      "Bad expression: call with parentheses around ID")
end


function test_return_stmt(t)
    io.write("Test Suite: return statements\n")

    checkParse(t, "return x", true, true,
      {STMTxLIST,{RETURNxSTMT,{SIMPLExVAR,"x"}}},
      "return statement: variable")
    checkParse(t, "return -34", true, true,
      {STMTxLIST,{RETURNxSTMT,{{UNxOP,"-"},{NUMLITxVAL,"34"}}}},
      "return statement: number")
    checkParse(t, "return", false, true, nil,
      "return statement: no argument")
    checkParse(t, "return(x)", true, true,
      {STMTxLIST,{RETURNxSTMT,{SIMPLExVAR,"x"}}},
      "return statement: variable in parentheses")
    checkParse(t, "return(3+true<=4*(x-y))", true, true,
      {STMTxLIST,{RETURNxSTMT,{{BINxOP,"<="},{{BINxOP,"+"},{NUMLITxVAL,
        "3"},{BOOLLITxVAL,"true"}},{{BINxOP,"*"},{NUMLITxVAL,"4"},
        {{BINxOP,"-"},{SIMPLExVAR,"x"},{SIMPLExVAR,"y"}}}}}},
      "return statement: fancier expression")
end


function test_print_stmt_with_expr(t)
    io.write("Test Suite: print statements - with expressions\n")

    checkParse(t, "print(x)", true, true,
      {STMTxLIST,{PRINTxSTMT,{SIMPLExVAR,"x"}}},
      "print statement: variable")
    checkParse(t, "print(char(65))", true, true,
      {STMTxLIST,{PRINTxSTMT,{CHARxCALL,{NUMLITxVAL,"65"}}}},
      "print statement: char call")
    checkParse(t, "print(char(1),char(2),char(3))", true, true,
      {STMTxLIST,{PRINTxSTMT,{CHARxCALL,{NUMLITxVAL,"1"}},{CHARxCALL,
        {NUMLITxVAL,"2"}},{CHARxCALL,{NUMLITxVAL,"3"}}}},
      "print statement: multiple char calls")
    checkParse(t, "print(\"a b\\\"\", char(1+2), a*4)", true, true,
      {STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"\"a b\\\"\""},{CHARxCALL,
        {{BINxOP,"+"},{NUMLITxVAL,"1"},{NUMLITxVAL,"2"}}},{{BINxOP,"*"},
        {SIMPLExVAR,"a"},{NUMLITxVAL,"4"}}}},
      "print statement: string literal, char call, expression #1")
    checkParse(t, "print(char(1-2), 'a b\\\'\"', 4/a)", true, true,
      {STMTxLIST,{PRINTxSTMT,{CHARxCALL,{{BINxOP,"-"},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}}},{STRLITxOUT,"'a b\\\'\"'"},{{BINxOP,"/"},
        {NUMLITxVAL,"4"},{SIMPLExVAR,"a"}}}},
      "print statement: string literal, char call, expression #2")
    checkParse(t, "print(a+xyz_3[b*(c==d-f)]%g<=h)", true, true,
      {STMTxLIST,{PRINTxSTMT,{{BINxOP,"<="},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{ARRAYxVAR,"xyz_3",{{BINxOP,"*"},{SIMPLExVAR,
        "b"},{{BINxOP,"=="},{SIMPLExVAR,"c"},{{BINxOP,"-"},{SIMPLExVAR,
        "d"},{SIMPLExVAR,"f"}}}}},{SIMPLExVAR,"g"}}},{SIMPLExVAR,
        "h"}}}},
      "print statement: complex expression")
    checkParse(t, "print(1) end", true, false, nil,
      "bad print statement: print 1 followed by end")
end


function test_func_def_with_expr(t)
    io.write("Test Suite: function definitions - with expressions\n")

    checkParse(t, "func q() print(abc+3) end", true, true,
      {STMTxLIST,{FUNCxDEF,"q",{STMTxLIST,{PRINTxSTMT,{{BINxOP,"+"},
        {SIMPLExVAR,"abc"},{NUMLITxVAL,"3"}}}}}},
      "func definition: with print expr")
    checkParse(t, "func qq() print(a+x[b*(c==d-f)]%g<=h) end", true, true,
      {STMTxLIST,{FUNCxDEF,"qq",{STMTxLIST,{PRINTxSTMT,{{BINxOP,"<="},
        {{BINxOP,"+"},{SIMPLExVAR,"a"},{{BINxOP,"%"},{ARRAYxVAR,"x",
        {{BINxOP,"*"},{SIMPLExVAR,"b"},{{BINxOP,"=="},{SIMPLExVAR,"c"},
        {{BINxOP,"-"},{SIMPLExVAR,"d"},{SIMPLExVAR,"f"}}}}},{SIMPLExVAR,
        "g"}}},{SIMPLExVAR,"h"}}}}}},
      "function definition: complex expression")
end


function test_expr_prec_assoc(t)
    io.write("Test Suite: expressions - precedence & associativity\n")

    checkParse(t, "x=1and 2and 3and 4and 5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{{BINxOP,
        "and"},{{BINxOP, "and"},{{BINxOP,"and"},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator 'and' is left-associative")
    checkParse(t, "x=1 or 2 or 3 or 4 or 5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{{BINxOP,
        "or"},{{BINxOP, "or"},{{BINxOP,"or"},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator 'or' is left-associative")
    checkParse(t, "x=1+2+3+4+5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "+"},{{BINxOP, "+"},{{BINxOP,"+"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Binary operator + is left-associative")
    checkParse(t, "x=1-2-3-4-5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "-"},{{BINxOP, "-"},{{BINxOP,"-"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Binary operator - is left-associative")
    checkParse(t, "x=1*2*3*4*5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "*"},{{BINxOP, "*"},{{BINxOP,"*"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Operator * is left-associative")
    checkParse(t, "x=1/2/3/4/5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{BINxOP,
        "/"},{{BINxOP, "/"},{{BINxOP,"/"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Operator / is left-associative")
    checkParse(t, "x=1%2%3%4%5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        "%"},{{BINxOP, "%"},{{BINxOP,"%"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Operator % is left-associative")
    checkParse(t, "x=1==2==3==4==5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "=="},{{BINxOP, "=="},{{BINxOP,"=="},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator == is left-associative")
    checkParse(t, "x=1!=2!=3!=4!=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"!="},{{BINxOP,
        "!="},{{BINxOP, "!="},{{BINxOP,"!="},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator != is left-associative")
    checkParse(t, "x=1<2<3<4<5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},{{BINxOP,
        "<"},{{BINxOP, "<"},{{BINxOP,"<"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Operator < is left-associative")
    checkParse(t, "x=1<=2<=3<=4<=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<="},{{BINxOP,
        "<="},{{BINxOP, "<="},{{BINxOP,"<="},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator <= is left-associative")
    checkParse(t, "x=1>2>3>4>5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        ">"},{{BINxOP, ">"},{{BINxOP,">"},{NUMLITxVAL,"1"},{NUMLITxVAL,
        "2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}}}},
      "Operator > is left-associative")
    checkParse(t, "x=1>=2>=3>=4>=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},{{BINxOP,
        ">="},{{BINxOP, ">="},{{BINxOP,">="},{NUMLITxVAL,"1"},
        {NUMLITxVAL,"2"}},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}},
        {NUMLITxVAL,"5"}}}},
      "Operator >= is left-associative")

    checkParse(t, "x=not not not not a", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"not"},{{UNxOP,"not"},
        {{UNxOP,"not"},{{UNxOP,"not"},{SIMPLExVAR,"a"}}}}}}},
      "Operator 'not' is right-associative")
    checkParse(t, "x=++++a", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{{UNxOP,"+"},
        {{UNxOP,"+"},{{UNxOP,"+"},{SIMPLExVAR,"a"}}}}}}},
      "Unary operator + is right-associative")
    checkParse(t, "x=----a", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"-"},{{UNxOP,"-"},
        {{UNxOP,"-"},{{UNxOP,"-"},{SIMPLExVAR,"a"}}}}}}},
      "Unary operator - is right-associative")

    checkParse(t, "x=a and b or c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{{BINxOP,
        "and"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: and, or")
    checkParse(t, "x=a and b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"=="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, ==")
    checkParse(t, "x=a and b!=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"!="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, !=")
    checkParse(t, "x=a and b<c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"<"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, <")
    checkParse(t, "x=a and b<=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"<="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, <=")
    checkParse(t, "x=a and b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,">"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, >")
    checkParse(t, "x=a and b>=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,">="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, >=")
    checkParse(t, "x=a and b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"+"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, binary +")
    checkParse(t, "x=a and b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"-"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, binary -")
    checkParse(t, "x=a and b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, *")
    checkParse(t, "x=a and b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, /")
    checkParse(t, "x=a and b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: and, %")

    checkParse(t, "x=a or b and c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{{BINxOP,
        "or"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: or, and")
    checkParse(t, "x=a or b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"=="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, ==")
    checkParse(t, "x=a or b!=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"!="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check:  or , !=")
    checkParse(t, "x=a or b<c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"<"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, <")
    checkParse(t, "x=a or b<=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"<="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, <=")
    checkParse(t, "x=a or b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,">"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, >")
    checkParse(t, "x=a or b>=c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,">="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, >=")
    checkParse(t, "x=a or b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"+"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, binary +")
    checkParse(t, "x=a or b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"-"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, binary -")
    checkParse(t, "x=a or b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, *")
    checkParse(t, "x=a or b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, /")
    checkParse(t, "x=a or b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: or, %")

    checkParse(t, "x=a==b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "=="},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: ==, >")
    checkParse(t, "x=a==b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"+"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: ==, binary +")
    checkParse(t, "x=a==b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"-"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: ==, binary -")
    checkParse(t, "x=a==b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: ==, *")
    checkParse(t, "x=a==b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: ==, /")
    checkParse(t, "x=a==b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: ==, %")

    checkParse(t, "x=a>b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        ">"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: >, ==")
    checkParse(t, "x=a>b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{SIMPLExVAR,
        "a"},{{BINxOP,"+"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: >, binary +")
    checkParse(t, "x=a>b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{SIMPLExVAR,
        "a"},{{BINxOP,"-"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: >, binary -")
    checkParse(t, "x=a>b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: >, *")
    checkParse(t, "x=a>b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: >, /")
    checkParse(t, "x=a>b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: >, %")

    checkParse(t, "x=a+b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "+"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary +, ==")
    checkParse(t, "x=a+b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "+"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary +, >")
    checkParse(t, "x=a+b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "+"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary +, binary -")
    checkParse(t, "x=a+b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary +, *")
    checkParse(t, "x=a+b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary +, /")
    checkParse(t, "x=a+b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary +, %")

    checkParse(t, "x=a-b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "-"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary -, ==")
    checkParse(t, "x=a-b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "-"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary -, >")
    checkParse(t, "x=a-b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "-"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: binary -, binary +")
    checkParse(t, "x=a-b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{SIMPLExVAR,
        "a"},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary -, *")
    checkParse(t, "x=a-b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{SIMPLExVAR,
        "a"},{{BINxOP,"/"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary -, /")
    checkParse(t, "x=a-b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{SIMPLExVAR,
        "a"},{{BINxOP,"%"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence check: binary -, %")

    checkParse(t, "x=a*b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, ==")
    checkParse(t, "x=a*b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, >")
    checkParse(t, "x=a*b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, binary +")
    checkParse(t, "x=a*b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, binary -")
    checkParse(t, "x=a*b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, /")
    checkParse(t, "x=a*b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        "*"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: *, %")

    checkParse(t, "x=a/b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, ==")
    checkParse(t, "x=a/b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, >")
    checkParse(t, "x=a/b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, binary +")
    checkParse(t, "x=a/b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, binary -")
    checkParse(t, "x=a/b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, *")
    checkParse(t, "x=a/b%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        "/"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: /, %")

    checkParse(t, "x=a%b==c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, ==")
    checkParse(t, "x=a%b>c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, >")
    checkParse(t, "x=a%b+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, binary +")
    checkParse(t, "x=a%b-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, binary -")
    checkParse(t, "x=a%b*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, *")
    checkParse(t, "x=a%b/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{BINxOP,
        "%"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: %, /")

    checkParse(t, "x=not a and b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, and")
    checkParse(t, "x=not a or b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, or")
    checkParse(t, "x=not a==b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, ==")
    checkParse(t, "x=not a!=b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"!="},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, !=")
    checkParse(t, "x=not a<b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, <")
    checkParse(t, "x=not a<=b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<="},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, <=")
    checkParse(t, "x=not a>b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, >")
    checkParse(t, "x=not a>=b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, >=")
    checkParse(t, "x=not a+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, binary +")
    checkParse(t, "x=not a-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, binary -")
    checkParse(t, "x=not a*b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, *")
    checkParse(t, "x=not a/b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, /")
    checkParse(t, "x=not a%b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{UNxOP,
        "not"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: not, %")
    checkParse(t, "x=a!=+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"!="},{SIMPLExVAR,
        "a"},{{UNxOP,"+"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: !=, unary +")
    checkParse(t, "x=-a<c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},{{UNxOP,
        "-"},{SIMPLExVAR,"a"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: unary -, <")
    checkParse(t, "x=a++b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{UNxOP,"+"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: binary +, unary +")
    checkParse(t, "x=a+-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
        "a"},{{UNxOP,"-"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: binary +, unary -")
    checkParse(t, "x=+a+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{UNxOP,"+"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: unary +, binary +, *")
    checkParse(t, "x=-a+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{UNxOP,"-"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: unary -, binary +")
    checkParse(t, "x=a-+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{SIMPLExVAR,
        "a"},{{UNxOP,"+"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: binary -, unary +")
    checkParse(t, "x=a--b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{SIMPLExVAR,
        "a"},{{UNxOP,"-"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: binary -, unary -")
    checkParse(t, "x=+a-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{UNxOP,"+"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: unary +, binary -, *")
    checkParse(t, "x=-a-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{UNxOP,"-"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"b"}}}},
      "Precedence check: unary -, binary -")
    checkParse(t, "x=a*-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{SIMPLExVAR,
        "a"},{{UNxOP,"-"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: *, unary -")
    checkParse(t, "x=+a*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{UNxOP,"+"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: unary +, *")
    checkParse(t, "x=a/+b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{SIMPLExVAR,
        "a"},{{UNxOP,"+"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: /, unary +")
    checkParse(t, "x=-a/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{UNxOP,"-"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: unary -, /")
    checkParse(t, "x=a%-b", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{SIMPLExVAR,
        "a"},{{UNxOP,"-"},{SIMPLExVAR,"b"}}}}},
      "Precedence check: %, unary -")
    checkParse(t, "x=+a%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{UNxOP,"+"},
        {SIMPLExVAR,"a"}},{SIMPLExVAR,"c"}}}},
      "Precedence check: unary +, %")

    checkParse(t, "x=1 and (2 and 3 and 4) and 5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"and"},{{BINxOP,
        "and"},{NUMLITxVAL,"1"},{{BINxOP,"and"},{{BINxOP,"and"},
          {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
          {NUMLITxVAL,"5"}}}},
      "Associativity override: and")
    checkParse(t, "x=1 or (2 or 3 or 4) or 5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"or"},{{BINxOP,
        "or"},{NUMLITxVAL,"1"},{{BINxOP,"or"},{{BINxOP,"or"},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: or")
    checkParse(t, "x=1==(2==3==4)==5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{{BINxOP,
        "=="},{NUMLITxVAL,"1"},{{BINxOP,"=="},{{BINxOP,"=="},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: ==")
    checkParse(t, "x=1!=(2!=3!=4)!=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"!="},{{BINxOP,
        "!="},{NUMLITxVAL,"1"},{{BINxOP,"!="},{{BINxOP,"!="},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: !=")
    checkParse(t, "x=1<(2<3<4)<5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},{{BINxOP,
        "<"},{NUMLITxVAL,"1"},{{BINxOP,"<"},{{BINxOP,"<"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: <")
    checkParse(t, "x=1<=(2<=3<=4)<=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<="},{{BINxOP,
        "<="},{NUMLITxVAL,"1"},{{BINxOP,"<="},{{BINxOP,"<="},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: <=")
    checkParse(t, "x=1>(2>3>4)>5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">"},{{BINxOP,
        ">"},{NUMLITxVAL,"1"},{{BINxOP,">"},{{BINxOP,">"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: >")
    checkParse(t, "x=1>=(2>=3>=4)>=5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},{{BINxOP,
        ">="},{NUMLITxVAL,"1"},{{BINxOP,">="},{{BINxOP,">="},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: >=")
    checkParse(t, "x=1+(2+3+4)+5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},
        {{BINxOP,"+"},{NUMLITxVAL,"1"},{{BINxOP,"+"},{{BINxOP,"+"},
        {NUMLITxVAL,"2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},
        {NUMLITxVAL,"5"}}}},
      "Associativity override: binary +")
    checkParse(t, "x=1-(2-3-4)-5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "-"},{NUMLITxVAL,"1"},{{BINxOP,"-"},{{BINxOP,"-"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: binary -")
    checkParse(t, "x=1*(2*3*4)*5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "*"},{NUMLITxVAL,"1"},{{BINxOP,"*"},{{BINxOP,"*"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: *")
    checkParse(t, "x=1/(2/3/4)/5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{BINxOP,
        "/"},{NUMLITxVAL,"1"},{{BINxOP,"/"},{{BINxOP,"/"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: /")
    checkParse(t, "x=1%(2%3%4)%5", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        "%"},{NUMLITxVAL,"1"},{{BINxOP,"%"},{{BINxOP,"%"},{NUMLITxVAL,
        "2"},{NUMLITxVAL,"3"}},{NUMLITxVAL,"4"}}},{NUMLITxVAL,"5"}}}},
      "Associativity override: %")

    checkParse(t, "x=(a==b)+c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{{BINxOP,
        "=="},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: ==, binary +")
    checkParse(t, "x=(a!=b)-c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"-"},{{BINxOP,
        "!="},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: !=, binary -")
    checkParse(t, "x=(a<b)*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "<"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: <, *")
    checkParse(t, "x=(a<=b)/c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{{BINxOP,
        "<="},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: <=, /")
    checkParse(t, "x=(a>b)%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        ">"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: >, %")
    checkParse(t, "x=a+(b>=c)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"+"},{SIMPLExVAR,
       "a"},{{BINxOP,">="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence override: binary +, >=")
    checkParse(t, "x=(a-b)*c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{{BINxOP,
        "-"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: binary -, *")
    checkParse(t, "x=(a+b)%c", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{{BINxOP,
        "+"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,"c"}}}},
      "Precedence override: binary +, %")
    checkParse(t, "x=a*(b==c)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"*"},{SIMPLExVAR,
        "a"},{{BINxOP,"=="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence override: *, ==")
    checkParse(t, "x=a/(b!=c)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"/"},{SIMPLExVAR,
        "a"},{{BINxOP,"!="},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence override: /, !=")
    checkParse(t, "x=a%(b<c)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"%"},{SIMPLExVAR,
        "a"},{{BINxOP,"<"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}}}}},
      "Precedence override: %, <")

    checkParse(t, "x=+(a<=b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{{BINxOP,
        "<="},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary +, <=")
    checkParse(t, "x=-(a>b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"-"},{{BINxOP,">"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary -, >")
    checkParse(t, "x=+(a+b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{{BINxOP,"+"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary +, binary +")
    checkParse(t, "x=-(a-b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"-"},{{BINxOP,"-"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary -, binary -")
    checkParse(t, "x=+(a*b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{{BINxOP,"*"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary +, *")
    checkParse(t, "x=-(a/b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"-"},{{BINxOP,"/"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary -, /")
    checkParse(t, "x=+(a%b)", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{UNxOP,"+"},{{BINxOP,"%"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"b"}}}}},
      "Precedence override: unary +, %")
end


function test_input(t)
    io.write("Test Suite: input\n")

    checkParse(t, "x=input()", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{INPUTxCALL}}},
      "Assignment with input")
    checkParse(t, "x=input(y)", false, false, nil,
      "Assignment with input - nonempty parens")
    checkParse(t, "x=input", false, true, nil,
      "Assignment with input - no parens")
    checkParse(t, "x=input)", false, false, nil,
      "Assignment with input - no left paren")
    checkParse(t, "x=input(", false, true, nil,
      "Assignment with input - no right paren")
    checkParse(t, "input()", true, false, nil,
      "input as statement")
    checkParse(t, "x=input() y=input()", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{INPUTxCALL}},{ASSNxSTMT,
        {SIMPLExVAR,"y"},{INPUTxCALL}}},
      "Multiple assignments with input")
end


function test_array_item(t)
    io.write("Test Suite: array items\n")

    checkParse(t, "a[1] = 2", true, true,
      {STMTxLIST,{ASSNxSTMT,{ARRAYxVAR,"a",{NUMLITxVAL,"1"}},
        {NUMLITxVAL,"2"}}},
      "Array item in LHS of assignment")
    checkParse(t, "a = b[2]", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"a"},{ARRAYxVAR,"b",{NUMLITxVAL,
        "2"}}}},
      "Array item in RHS of assignment")
    checkParse(t, "abc[5*2+a]=bcd[5<=true/4]/cde[not false>x]", true, true,
      {STMTxLIST,{ASSNxSTMT,{ARRAYxVAR,"abc",{{BINxOP,"+"},{{BINxOP,
        "*"},{NUMLITxVAL,"5"},{NUMLITxVAL,"2"}},{SIMPLExVAR,"a"}}},
        {{BINxOP,"/"},{ARRAYxVAR,"bcd",{{BINxOP,"<="},{NUMLITxVAL,"5"},
        {{BINxOP,"/"},{BOOLLITxVAL,"true"},{NUMLITxVAL,"4"}}}},
        {ARRAYxVAR,"cde",{{BINxOP,">"},{{UNxOP,"not"},{BOOLLITxVAL,
        "false"}},{SIMPLExVAR,"x"}}}}}},
      "Array items: fancier")
end


function test_expr_complex(t)
    io.write("Test Suite: complex expressions\n")

    checkParse(t, "x=((((((((((((((((((((((((((((((((((((((((a)))"
      ..")))))))))))))))))))))))))))))))))))))", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{SIMPLExVAR,"a"}}},
      "Complex expression: many parens")
    checkParse(t, "x=(((((((((((((((((((((((((((((((((((((((a))))"
      .."))))))))))))))))))))))))))))))))))))", true, false, nil,
      "Bad complex expression: many parens, mismatch #1")
    checkParse(t, "x=((((((((((((((((((((((((((((((((((((((((a)))"
      .."))))))))))))))))))))))))))))))))))))", false, true, nil,
      "Bad complex expression: many parens, mismatch #2")
    checkParse(t, "x=a==b+c[x-y[2]]*+d!=e-f/-g<h+i%+j", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"<"},
        {{BINxOP,"!="},{{BINxOP,"=="},{SIMPLExVAR,"a"},{{BINxOP,"+"},
        {SIMPLExVAR,"b"},{{BINxOP,"*"},{ARRAYxVAR,"c",{{BINxOP,"-"},
        {SIMPLExVAR,"x"},{ARRAYxVAR,"y",{NUMLITxVAL,"2"}}}},{{UNxOP,
        "+"},{SIMPLExVAR,"d"}}}}},{{BINxOP,"-"},{SIMPLExVAR,"e"},
        {{BINxOP,"/"},{SIMPLExVAR,"f"},{{UNxOP,"-"},{SIMPLExVAR,
        "g"}}}}},{{BINxOP,"+"},{SIMPLExVAR,"h"},{{BINxOP,"%"},
        {SIMPLExVAR,"i"},{{UNxOP,"+"},{SIMPLExVAR,"j"}}}}}}},
      "Complex expression: misc #1")
    checkParse(t, "x=a==b+(c*+(d!=e[2*z]-f/-g)<h+i)%+j", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,"=="},{SIMPLExVAR,
        "a"},{{BINxOP,"+"},{SIMPLExVAR,"b"},{{BINxOP,"%"},{{BINxOP,"<"},
        {{BINxOP,"*"},{SIMPLExVAR,"c"},{{UNxOP,"+"},{{BINxOP,"!="},
        {SIMPLExVAR,"d"},{{BINxOP,"-"},{ARRAYxVAR,"e",{{BINxOP,"*"},
        {NUMLITxVAL,"2"},{SIMPLExVAR,"z"}}},{{BINxOP,"/"},{SIMPLExVAR,
        "f"},{{UNxOP,"-"},{SIMPLExVAR,"g"}}}}}}},{{BINxOP,"+"},
        {SIMPLExVAR,"h"},{SIMPLExVAR,"i"}}},{{UNxOP,"+"},{SIMPLExVAR,
        "j"}}}}}}},
      "Complex expression: misc #2")
    checkParse(t, "x=a[x[y[z]]%4]++b*c<=d--e/f>g+-h%i>=j", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},{{BINxOP,
        ">"},{{BINxOP,"<="},{{BINxOP,"+"},{ARRAYxVAR,"a",{{BINxOP,"%"},
        {ARRAYxVAR,"x",{ARRAYxVAR,"y",{SIMPLExVAR,"z"}}},{NUMLITxVAL,
        "4"}}},{{BINxOP,"*"},{{UNxOP,"+"},{SIMPLExVAR,"b"}},{SIMPLExVAR,
        "c"}}},{{BINxOP,"-"},{SIMPLExVAR,"d"},{{BINxOP,"/"},
        {{UNxOP,"-"},{SIMPLExVAR,"e"}},{SIMPLExVAR,"f"}}}},
        {{BINxOP,"+"},{SIMPLExVAR,"g"},{{BINxOP,"%"},{{UNxOP,"-"},
        {SIMPLExVAR,"h"}},{SIMPLExVAR,"i"}}}},{SIMPLExVAR,"j"}}}},
      "Complex expression: misc #3")
    checkParse(t, "x=a++(b*c<=d)--e/(f>g+-h%i)>=j[-z]", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{{BINxOP,">="},
        {{BINxOP,"-"},{{BINxOP,"+"},{SIMPLExVAR,"a"},{{UNxOP,"+"},
        {{BINxOP,"<="},{{BINxOP,"*"},{SIMPLExVAR,"b"},{SIMPLExVAR,"c"}},
        {SIMPLExVAR,"d"}}}},{{BINxOP,"/"},{{UNxOP,"-"},
        {SIMPLExVAR,"e"}},{{BINxOP,">"},{SIMPLExVAR,"f"},{{BINxOP,"+"},
        {SIMPLExVAR,"g"},{{BINxOP,"%"},{{UNxOP,"-"},{SIMPLExVAR,"h"}},
        {SIMPLExVAR,"i"}}}}}},{ARRAYxVAR,"j",{{UNxOP,"-"},
        {SIMPLExVAR,"z"}}}}}},
      "Complex expression: misc #4")
    checkParse(t, "x=a==b+c*+d!=e-/-g<h+i%+j",
      false, false, nil,
      "Bad complex expression: misc #1")
    checkParse(t, "x=a==b+(c*+(d!=e-f/-g)<h+i)%+",
      false, true, nil,
      "Bad complex expression: misc #2")
    checkParse(t, "x=a++b*c<=d--e x/f>g+-h%i>=j",
      false, false, nil,
      "Bad complex expression: misc #3")
    checkParse(t, "x=a++b*c<=d)--e/(f>g+-h%i)>=j",
      true, false, nil,
      "Bad complex expression: misc #4")

    checkParse(t, "x=((a[(b[c[(d[((e[f]))])]])]))", true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"x"},{ARRAYxVAR,"a",
        {ARRAYxVAR,"b",{ARRAYxVAR,"c",{ARRAYxVAR,"d",{ARRAYxVAR,"e",
        {SIMPLExVAR,"f"}}}}}}}},
      "Complex expression: many parens/brackets")
    checkParse(t, "x=((a[(b[c[(d[((e[f]))]])])]))", false, false, nil,
      "Bad complex expression: mismatched parens/brackets")

    checkParse(t, "while (a+b)%d+a()!=true print() end", true, true,
      {STMTxLIST,{WHILExSTMT,{{BINxOP,"!="},{{BINxOP,"+"},{{BINxOP,"%"},
        {{BINxOP,"+"},{SIMPLExVAR,"a"},{SIMPLExVAR,"b"}},{SIMPLExVAR,
        "d"}},{FUNCxCALL,"a"}},{BOOLLITxVAL,"true"}},{STMTxLIST,
        {PRINTxSTMT}}}},
      "While statment with complex expression")
    checkParse(t, "if 6e+5==true/((q()))+-+-+-false a=3elif 3+4+5 "
      .."x=5else r=7end", true, true,
      {STMTxLIST,{IFxSTMT,{{BINxOP,"=="},{NUMLITxVAL,"6e+5"},{{BINxOP,
        "+"},{{BINxOP,"/"},{BOOLLITxVAL,"true"},{FUNCxCALL,"q"}},
        {{UNxOP,"-"},{{UNxOP,"+"},{{UNxOP,"-"},{{UNxOP,"+"},{{UNxOP,
        "-"},{BOOLLITxVAL,"false"}}}}}}}},{STMTxLIST,{ASSNxSTMT,
        {SIMPLExVAR,"a"},{NUMLITxVAL,"3"}}},{{BINxOP,"+"},{{BINxOP,"+"},
        {NUMLITxVAL,"3"},{NUMLITxVAL,"4"}},{NUMLITxVAL,"5"}},{STMTxLIST,
        {ASSNxSTMT,{SIMPLExVAR,"x"},{NUMLITxVAL,"5"}}},{STMTxLIST,
        {ASSNxSTMT,{SIMPLExVAR,"r"},{NUMLITxVAL,"7"}}}}},
      "If statement with complex expression")
end


function test_prog(t)
    io.write("Test Suite: complete programs\n")

    -- Example #1 from Assignment 4 description
    checkParse(t,
      [[#
        # Degu Example #1
        # Glenn G. Chappell
        # 2020-02-06
        nn = 3
        print(nn, '\n')
      ]], true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"nn"},{NUMLITxVAL,"3"}},
        {PRINTxSTMT,{SIMPLExVAR,"nn"},{STRLITxOUT,"'\\n'"}}},
      "Program: Example #1 from Assignment 4 description")

    -- Fibonacci Example
    checkParse(t,
      [[#
        # fibo.degu
        # Glenn G. Chappell
        # 2020-02-06
        #
        # For CS F331 / CSCE A331 Spring 2020
        # Compute Fibonacci Numbers

        # The Fibonacci number F(n), for n >= 0, is defined by F(0) = 0,
        # F(1) = 1, and for n >= 2, F(n) = F(n-2) + F(n-1).

        # fibo
        # Parameter is in variable n. Return Fibonacci number F(n).
        func fibo()
            curr_fibo = 0
            next_fibo = 1
            i = 0  # Loop counter
            while i < n
                # Advance (curr_fibo, next_fibo)
                tmp = curr_fibo + next_fibo
                curr_fibo = next_fibo
                next_fibo = tmp
                i = i+1
            end
            return curr_fibo
        end

        # Main program
        # Print some Fibonacci numbers
        how_many_to_print = 20

        print("Fibonacci Numbers\n")

        j = 0  # Loop counter
        while j < how_many_to_print
            n = j  # Set parameter for fibo
            print("F(",j,") = ",fibo(),"\n")
            j = j+1
        end
      ]], true, true,
      {STMTxLIST,{FUNCxDEF,"fibo",{STMTxLIST,{ASSNxSTMT,
        {SIMPLExVAR,"curr_fibo"},{NUMLITxVAL,"0"}},{ASSNxSTMT,
        {SIMPLExVAR,"next_fibo"},{NUMLITxVAL,"1"}},{ASSNxSTMT,
        {SIMPLExVAR,"i"},{NUMLITxVAL,"0"}},{WHILExSTMT,{{BINxOP,"<"},
        {SIMPLExVAR,"i"},{SIMPLExVAR,"n"}},{STMTxLIST,{ASSNxSTMT,
        {SIMPLExVAR,"tmp"},{{BINxOP,"+"},{SIMPLExVAR,"curr_fibo"},
        {SIMPLExVAR,"next_fibo"}}},{ASSNxSTMT,{SIMPLExVAR,"curr_fibo"},
        {SIMPLExVAR,"next_fibo"}},{ASSNxSTMT,{SIMPLExVAR,"next_fibo"},
        {SIMPLExVAR,"tmp"}},{ASSNxSTMT,{SIMPLExVAR,"i"},{{BINxOP,"+"},
        {SIMPLExVAR,"i"},{NUMLITxVAL,"1"}}}}},{RETURNxSTMT,
        {SIMPLExVAR,"curr_fibo"}}}},{ASSNxSTMT,
        {SIMPLExVAR,"how_many_to_print"},{NUMLITxVAL,"20"}},{PRINTxSTMT,
        {STRLITxOUT,"\"Fibonacci Numbers\\n\""}},{ASSNxSTMT,
        {SIMPLExVAR,"j"},{NUMLITxVAL,"0"}},{WHILExSTMT,{{BINxOP,"<"},
        {SIMPLExVAR,"j"},{SIMPLExVAR,"how_many_to_print"}},{STMTxLIST,
        {ASSNxSTMT,{SIMPLExVAR,"n"},{SIMPLExVAR,"j"}},{PRINTxSTMT,
        {STRLITxOUT,"\"F(\""},{SIMPLExVAR,"j"},{STRLITxOUT,"\") = \""},
        {FUNCxCALL,"fibo"},{STRLITxOUT,"\"\\n\""}},{ASSNxSTMT,
        {SIMPLExVAR,"j"},{{BINxOP,"+"},{SIMPLExVAR,"j"},
        {NUMLITxVAL,"1"}}}}}},
      "Program: Fibonacci Example")

    -- Input number, print its square
    checkParse(t,
      [[#
        print('Type a number: ')
        a = input()
        print('\n\n')
        print('You typed: ')
        print(a, '\n')
        print('Its square is: ')
        print(a*a, '\n\n')
      ]], true, true,
      {STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"'Type a number: '"}},
        {ASSNxSTMT,{SIMPLExVAR,"a"},{INPUTxCALL}},{PRINTxSTMT,
        {STRLITxOUT,"'\\n\\n'"}},{PRINTxSTMT,
        {STRLITxOUT,"'You typed: '"}},{PRINTxSTMT,{SIMPLExVAR,"a"},
        {STRLITxOUT,"'\\n'"}},{PRINTxSTMT,
        {STRLITxOUT,"'Its square is: '"}},{PRINTxSTMT,{{BINxOP,"*"},
        {SIMPLExVAR,"a"},{SIMPLExVAR,"a"}},{STRLITxOUT,"'\\n\\n'"}}},
      "Program: Input number, print its square")

    -- Input numbers, stop at sentinel, print even/odd
    checkParse(t,
      [[#
        continue = true
        while continue
            print('Type a number (0 to end): ')
            n = input()
            print('\n\n')
            if n == 0
                continue = false
            else
                print('The number ', n, ' is ')
                if n % 2 == 0
                    print('even')
                else
                    print('odd')
                end
                print('\n\n')
            end
        end
        print('Bye!', '\n\n')
      ]], true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"continue"},
        {BOOLLITxVAL,"true"}},{WHILExSTMT,{SIMPLExVAR,"continue"},
        {STMTxLIST,{PRINTxSTMT,
        {STRLITxOUT,"'Type a number (0 to end): '"}},{ASSNxSTMT,
        {SIMPLExVAR,"n"},{INPUTxCALL}},{PRINTxSTMT,
        {STRLITxOUT,"'\\n\\n'"}},{IFxSTMT,{{BINxOP,"=="},
        {SIMPLExVAR,"n"},{NUMLITxVAL,"0"}},{STMTxLIST,{ASSNxSTMT,
        {SIMPLExVAR,"continue"},{BOOLLITxVAL,"false"}}},{STMTxLIST,
        {PRINTxSTMT,{STRLITxOUT,"'The number '"},{SIMPLExVAR,"n"},
        {STRLITxOUT,"' is '"}},{IFxSTMT,{{BINxOP,"=="},{{BINxOP,"%"},
        {SIMPLExVAR,"n"},{NUMLITxVAL,"2"}},{NUMLITxVAL,"0"}},{STMTxLIST,
        {PRINTxSTMT,{STRLITxOUT,"'even'"}}},{STMTxLIST,{PRINTxSTMT,
        {STRLITxOUT,"'odd'"}}}},{PRINTxSTMT,
        {STRLITxOUT,"'\\n\\n'"}}}}}},{PRINTxSTMT,{STRLITxOUT,"'Bye!'"},
        {STRLITxOUT,"'\\n\\n'"}}},
      "Program: Input numbers, stop at sentinel, print even/odd")

    -- Input numbers, print them in reverse order
    checkParse(t,
      [[#
        howMany = 5  # How many numbers to input
        print('I will ask you for ', howMany, ' numbers.\n')
        print('Then I will print them in reverse order.\n\n')
        i = 1
        while i <= howMany  # Input loop
            print('Type value #', i, ': ')
            v[i] = input()
            print('\n\n')
            i = i+1
        end
        print('------------------------------------\n\n')
        print('Here are the values, in reverse order:\n')
        i = howMany
        while i > 0  # Output loop
            print('Value #', i, ': ', v[i], '\n')
            i = i-1
        end
        print('\n')
      ]], true, true,
      {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"howMany"},{NUMLITxVAL,"5"}},
        {PRINTxSTMT,{STRLITxOUT,"'I will ask you for '"},{SIMPLExVAR,"howMany"},
        {STRLITxOUT,"' numbers.\\n'"}},{PRINTxSTMT,
        {STRLITxOUT,"'Then I will print them in reverse order.\\n\\n'"}},
        {ASSNxSTMT,{SIMPLExVAR,"i"},{NUMLITxVAL,"1"}},{WHILExSTMT,
        {{BINxOP,"<="},{SIMPLExVAR,"i"},{SIMPLExVAR,"howMany"}},
        {STMTxLIST,{PRINTxSTMT,{STRLITxOUT,"'Type value #'"},
        {SIMPLExVAR,"i"},{STRLITxOUT,"': '"}},{ASSNxSTMT,{ARRAYxVAR,"v",
        {SIMPLExVAR,"i"}},{INPUTxCALL}},{PRINTxSTMT,
        {STRLITxOUT,"'\\n\\n'"}},{ASSNxSTMT,{SIMPLExVAR,"i"},
        {{BINxOP,"+"},{SIMPLExVAR,"i"},{NUMLITxVAL,"1"}}}}},{PRINTxSTMT,
        {STRLITxOUT,"'------------------------------------\\n\\n'"}},
        {PRINTxSTMT,
        {STRLITxOUT,"'Here are the values, in reverse order:\\n'"}},
        {ASSNxSTMT,{SIMPLExVAR,"i"},{SIMPLExVAR,"howMany"}},{WHILExSTMT,
        {{BINxOP,">"},{SIMPLExVAR,"i"},{NUMLITxVAL,"0"}},{STMTxLIST,
        {PRINTxSTMT,{STRLITxOUT,"'Value #'"},{SIMPLExVAR,"i"},
        {STRLITxOUT,"': '"},{ARRAYxVAR,"v",{SIMPLExVAR,"i"}},
        {STRLITxOUT,"'\\n'"}},{ASSNxSTMT,{SIMPLExVAR,"i"},{{BINxOP,"-"},
        {SIMPLExVAR,"i"},{NUMLITxVAL,"1"}}}}},{PRINTxSTMT,
        {STRLITxOUT,"'\\n'"}}},
      "Program: Input numbers, print them in reverse order")

    -- Long program
    howmany = 200
    progpiece = "print(42)\n"
    prog = progpiece:rep(howmany)
    ast = {STMTxLIST}
    astpiece = {PRINTxSTMT,{NUMLITxVAL,"42"}}
    for i = 1, howmany do
        table.insert(ast, astpiece)
    end
    checkParse(t, prog, true, true,
      ast,
      "Program: Long program")

    -- Very long program
    howmany = 20000
    progpiece = "x = input() print(x, '\\n')\n"
    prog = progpiece:rep(howmany)
    ast = {STMTxLIST}
    astpiece1 = {ASSNxSTMT,{SIMPLExVAR,"x"},{INPUTxCALL}}
    astpiece2 = {PRINTxSTMT,{SIMPLExVAR,"x"},{STRLITxOUT,"'\\n'"}}
    for i = 1, howmany do
        table.insert(ast, astpiece1)
        table.insert(ast, astpiece2)
    end
    checkParse(t, prog, true, true,
      ast,
      "Program: Very long program")
end


function test_parseit(t)
    io.write("TEST SUITES FOR MODULE parseit\n")
    test_simple(t)
    test_print_stmt_no_expr(t)
    test_function_call_stmt(t)
    test_func_def_no_expr(t)
    test_while_stmt_simple_expr(t)
    test_if_stmt_simple_expr(t)
    test_assn_stmt_simple_expr(t)
    test_return_stmt(t)
    test_print_stmt_with_expr(t)
    test_func_def_with_expr(t)
    test_expr_prec_assoc(t)
    test_input(t)
    test_array_item(t)
    test_expr_complex(t)
    test_prog(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_parseit(tester)
io.write("\n")
endMessage(tester:allPassed())

-- Wait for user
io.write("\nPress ENTER to quit ")
io.read("*l")


