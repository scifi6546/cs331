-- parseit.lua
-- Glenn G. Chappell, Nicholas Alexeev
-- 2020-02-14
--
-- For CS F331 / CSCE A331 Spring 2020
-- Recursive-Descent Parser #4: Expressions + Better ASTs
-- Requires lexer.lua


-- Grammar
-- Start symbol: expr
--
--     expr    ->  term { ("+" | s"-") term }
--     term    ->  factor { ("*" | "/") factor }
--     factor  ->  ID
--              |  NUMLIT
--              |  "(" expr ")"
--
-- All operators (+ - * /) are left-associative.
--
-- AST Specification
-- - For an ID, the AST is { SIMPLE_VAR, SS }, where SS is the string
--   form of the lexeme.
-- - For a NUMLIT, the AST is { NUMLIT_VAL, SS }, where SS is the string
--   form of the lexeme.
-- - For expr -> term, then AST for the expr is the AST for the term,
--   and similarly for term -> factor.
-- - Let X, Y be expressions with ASTs XT, YT, respectively.
--   - The AST for ( X ) is XT.
--   - The AST for X + Y is { { BIN_OP, "+" }, XT, YT }. For multiple
--     "+" operators, left-asociativity is reflected in the AST. And
--     similarly for the other operators.


local rdparser4 = {}  -- Our module
local STMT_LIST   = 1
local PRINT_STMT  = 2
local FUNC_DEF    = 3
local FUNC_CALL   = 4
local IF_STMT     = 5
local WHILE_STMT  = 6
local RETURN_STMT = 7
local ASSN_STMT   = 8
local STRLIT_OUT  = 9
local CHAR_CALL   = 10
local BIN_OP      = 11
local UN_OP       = 12
local NUMLIT_VAL  = 13
local BOOLLIT_VAL = 14
local INPUT_CALL  = 15
local SIMPLE_VAR  = 16
local ARRAY_VAR   = 17
local lexer = require "lexer"

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
-- Variables

-- For lexer iteration
local iter          -- Iterator returned by lexer.lex
local state         -- State for above iterator (maybe not used)
local lexer_out_s   -- Return value #1 from above iterator
local lexer_out_c   -- Return value #2 from above iterator

-- For current lexeme
local lexstr = ""   -- String form of current lexeme
local lexcat = 0    -- Category of current lexeme:
                    --  one of categories below, or 0 for past the end


-- Symbolic Constants for AST


-- Utility Functions

-- advance
-- Go to next lexeme and load it into lexstr, lexcat.
-- Should be called once before any parsing is done.
-- Function init must be called before this function is called.
local function advance()
    -- Advance the iterator
    lexer_out_s, lexer_out_c = iter(state, lexer_out_s)

    -- If we're not past the end, copy current lexeme into vars
    if lexer_out_s ~= nil then
        lexstr, lexcat = lexer_out_s, lexer_out_c
    else
        lexstr, lexcat = "", 0
    end
end


-- init
-- Initial call. Sets input for parsing functions.
local function init(prog)
    iter, state, lexer_out_s = lexer.lex(prog)
    advance()
end


-- atEnd
-- Return true if pos has reached end of input.
-- Function init must be called before this function is called.
local function atEnd()
    return lexcat == 0
end


-- matchString
-- Given string, see if current lexeme string form is equal to it. If
-- so, then advance to next lexeme & return true. If not, then do not
-- advance, return false.
-- Function init must be called before this function is called.
local function matchString(s)
    if lexstr == s then
        advance()
        return true
    else
        return false
    end
end


-- matchCat
-- Given lexeme category (integer), see if current lexeme category is
-- equal to it. If so, then advance to next lexeme & return true. If
-- not, then do not advance, return false.
-- Function init must be called before this function is called.
local function matchCat(c)
    if lexcat == c then
        advance()
        return true
    else
        return false
    end
end


-- Primary Function for Client Code

-- "local" statements for parsing functions
local parse_program
local parse_stmt_list
local parse_statement
local parse_print_arg
local parse_expr
local parse_comp_expr
local parse_arith_expr
local parse_term
local parse_factor

-- parse
-- Given program, initialize parser and call parsing function for start
-- symbol. Returns pair of booleans & AST. First boolean indicates
-- successful parse or not. Second boolean indicates whether the parser
-- reached the end of the input or not. AST is only valid if first
-- boolean is true.
function rdparser4.parse(prog)
    -- Initialization
    init(prog)

    -- Get results from parsing
    local good, ast = parse_program()  -- Parse start symbol
    local done = atEnd()

    -- And return them
    return good, done,ast
end
function parse_program()
    local good, ast

    good, ast = parse_stmt_list()
    return good, ast
