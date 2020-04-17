-- interpit.lua
-- Nicholas Alexeev and Glenn G. Chappell
-- 2020-04-10
--
-- For CS F331
-- Interpret AST from parseit.parse
-- For Assignment 6, Exercise 1


-- ***************************************************************
-- * To run a Degu program, use degu.lua (which uses this file). *
-- ***************************************************************


local interpit = {}  -- Our module


-- ***** Variables *****


-- Symbolic Constants for AST

local STMT_LIST    = 1
local PRINT_STMT   = 2
local FUNC_DEF     = 3
local FUNC_CALL    = 4
local IF_STMT      = 5
local WHILE_STMT   = 6
local RETURN_STMT  = 7
local ASSN_STMT    = 8
local STRLIT_OUT   = 9
local CHAR_CALL    = 10
local BIN_OP       = 11
local UN_OP        = 12
local NUMLIT_VAL   = 13
local BOOLLIT_VAL  = 14
local INPUT_CALL   = 15
local SIMPLE_VAR   = 16
local ARRAY_VAR    = 17


-- ***** Utility Functions *****


-- numToInt
-- Given a number, return the number rounded toward zero.
local function numToInt(n)
    assert(type(n) == "number")

    if n >= 0 then
        return math.floor(n)
    else
        return math.ceil(n)
    end
end


-- strToNum
-- Given a string, attempt to interpret it as an integer. If this
-- succeeds, return the integer. Otherwise, return 0.
local function strToNum(s)
    assert(type(s) == "string")

    -- Try to do string -> number conversion; make protected call
    -- (pcall), so we can handle errors.
    local success, value = pcall(function() return tonumber(s) end)

    -- Return integer value, or 0 on error.
    if success then
        if value == nil then
            return 0
        else
            return numToInt(value)
        end
    else
        return 0
    end
end


-- numToStr
-- Given a number, return its string form.
local function numToStr(n)
    assert(type(n) == "number")

    return tostring(n)
end

local function numToBool(n)
    if n==0 then
        return false
    else 
        return true

    end
end
-- boolToInt
-- Given a boolean, return 1 if it is true, 0 if it is false.
local function boolToInt(b)
    assert(type(b) == "boolean")

    if b then
        return 1
    else
        return 0
    end
end

-- strToBool
-- given string returns bool value
local function strToBool(s)
    if s == "true" then 
        return true
    elseif s == "false" then
        return false
    end
    assert(0==1)
end

-- astToStr
-- Given an AST, produce a string holding the AST in (roughly) Lua form,
-- with numbers replaced by names of symbolic constants used in parseit.
-- A table is assumed to represent an array.
-- See the Assignment 4 description for the AST Specification.
--
-- THIS FUNCTION IS INTENDED FOR USE IN DEBUGGING ONLY!
-- IT SHOULD NOT BE CALLED IN THE FINAL VERSION OF THE CODE.
function astToStr(x)
    local symbolNames = {
        "STMT_LIST", "PRINT_STMT", "FUNC_DEF", "FUNC_CALL", "IF_STMT",
        "WHILE_STMT", "RETURN_STMT", "ASSN_STMT", "STRLIT_OUT",
        "CHAR_CALL", "BIN_OP", "UN_OP", "NUMLIT_VAL", "BOOLLIT_VAL",
        "INPUT_CALL", "SIMPLE_VAR", "ARRAY_VAR"
    }
    if type(x) == "number" then
        local name = symbolNames[x]
        if name == nil then
            return "<Unknown numerical constant: "..x..">"
        else
            return name
        end
    elseif type(x) == "string" then
        return '"'..x..'"'
    elseif type(x) == "boolean" then
        if x then
            return "true"
        else
            return "false"
        end
    elseif type(x) == "table" then
        local first = true
        local result = "{"
        for k = 1, #x do
            if not first then
                result = result .. ","
            end
            result = result .. astToStr(x[k])
            first = false
        end
        result = result .. "}"
        return result
    elseif type(x) == "nil" then
        return "nil"
    else
        return "<"..type(x)..">"
    end
end


-- ***** Primary Function for Client Code *****


