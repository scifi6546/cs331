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

local BIN_OP     = 1
local NUMLIT_VAL = 2
local SIMPLE_VAR = 3


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
        print("lexstr: "..lexstr)
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
            print("not good")
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
            return false, nil
        end

        ast2 = { PRINT_STMT, ast1 }
        
        while matchString(",") do
            good, ast1 = parse_print_arg()
            if not good then
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
            
            if matchString("()") then
                local good,ast2=parse_stmt_list()
                if not good then
                    return false,nil
                end
                return good,{FUNC_DEF,func_name,{ast2}}
            end
        end
    else
        local function_name = lexstr
        if matchCat(lexer.ID) then
            print("matched identifier")
            if matchString("(") and matchString(")") then
                return true,{FUNC_CALL,function_name}
            elseif matchString("[") then
                local good,ast = parse_expr();
                if not good then
                    return false,nil
                end
                if matchString("]") and matchString("=") then
                    local good,ast3 = parse_expr();
                    return true,{"todo"}
                else
                    return false,nil
                end
            else
                return false,nil
            end
        else
            return false,nil
        end
    end
end
function parse_print_arg()
    local temp_strlit = lexstr
    if matchCat(lexer.STRLIT) then
        print("returning strlit "..temp_strlit)
        return true,{STRLIT_OUT,temp_strlit}
    elseif matchString("char(") then
        local good,ast = parse_expr();
        if not good then
            return false,nil
        end
        return true,{CHAR_CALL,{ast}}
    else
        local good,ast = parse_expr();
        if not good then
            return false,nil
        end
        return true,{CHAR_CALL,{ast}}
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

    good, ast = parse_term()
    if not good then
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("+") and not matchString("-") then
            break
        end

        good, newast = parse_term()
        if not good then
            return false, nil
        end

        ast = { { BIN_OP, saveop }, ast, newast }
    end

    return true, ast
end


-- parse_term
-- Parsing function for nonterminal "term".
-- Function init must be called before this function is called.
function parse_term()
    local good, ast, saveop, newast

    good, ast = parse_factor()
    if not good then
        return false, nil
    end

    while true do
        saveop = lexstr
        if not matchString("*") and not matchString("/") then
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
    if matchCat(lexer.ID) then
        return true, { SIMPLE_VAR, savelex }
    elseif matchCat(lexer.NUMLIT) then
        return true, { NUMLIT_VAL, savelex }
    elseif matchString("(") then
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