end
function parse_stmt_list()
	local good, ast, newast

    ast = { STMT_LIST }
    while true do
        print("parse_stmt_list lexstr: "..lexstr)
        if lexstr ~= "print"
          and lexstr ~= "func"
          and lexstr ~= "if"
          and lexstr ~= "while"
          and lexstr ~= "return"
          and lexcat ~= lexer.ID then
            print("not id")
            return true, ast
        end

        good, newast = parse_statement()
        if not good then
            print("stmt not good")
            print(atEnd())
            print("")
            return false, nil
        end

        table.insert(ast, newast)
    end
end
function parse_statement()
    local good, ast1, ast2, savelex, arrayflag
    print("lexcat: " .. lexcat)
    if matchString("print") then
        print("handeling print")
        if not matchString("(") then
            return false, nil
        end

        if matchString(")") then
            return true, { PRINT_STMT }
        end

        good, ast1 = parse_print_arg()
        print("from parse_print_arg")
        print(dump(ast1))
        if not good then
            print("failed parse print arg")
            return false, nil
        end

        ast2 = { PRINT_STMT, ast1 }
        
        while matchString(",") do
            good, ast1 = parse_print_arg()
            if not good then
                print("failed to parse args after comma")
                return false, nil
            end
            
            table.insert(ast2, ast1)
        end

        if not matchString(")") then
            return false, nil
        end
   
        return true, ast2

    elseif matchString("func") then
        local func_name = lexstr;
        if matchCat(lexer.ID) then
            
            if matchString("(") and matchString(")") then
                local good,ast2=parse_stmt_list()
                if not good then
                    return false,nil
                end
                if matchString("end") then
                    return good,{FUNC_DEF,func_name,ast2}
                else
                    return false,nil
                end
            else 
                return false,nil
            end
        end
    elseif matchString("if") then
        local good,expr_ast=parse_expr();
        if not good then
            print("parse_statemnt if: parse_expr failed");
            return false,nil;
        end
        local good,stmt_list_ast = parse_stmt_list();
        if not good then
            return false,nil;
        end
        local out_ast = {IF_STMT,expr_ast,stmt_list_ast}
        --local elif_list_ast=nil
        while matchString("elif") do
            local good,elif_expr_ast = parse_expr()
            if not good then
                return false,nil;
            end
            local good,elif_stmt_list_ast = parse_stmt_list();
            if not good then
                return false,nil;
            end
            print("elif ast: " .. dump(elif_stmt_list_ast))
            
            table.insert(out_ast,elif_expr_ast);
            table.insert(out_ast,elif_stmt_list_ast);
            
        end
        local else_ast = nil
        if matchString("else") then
            local good=false
            good,else_ast = parse_stmt_list()
            if not good then
                return false,nil;
            end
        end
        if not matchString("end") then
            return false,nil
        end
        
        
        if else_ast~=nil then
            table.insert(out_ast,else_ast);
        end
        return true,out_ast
    elseif matchString("while")then
        local good,expr_ast = parse_expr()
        print("while_expr ast"..dump(expr_ast))
        if not good then
            return false,nil
        end
        local good,stmt_list_ast = parse_stmt_list()
        if not good then
            return false,nil
        end
        if matchString("end") then
            return true,{WHILE_STMT,expr_ast,stmt_list_ast};
        else
            return false,nil
        end
    elseif matchString("return") then
        local good,ast = parse_expr()
        if not good then 
            return false,nil
        end
        return true,{RETURN_STMT,ast}
    else
        local function_name = lexstr
        if matchCat(lexer.ID) then
            print("matched identifier")
            if matchString("(") and matchString(")") then
                print("matched func")
                return true,{FUNC_CALL,function_name}
            else
                local ast={ASSN_STMT,{SIMPLE_VAR,function_name}}
                if matchString("[") then
                    print("matched [")
                    local good,array_ast = parse_expr();
                    if not good then
                        print("failed to parse expr")
                        return false,nil
                    end
                    if matchString("]")then
                        ast={ASSN_STMT,{ARRAY_VAR,function_name,array_ast}};
                    else
                        print("] not found")
                        return false,nil
                    end
                end
                if matchString("=") then
                    print("matched = ")
                    print("lexstr: "..lexstr)
                    print("lexcat: "..lexcat)
                    local good,expr_ast = parse_expr()
                    print("expr_ast: "..dump(expr_ast))
                    if not good then
                        print("after= expr not parsed")
                        return false,nil
                    end
                    table.insert(ast,expr_ast)
                    print("inserting table")
                    return true,ast;
                else
                    return false,nil
                end
            end
        else
            return false,nil
        end
    end