-- interp
-- Interpreter, given AST returned by parseit.parse.
-- Parameters:
--   ast     - AST constructed by parseit.parse
--   state   - Table holding Degu variables & functions
--             - AST for function xyz is in state.f["xyz"]
--             - Value of simple variable xyz is in state.v["xyz"]
--             - Value of array item xyz[42] is in state.a["xyz"][42]
--   incall  - Function to call for line input
--             - incall() inputs line, returns string with no newline
--   outcall - Function to call for string output
--             - outcall(str) outputs str with no added newline
--             - To print a newline, do outcall("\n")
-- Return Value:
--   state, updated with changed variable values
function interpit.interp(ast, state, incall, outcall)
    -- Each local interpretation function is given the AST for the
    -- portion of the code it is interpreting. The function-wide
    -- versions of state, incall, and outcall may be used. The
    -- function-wide version of state may be modified as appropriate.


    -- Forward declare local functions
    local interp_stmt_list
    local handle_backslash_escapes
    local interp_stmt
    local eval_expr
    local is_expr
    local eval_array

    -- interp_stmt_list
    -- Execute a statement list, given its AST.
    function interp_stmt_list(ast)
        for i = 2, #ast do
            interp_stmt(ast[i])
        end
    end


    -- handle_backslash_escapes
    -- Given a string possibly containing backslash escapes,
    -- returns a string with each replaced by the correct character.
    function handle_backslash_escapes(instr)
        local previous = instr:sub(1,1)
        local outstr = ""
        if previous~="\\" then
            outstr = outstr..previous
        end
        for i = 2, instr:len() do
            if previous=="\\" then 
                if instr:sub(i,i)== "n" then
                    outstr = outstr .. "\n"
                    previous = instr:sub(i,i)
                elseif instr:sub(i,i)== "\\" then
                    outstr = outstr .. "\\"
                    previous=""
                else
                    outstr = outstr .. instr:sub(i,i)
                    previous = instr:sub(i,i)
                end
            else
                if instr:sub(i,i) ~= "\\" then 
                    outstr = outstr .. instr:sub(i,i)
                end
                previous = instr:sub(i,i)
            end
            

        end
        return outstr
    end

    function is_expr(ast)
        if ast[1] == SIMPLE_VAR or ast[1] == INPUT_CALL or ast[1] == CHAR_CALL or 
            ast[1] == BIN_OP or ast[1] == UN_OP  or ast[1] == NUMLIT_VAL or ast[1] == BOOLLIT_VAL  then
            return true
        else
            if type(ast[1])=="table" then
                if ast[1][1] == BIN_OP or ast[1][1] == UN_OP  or ast[1][1] == NUMLIT_VAL or ast[1][1] == BOOLLIT_VAL then
                    return true
                end
            end
            return false
        end
    end
    -- interp_stmt
    -- Execute a statement, given its AST.
    function interp_stmt(ast)
        if ast[1] == PRINT_STMT then
            for i = 2, #ast do
                if ast[i][1] == STRLIT_OUT then
                    local str = ast[i][2]
                    
                    outcall(handle_backslash_escapes(
                             str:sub(2,str:len()-1)))
                elseif ast[i][1] == CHAR_CALL then
                    outcall(eval_expr(ast[i]))
                else

                    local value = eval_expr(ast[i])
                    outcall(numToStr(value))
                end
            end
        elseif ast[1] == FUNC_DEF then
            local funcname = ast[2]
            local funcbody = ast[3]
            state.f[funcname] = funcbody
        elseif ast[1] == FUNC_CALL then
            local funcname = ast[2]
            local funcbody = state.f[funcname]
            if funcbody == nil then
                funcbody = { STMT_LIST }
            end
            interp_stmt_list(funcbody)
        elseif ast[1] == IF_STMT then
            local if_res = numToBool(eval_expr(ast[2]))
            local i=2
            while ast[i]~=nil do
                
                if is_expr(ast[i]) then
                    if numToBool(eval_expr(ast[i])) then
                        interp_stmt_list(ast[i+1])
                        break
                    end
                    i=i+2
                else
                    interp_stmt_list(ast[i])
                    break
                end
            end

        elseif ast[1] == WHILE_STMT then
            while eval_expr(ast[2])==1 do
                interp_stmt_list(ast[3])
            end
        elseif ast[1] == RETURN_STMT then
            local var_value = eval_expr(ast[2])
            state.v["return"]=var_value
        elseif ast[1] == ASSN_STMT then
            if ast[2][1]==SIMPLE_VAR then
                local var = ast[2][2]
                local var_value = eval_expr(ast[3])
                state.v[var]=var_value

            elseif ast[2][1] == ARRAY_VAR then
                local var_name = ast[2][2]
                if state.a[ast[2][2]] == nil then
                    state.a[ast[2][2]] = {}
                end
                state.a[ast[2][2]][eval_expr(ast[2][3])]=eval_expr(ast[3])
            else
                print("INVALID VARLAIBLE TYPE ASSIGNED TO")
                print(astToStr(ast))
                

            end
        else
            print("INVALID STATEMENT")
            print(astToStr(ast))

        end
    end


    -- eval_expr
    -- Evaluate an expression, given its AST. The return value is the
    -- value of the expression.
    function eval_expr(ast)
        if ast == nil then
            return 0
        elseif ast[1] == NUMLIT_VAL then
            return strToNum(ast[2])
        elseif ast[1] == BOOLLIT_VAL then
            return boolToInt(strToBool(ast[2]))
        elseif ast[1] == SIMPLE_VAR then
            
            if state.v[ast[2]] ~=nil then
                return state.v[ast[2]]
            else
                return 0
            end
        elseif ast[1] == INPUT_CALL then
            return strToNum(incall())
        elseif ast[1] == ARRAY_VAR then
            local array_var_name = ast[2]
            if state.a[array_var_name] == nil then
                return 0
            else
                local arr_value = state.a[array_var_name][eval_expr(ast[3])]
                if arr_value == nil then
                    return 0
                else
                    return arr_value
                end
            end
        elseif ast[1] == CHAR_CALL then
            local char_code = eval_expr(ast[2])
            if char_code>=0 and char_code<=255 then
                return string.char(char_code)
            else
                return string.char(0)
            end
        elseif ast[1] == FUNC_CALL then
            local func_body = state.f[ast[2]]
            local pre_ret = state.v["return"]
            interp_stmt_list(func_body)
            local post_ret = state.v["return"]
            if pre_ret == post_ret then
                if pre_ret~=nil then
                    return post_ret;
                else
                    return 0
                end
            else
                return post_ret
            end
        elseif ast[1][1] == BIN_OP then
            if ast[1][2] == "+" then 
                return numToInt(eval_expr(ast[2])+eval_expr(ast[3]))
            elseif ast[1][2] == "-" then
                return numToInt(eval_expr(ast[2])-eval_expr(ast[3]))
            elseif ast[1][2] == "*" then
                return numToInt(eval_expr(ast[2])*eval_expr(ast[3]))
            elseif ast[1][2] == "/" then
                local bottom = eval_expr(ast[3])
                if bottom==0 then
                    return numToInt(0)
                else
                    return numToInt(eval_expr(ast[2])/eval_expr(ast[3]))
                end
            elseif ast[1][2] == "==" then
                return boolToInt(eval_expr(ast[2]) == eval_expr(ast[3]))
            elseif ast[1][2] == "!=" then
                return boolToInt(eval_expr(ast[2]) ~= eval_expr(ast[3]))
            elseif ast[1][2] == "<=" then
                return boolToInt(eval_expr(ast[2]) <= eval_expr(ast[3]))
            elseif ast[1][2] == ">=" then
                return boolToInt(eval_expr(ast[2]) >= eval_expr(ast[3]))
            elseif ast[1][2] == ">" then
                return boolToInt(eval_expr(ast[2]) > eval_expr(ast[3]))
            elseif ast[1][2] == "<" then
                return boolToInt(eval_expr(ast[2]) < eval_expr(ast[3]))
            elseif ast[1][2] == "&&" then
                return boolToInt(numToBool(eval_expr(ast[2])) and numToBool(eval_expr(ast[3])))
            elseif ast[1][2] == "||" then
                return boolToInt(numToBool(eval_expr(ast[2])) or numToBool(eval_expr(ast[3])))
            elseif ast[1][2] == "%" then
                local left = eval_expr(ast[3])
                if left==0 then
                    return numToInt(0)
                else
                    return numToInt(eval_expr(ast[2]) % eval_expr(ast[3]))
                end
            else
                print("ERROR INVALID BIN OP")
                print(astToStr(ast))
                return 0
            end
        elseif ast[1][1] == UN_OP then
            if ast[1][2] == "-" then
                return numToInt(-1* eval_expr(ast[2]))
            elseif ast[1][2] == "+" then 
                return numToInt(eval_expr(ast[2]))
            elseif ast[1][2] == "!" then
                local num = numToInt(eval_expr(ast[2]))
                if num==0 then
                    return 1
                else
                    return 0
                end
            else
                print("INVALID UNARY OPERATOR")
                print(astToStr(ast))
                return 0
            end
        else
            print("INVALID EXPRESSION")
            print(astToStr(ast))
            
            return 42  -- DUMMY!!!
        end
    end


    -- Body of function interp
    interp_stmt_list(ast)
    return state
end


-- ***** Module Export *****


return interpit