end
function parse_print_arg()
    local temp_strlit = lexstr
    
    if matchString("char") then
        local good,ast = parse_expr();
        
        if not good then
            print("failed to parse char")
            return false,nil
        end
        return true,{CHAR_CALL,ast}
    elseif matchCat(lexer.STRLIT) then
        print("returning strlit "..temp_strlit)
        return true,{STRLIT_OUT,temp_strlit}
    else
        local good,ast = parse_expr();
        if not good then
            return false,nil
        end
        return true,ast
    end
end
-- Parsing Functions

-- Each of the following is a parsing function for a nonterminal in the
-- grammar. Each function parses the nonterminal in its name and returns
-- a pair: boolean, AST. On a successul parse, the boolean is true, the
-- AST is valid, and the current lexeme is just past the end of the
-- string the nonterminal expanded into. Otherwise, the boolean is
-- false, the AST is not valid, and no guarantees are made about the
-- current lexeme. See the AST Specification near the beginning of this
-- file for the format of the returned AST.

-- NOTE. Declare parsing functions "local" above, but not below. This
-- allows them to be called before their definitions.


-- parse_expr
-- Parsing function for nonterminal "expr".
-- Function init must be called before this function is called.
function parse_expr()
    local good, ast, saveop, newast

    good, ast = parse_comp_expr()
    if not good then
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("and") and not matchString("or") then
            break
        end

        good, newast = parse_comp_expr()
        if not good then
            return false, nil
        end

        ast = { { BIN_OP, saveop }, ast, newast }
    end

    return true, ast
end

function parse_comp_expr()

    local good, ast, saveop, newast

    good, ast = parse_arith_expr()
    if not good then
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("==") and
        not matchString("!=") and 
        not matchString("<") and 
        not matchString("<=") and 
        not matchString(">") and 
        not matchString(">=") then
            break
        end

        good, newast = parse_arith_expr()
        if not good then
            return false, nil
        end

        ast = { { BIN_OP, saveop }, ast, newast }
    end

    return true, ast
end
function parse_arith_expr()
    local good, out_ast
    good, out_ast = parse_term()
    if not good then
        print("parse_arith_expr: parse failed")
        return false, nil
    end
    local lexsave=lexstr
    local temp_ast = nil
    while matchString("+") or matchString("-") do
        local good,ast2 = parse_term();
        if not good then
            return false, nil
        end
        if temp_ast==nil then
            temp_ast={}
        end
        out_ast={out_ast}
        table.insert(out_ast,1,{BIN_OP,lexsave})
        table.insert(out_ast,ast2)
        lexsave=lexstr
    end
    
    return true,out_ast
end
-- parse_term
-- Parsing function for nonterminal "term".
-- Function init must be called before this function is called.
function parse_term()
    local good, ast, saveop, newast
    good, ast = parse_factor()
    if not good then
        print("in parse term: failed to parse factor")
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("*") and not matchString("/") and not matchString("%") then
            break
        end

        good, newast = parse_factor()
        if not good then
            return false, nil
        end

        ast = { { BIN_OP, saveop }, ast, newast }
    end

    return true, ast
end


-- parse_factor
-- Parsing function for nonterminal "factor".
-- Function init must be called before this function is called.
function parse_factor()
    local savelex, good, ast
    
    savelex = lexstr
    print("parse factor savelex: "..savelex)
    if matchCat(lexer.ID) then
        if matchString("(") then
            if matchString(")") then
                return true,{FUNC_CALL,savelex}
            else
                print("did not match string )")
                return false,nil
            end
        elseif matchString("[") then
            local good,ast = parse_expr();
            if not good then
                print("did not parse array")
                return false,nil
            end
            if matchString("]") then
                return true,{ARRAY_VAR,savelex,ast}
            else
                return false,nil
            end
        else
            return true,{SIMPLE_VAR,savelex}
        end
    elseif matchString("input") then
        if matchString("(") then
            if matchString(")") then
                return true,{INPUT_CALL}
            else
                return false,nil
            end
        else 
            return false,nil
        end
    elseif matchString("+") or matchString("-") or matchString("not") then
        local good,ast = parse_factor()
        if not good then
            return false,nil
        end
        return true,{{UN_OP,savelex},ast}
    elseif matchString("false") then
        return true,{BOOLLIT_VAL,"false"}
    elseif matchString("true") then
        return true,{BOOLLIT_VAL,"true"}
    elseif matchCat(lexer.NUMLIT) then
        return true, { NUMLIT_VAL, savelex }
    elseif matchString("(") then
        print("matching (")
        good, ast = parse_expr()
        if not good then
            return false, nil
        end

        if not matchString(")") then
            return false, nil
        end

        return true, ast
    
    else
        return false, nil
    end
end


-- Module Export

return rdparser4


