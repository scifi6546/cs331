#!/usr/bin/env lua
-- interpit_test.lua
-- Glenn G. Chappell
-- 2020-10-13
--
-- For CS F331 / CSCE A331 Spring 2020
-- Test Program for Module interpit
-- Used in Assignment 6, Exercise 1

interpit = require "interpit"  -- Import interpit module


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


-- numKeys
-- Given a table, return the number of keys in it.
function numKeys(tab)
    local keycount = 0
    for k, v in pairs(tab) do
        keycount = keycount + 1
    end
    return keycount
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


-- deepcopy
-- Returns deep copy of given value.
-- From http://lua-users.org/wiki/CopyTable
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


-- isState
-- Return true if given value is properly formatted Jerboa state table,
-- false otherwise.
function isState(tab)
    -- Is table?
    if type(tab) ~= "table" then
        return false
    end

    -- Has exactly 3 keys?
    if numKeys(tab) ~= 3 then
        return false
    end

    -- Has f, v, a keys?
    if tab.f == nil or tab.v == nil or tab.a == nil then
        return false
    end

    -- f, v, a keys are tables?
    if type(tab.f) ~= "table"
      or type(tab.v) ~= "table"
      or type(tab.a) ~= "table" then
        return false
    end

    -- All items in f are string:table
    -- String begins with "[_A-Za-z]"
    for k, v in pairs(tab.f) do
        if type(k) ~= "string" or type(v) ~= "table" then
            return false
        end
        if k:sub(1,1) ~= "_"
           and (k:sub(1,1) < "A" or k:sub(1,1) > "Z")
           and (k:sub(1,1) < "a" or k:sub(1,1) > "z") then
            return false
        end
    end

    -- All items in v are string:number
    -- String begins with "[_A-Za-z]"
    for k, v in pairs(tab.v) do
        if type(k) ~= "string" or type(v) ~= "number" then
            return false
        end
        if k:sub(1,1) ~= "_"
           and (k:sub(1,1) < "A" or k:sub(1,1) > "Z")
           and (k:sub(1,1) < "a" or k:sub(1,1) > "z") then
            return false
        end
    end

    -- All items in a are string:table
    -- String begins with "[_A-Za-z]"
    -- All items in values in a are number:number
    for k, v in pairs(tab.a) do
        if type(k) ~= "string" or type(v) ~= "table" then
            return false
        end
        if k:sub(1,1) ~= "_"
           and (k:sub(1,1) < "A" or k:sub(1,1) > "Z")
           and (k:sub(1,1) < "a" or k:sub(1,1) > "z") then
            return false
        end
        for kk, vv in pairs(v) do
            if type(kk) ~= "number" or type(vv) ~= "number" then
                return false
            end
        end
    end

    return true
end


-- checkInterp
-- Given tester object, AST, array of input strings, input state, array
-- of expected output strings, expected output state, and string giving
-- the name of the test. Calls interpit.interp and checks output strings
-- & state. Prints result. If test fails and EXIT_ON_FIRST_FAILURE is
-- true, then print detailed results and exit program.
function checkInterp(t, ast,
                     input, statein,
                     expoutput, expstateout,
                     testName)
    -- Error flags
    local err_incallparam = false
    local err_outcallnil = false
    local err_outcallnonstr = false

    local incount = 0
    local function incall(param)
        if param ~= nil then
            err_incallparam = true
        end
        incount = incount + 1
        if incount <= #input then
            return input[incount]
        else
            return ""
        end
    end

    local output = {}
    local function outcall(str)
        if type(str) == "string" then
            table.insert(output, str)
        elseif str == nil then
            err_outcallnil = true
            table.insert(output, "")
        else
            err_outcallnonstr = true
            table.insert(output, "")
        end
    end

    local pass = true
    local msg = ""

    local success, result = pcall(interpit.interp,
                                  ast, statein, incall, outcall)
    if not success then
        pass = false
        msg = msg.."interpit.interp crashed:".."\n  "..result.."\n"
    else
        local stateout = result

        if incount > #input then
            pass = false
            msg = msg .. "Too many calls to incall\n"
        elseif incount < #input then
            pass = false
            msg = msg .. "Too few calls to incall\n"
        end

        if err_incallparam then
            pass = false
            msg = msg .. "incall called with parameter\n"
        end

        if #output > #expoutput then
            pass = false
            msg = msg .. "Too many calls to outcall\n"
        elseif #output < #expoutput then
            pass = false
            msg = msg .. "Too few calls to outcall\n"
        end

        if err_outcallnil then
            pass = false
            msg = msg ..
                 "outcall called with nil or missing parameter\n"
        end
        if err_outcallnonstr then
            pass = false
            msg = msg .. "outcall called with non-string parameter\n"
        end

        if not equal(output, expoutput) then
            pass = false
            msg = msg .. "Output incorrect\n"
        end

        if isState(stateout) then
            if not equal(stateout, expstateout) then
                pass = false
                msg = msg .. "Returned state is incorrect\n"
                print(astToStr(stateout.f["fibo"])) --&&&
            end
        else
            pass = false
            msg = msg .. "Returned state is not a Jerboa state\n"
        end
    end

    t:test(pass, testName)
    if pass or not EXIT_ON_FIRST_FAILURE then
        return
    end

    io.write("\n")
    io.write(msg)
    io.write("\n")
    failExit()
end


-- *********************************************************************
-- Test Suite Functions
-- *********************************************************************


function test_pre_written(t)
    io.write("Test Suite: programs that work with pre-written"
             .." interpit.lua\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Empty program
    ast = {STMTxLIST}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Empty program")

    -- Empty print
    ast = {STMTxLIST, {PRINTxSTMT}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "print nothing")

    -- Print: empty string
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "''"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {""}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: empty string")

    -- Print: string, single-quoted
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"abc"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: string, single-quoted")

    -- Print: string, double-quoted
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, '"def"'}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"def"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: string, double-quoted")

    -- Print: string + string
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"},
      {STRLITxOUT, "'def'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"abc", "def"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: string + cr")

    -- Print: number
    ast = {STMTxLIST, {PRINTxSTMT, {NUMLITxVAL, "42"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"42"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: number")

    -- Print: string + number + number + string
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"},
      {NUMLITxVAL, "042"}, {NUMLITxVAL, "1"}, {STRLITxOUT, "\"x\""}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"abc", "42", "1", "x"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: string + number + number + string")

    -- Func, no call
    ast = {STMTxLIST, {FUNCxDEF, "x",
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={}, a={}, f={["x"]={STMTxLIST,
      {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Func, no call")

    -- Call, no func
    ast = {STMTxLIST, {FUNCxCALL, "x"}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Call, no func")

    -- Func with call (wrong name)
    ast = {STMTxLIST, {FUNCxDEF, "x",
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}},
      {FUNCxCALL, "y"}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={}, a={}, f={["x"]={STMTxLIST,
      {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Func with call (wrong name)")

    -- Func with call (right name)
    ast = {STMTxLIST, {FUNCxDEF, "x",
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}},
      {FUNCxCALL, "x"}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"abc"}
    expstateout = {v={}, a={}, f={["x"]={STMTxLIST,
      {PRINTxSTMT, {STRLITxOUT, "'abc'"}}}}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Func with call (right name)")

    -- Func defs func, no call
    ast = {STMTxLIST, {FUNCxDEF, "x",
      {STMTxLIST, {FUNCxDEF, "y", {STMTxLIST}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={}, a={}, f={["x"]={STMTxLIST,
      {FUNCxDEF, "y", {STMTxLIST}}}}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Func defs func, no call")

    -- Func defs func, with call
    ast = {STMTxLIST, {FUNCxDEF, "x",
      {STMTxLIST, {FUNCxDEF, "y", {STMTxLIST}}}},
      {FUNCxCALL, "x"}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={}, a={}, f={["x"]={STMTxLIST,
      {FUNCxDEF, "y", {STMTxLIST}}},
      ["y"]={STMTxLIST}}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Func defs func, with call")
end


function test_simple(t)
    io.write("Test Suite: simple programs\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Simple assignment: number
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "a"},
      {NUMLITxVAL, "42"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=42}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple assignment: number")

    -- Simple assignment: true
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "a"},
      {BOOLLITxVAL, "true"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=1}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple assignment: true")

    -- Simple assignment: false
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "a"},
      {BOOLLITxVAL, "false"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=0}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple assignment: false")

    -- Simple if #1
    ast = {STMTxLIST, {IFxSTMT, {NUMLITxVAL, "0"}, {STMTxLIST}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple if #1")

    -- Simple if #2
    ast = {STMTxLIST, {IFxSTMT, {NUMLITxVAL, "4"}, {STMTxLIST}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple if #2")

    -- Simple while
    ast = {STMTxLIST, {WHILExSTMT, {NUMLITxVAL, "0"}, {STMTxLIST}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple while")

    -- Print: number
    ast = {STMTxLIST, {PRINTxSTMT, {NUMLITxVAL, "28"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"28"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: number")

    -- Print: undefined variable
    ast = {STMTxLIST, {PRINTxSTMT, {SIMPLExVAR, "d"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print: undefined variable")

   -- Simple input
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "b"},
      {INPUTxCALL}}}
    input = {"37"}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["b"]=37}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Simple input")

    -- Set + print: variable
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "c"},
      {NUMLITxVAL, "57"}}, {PRINTxSTMT, {SIMPLExVAR, "c"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"57"}
    expstateout = {v={["c"]=57}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Set + print: variable")

    -- Set + print: other variable
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "c"},
      {NUMLITxVAL, "57"}}, {PRINTxSTMT, {SIMPLExVAR, "d"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = {v={["c"]=57}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Set + print: variable")

    -- Read + print: variable
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "c"},
      {INPUTxCALL}}, {PRINTxSTMT, {SIMPLExVAR, "c"}}}
    input = {"12"}
    statein = deepcopy(emptystate)
    expoutput = {"12"}
    expstateout = {v={["c"]=12}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Read + print: variable")

    -- Read + print: other variable
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "c"},
      {INPUTxCALL}}, {PRINTxSTMT, {SIMPLExVAR, "d"}}}
    input = {"24"}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = {v={["c"]=24}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Read + print: other variable")

    -- Set array
    ast = {STMTxLIST, {ASSNxSTMT,
      {ARRAYxVAR, "a", {NUMLITxVAL, "2"}},
      {NUMLITxVAL, "7"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={}, a={["a"]={[2]=7}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Set array")
end


function test_state(t)
    io.write("Test Suite: modified initial state\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Empty program
    ast = {STMTxLIST}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - empty program")

    -- Set simple var #1
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "a"}, {NUMLITxVAL, "3"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = {v={["a"]=3,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - set simple var #1")

    -- Set simple var #2
    ast = {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "c"}, {NUMLITxVAL, "3"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = {v={["a"]=1,["b"]=2,["c"]=3},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - set simple var #2")

    -- Set array #1
    ast = {STMTxLIST, {ASSNxSTMT,
      {ARRAYxVAR, "b", {NUMLITxVAL, "2"}},
      {NUMLITxVAL, "9"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=9,[4]=3}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - set array #1")

    -- Set array #2
    ast = {STMTxLIST, {ASSNxSTMT,
      {ARRAYxVAR, "b", {NUMLITxVAL, "-5"}},
      {NUMLITxVAL, "9"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3,[-5]=9}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - set array #2")

    -- Set array #3
    ast = {STMTxLIST, {ASSNxSTMT,
      {ARRAYxVAR, "c", {NUMLITxVAL, "0"}},
      {NUMLITxVAL, "9"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {}
    expstateout = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3},["c"]={[0]=9}},
      f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - set array #3")

    -- Print simple var #1
    ast = {STMTxLIST, {PRINTxSTMT, {SIMPLExVAR, "a"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print simple var #1")

    -- Print simple var #2
    ast = {STMTxLIST, {PRINTxSTMT, {SIMPLExVAR, "c"}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print simple var #2")

    -- Print array #1
    ast = {STMTxLIST, {PRINTxSTMT, {ARRAYxVAR, "a",
      {NUMLITxVAL, "4"}}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {"7"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print array #1")

    -- Print array #2
    ast = {STMTxLIST, {PRINTxSTMT, {ARRAYxVAR, "a",
      {NUMLITxVAL, "8"}}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print array #2")

    -- Print array #3
    ast = {STMTxLIST, {PRINTxSTMT, {ARRAYxVAR, "c",
      {NUMLITxVAL, "8"}}}}
    input = {}
    statein = {v={["a"]=1,["b"]=2},
      a={["a"]={[2]=3,[4]=7},["b"]={[2]=7,[4]=3}}, f={}}
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print array #3")

    -- Print-set-print-read-print
    ast = {STMTxLIST,
      {PRINTxSTMT, {SIMPLExVAR, "abc"}},
      {ASSNxSTMT, {SIMPLExVAR, "abc"}, {NUMLITxVAL, "55"}},
      {PRINTxSTMT, {SIMPLExVAR, "abc"}},
      {ASSNxSTMT, {SIMPLExVAR, "abc"}, {INPUTxCALL}},
      {PRINTxSTMT, {SIMPLExVAR, "abc"}}}
    input = {"66"}
    statein = {v={["abc"]=44}, a={}, f={}}
    expoutput = {"44", "55", "66"}
    expstateout = {v={["abc"]=66}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Print-set-print-read-print")

    -- Call func
    ast = {STMTxLIST, {FUNCxCALL, "q"}}
    input = {}
    statein = {v={}, a={}, f={["q"]=
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'x'"}}}
    }}
    expoutput = {"x"}
    expstateout = {v={}, a={}, f={["q"]=
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'x'"}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Modified initial state - Function")
end


function test_special_chars(t)
    io.write("Test Suite: printing special characters\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- print with char()
    ast = {STMTxLIST, {PRINTxSTMT, {CHARxCALL, {NUMLITxVAL, "65"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"A"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print with char()")

    -- char() containing nontrivial expression
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}, {CHARxCALL,
      {{BINxOP, "+"}, {NUMLITxVAL, "60"}, {NUMLITxVAL, "6"}}},
      {STRLITxOUT, "'z'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a", "B", "z"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "char() containing nontrivial expression")

    -- char() containing out-of-range value #1
    ast = {STMTxLIST, {PRINTxSTMT, {CHARxCALL, {{UNxOP, "-"},
      {NUMLITxVAL, "1"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {string.char(0)}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "char() containing out-of-range value #1")

    -- char() containing out-of-range value #2
    ast = {STMTxLIST, {PRINTxSTMT, {CHARxCALL, {NUMLITxVAL, "1000"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {string.char(0)}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "char() containing out-of-range value #2")

    -- Backslash escape: same char #1
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'\\a'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Backslash escape: same char #1")

    -- Backslash escape: same char #2
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'\\!'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"!"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Backslash escape: same char #2")

    -- Backslash escape: backslash
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'\\\\'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"\\"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Backslash escape: backslash")

    -- Backslash escape: newline
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'\\n'"}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"\n"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Backslash escape: newline")

    -- Backslash escapess: fancy
    ast = {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "\"a\\\\\\\\x\\nx\""}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a\\\\x\nx"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Backslash escapes: fancy")
end


function test_expr(t)
    io.write("Test Suite: expressions\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Print unary +
    ast = {STMTxLIST, {PRINTxSTMT,
      {{UNxOP, "+"}, {NUMLITxVAL, "5"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"5"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print unary +")

    -- Print unary -
    ast = {STMTxLIST, {PRINTxSTMT,
      {{UNxOP, "-"}, {NUMLITxVAL, "5"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"-5"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print unary -")

    -- Print ! #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{UNxOP, "!"}, {NUMLITxVAL, "5"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print ! #1")

    -- Print ! #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{UNxOP, "!"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print ! #2")

    -- Print binary +
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "+"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"7"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print binary +")

    -- Print binary -
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "-"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"3"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print binary -")

    -- Print *
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "*"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"10"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print *")

    -- Print /
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "/"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"2"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print /")

    -- Print / (div by zero)
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "/"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print / (div by zero)")

    -- Print %
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "%"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print %")

    -- Print % (div by zero)
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "%"}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print % (div by zero)")

    -- Print == #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "=="}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print == #1")

    -- Print == #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "=="}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "5"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print == #2")

    -- Print != #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "!="}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print != #1")

    -- Print != #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "!="}, {NUMLITxVAL, "5"}, {NUMLITxVAL, "5"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print != #2")

    -- Print < #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<"}, {NUMLITxVAL, "1"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print < #1")

    -- Print < #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print < #2")

    -- Print < #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<"}, {NUMLITxVAL, "3"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print < #3")

    -- Print <= #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<="}, {NUMLITxVAL, "1"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print <= #1")

    -- Print <= #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<="}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print <= #2")

    -- Print <= #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "<="}, {NUMLITxVAL, "3"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print <= #3")

    -- Print > #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">"}, {NUMLITxVAL, "1"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print > #1")

    -- Print > #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print > #2")

    -- Print > #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">"}, {NUMLITxVAL, "3"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print > #3")

    -- Print >= #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">="}, {NUMLITxVAL, "1"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print >= #1")

    -- Print >= #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">="}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print >= #2")

    -- Print >= #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, ">="}, {NUMLITxVAL, "3"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print >= #3")

    -- Print && #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "&&"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print && #1")

    -- Print && #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "&&"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print && #2")

    -- Print && #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "&&"}, {NUMLITxVAL, "0"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print && #3")

    -- Print && #4
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "&&"}, {NUMLITxVAL, "0"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print && #4")

    -- Print || #1
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "||"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print || #1")

    -- Print || #2
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "||"}, {NUMLITxVAL, "2"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print || #2")

    -- Print || #3
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "||"}, {NUMLITxVAL, "0"}, {NUMLITxVAL, "2"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"1"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print || #3")

    -- Print || #4
    ast = {STMTxLIST, {PRINTxSTMT,
      {{BINxOP, "||"}, {NUMLITxVAL, "0"}, {NUMLITxVAL, "0"}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Print || #4")

    -- Longer expression
    ast =
      {STMTxLIST,
        {PRINTxSTMT,
          {{UNxOP, "-"},
            {{BINxOP, "-"},
              {{BINxOP, "=="}, {SIMPLExVAR, "x"}, {NUMLITxVAL, "3"}},
              {{BINxOP, "*"},
                {{BINxOP, "+"},
                  {NUMLITxVAL, "8"},
                  {BOOLLITxVAL, "true"}},
                {{UNxOP, "+"}, {SIMPLExVAR, "y"}}
              }
            }
          }
        }
      }
    input = {}
    statein = {v={["x"]=3, ["y"]=5}, a={}, f={}}
    expoutput = {"44"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Longer expression")
end


function test_intconv(t)
    io.write("Test Suite: integer conversion\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Numeric literal #1
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "n"}, {NUMLITxVAL, "5.4"}}
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["n"]=5}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - numeric literal #1")

    -- Numeric literal #2
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "n"}, {NUMLITxVAL, "-7.4"}}
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["n"]=-7}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - numeric literal #2")

    -- Numeric literal #3
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "n"}, {NUMLITxVAL, "5.74e1"}}
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["n"]=57}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - numeric literal #3")

    -- Input
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "n"}, {INPUTxCALL}}
      }
    input = {"2.9"}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["n"]=2}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - input")

    -- Division + multiplication #1
    ast =
      {STMTxLIST,
        {PRINTxSTMT,
          {{BINxOP, "*"},
            {{BINxOP, "/"}, {NUMLITxVAL, "10"}, {NUMLITxVAL, "3"}},
            {NUMLITxVAL, "3"}
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"9"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - division + multiplication #1")

    -- Division + multiplication #2
    ast =
      {STMTxLIST,
        {PRINTxSTMT,
          {{BINxOP, "*"},
            {{BINxOP, "/"}, {NUMLITxVAL, "-3"}, {NUMLITxVAL, "2"}},
            {NUMLITxVAL, "2"}
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"-2"}
    expstateout = deepcopy(statein)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Integer conversion - division + multiplication #2")
end


function test_if(t)
    io.write("Test Suite: if-statements\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- If #1
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "4"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If #1")

    -- If #2
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If #2")

    -- If-else #1
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "5"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-else #1")

    -- If-else #2
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"b"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-else #2")

    -- If-elseif #1
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "6"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "7"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif #1")

    -- If-elseif #2
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "7"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"b"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif #2")

    -- If-elseif #3
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif #3")

    -- If-elseif-else #1
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "6"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "7"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif-else #1")

    -- If-elseif-else #2
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "7"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"b"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif-else #2")

    -- If-elseif-else #3
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"c"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif-else #3")

    -- If-elseif*-else #1
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "8"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
      {NUMLITxVAL, "9"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'e'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'f'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif*-else #1")

    -- If-elseif*-else #2
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
      {NUMLITxVAL, "9"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'e'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'f'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"d"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif*-else #2")

    -- If-elseif*-else #3
    ast = {STMTxLIST, {IFxSTMT,
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}},
      {NUMLITxVAL, "0"},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'e'"}}},
      {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'f'"}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"f"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "If-elseif*-else #3")

    -- Nested if-else #1
    ast =
      {STMTxLIST,
        {IFxSTMT,
          {NUMLITxVAL, "1"},
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "1"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}
            }
          },
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "1"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}}
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"a"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Nested if-else #1")

    -- Nested if-else #2
    ast =
      {STMTxLIST,
        {IFxSTMT,
          {NUMLITxVAL, "1"},
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "0"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}
            }
          },
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "0"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}}
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"b"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Nested if-else #2")

    -- Nested if-else #3
    ast =
      {STMTxLIST,
        {IFxSTMT,
          {NUMLITxVAL, "0"},
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "1"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}
            }
          },
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "1"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}}
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"c"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Nested if-else #3")

    -- Nested if-else #4
    ast =
      {STMTxLIST,
        {IFxSTMT,
          {NUMLITxVAL, "0"},
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "0"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'a'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'b'"}}}
            }
          },
          {STMTxLIST,
            {IFxSTMT,
              {NUMLITxVAL, "0"},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'c'"}}},
              {STMTxLIST, {PRINTxSTMT, {STRLITxOUT, "'d'"}}}
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"d"}
    expstateout = deepcopy(emptystate)
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Nested if-else #4")
end


function test_while(t)
    io.write("Test Suite: while-loops\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- While loop - counted
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "i"}, {NUMLITxVAL, "0"}},
        {WHILExSTMT,
          {{BINxOP, "<"}, {SIMPLExVAR, "i"}, {NUMLITxVAL, "7"}},
          {STMTxLIST,
            {PRINTxSTMT,
              {{BINxOP, "*"}, {SIMPLExVAR, "i"}, {SIMPLExVAR, "i"}}
            },
            {ASSNxSTMT,
              {SIMPLExVAR, "i"},
              {{BINxOP, "+"}, {SIMPLExVAR, "i"}, {NUMLITxVAL, "1"}}
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0", "1", "4", "9", "16", "25", "36"}
    expstateout = {v={["i"]=7},a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "While loop - counted")

    -- While loop - read with sentinel
    ast =
      {STMTxLIST,
        {ASSNxSTMT, {SIMPLExVAR, "notdone"}, {NUMLITxVAL, "1"}},
        {WHILExSTMT,
          {SIMPLExVAR, "notdone"},
          {STMTxLIST,
            {ASSNxSTMT, {SIMPLExVAR, "n"}, {INPUTxCALL}},
            {IFxSTMT,
              {{BINxOP, "=="}, {SIMPLExVAR, "n"}, {NUMLITxVAL, "99"}},
              {STMTxLIST,
                {ASSNxSTMT, {SIMPLExVAR, "notdone"}, {NUMLITxVAL, "0"}}
              },
              {STMTxLIST,
                {PRINTxSTMT, {SIMPLExVAR, "n"}, {STRLITxOUT, "'\\n'"}}
              }
            }
          }
        },
        {PRINTxSTMT, {STRLITxOUT, "'Bye!\\n'"}}
      }
    input = {"1", "8", "-17", "13.5", "99"}
    statein = deepcopy(emptystate)
    expoutput = {"1", "\n", "8", "\n", "-17", "\n", "13", "\n",
      "Bye!\n"}
    expstateout = {v={["notdone"]=0, ["n"]=99}, a={}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "While loop - read with sentinel")
end


function test_return(t)
    io.write("Test Suite: returning a value\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Writing a return value
    ast =
      {STMTxLIST,
        {FUNCxDEF, "sq",
          {STMTxLIST,
            {RETURNxSTMT,
              {{BINxOP, "*"}, {SIMPLExVAR, "a"}, {SIMPLExVAR, "a"}}
            }
          }
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {NUMLITxVAL, "7"}
        },
        {PRINTxSTMT,
          {FUNCxCALL, "sq"},
          {STRLITxOUT, "'\\n'"}
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"49","\n"}
    expstateout = {v={["a"]=7,["return"]=49}, a={}, f={["sq"]=
      {STMTxLIST, {RETURNxSTMT, {{BINxOP, "*"}, {SIMPLExVAR, "a"},
      {SIMPLExVAR, "a"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Writing a return value")

    -- Assigning a return value
    ast =
      {STMTxLIST,
        {FUNCxDEF, "sq",
          {STMTxLIST,
            {RETURNxSTMT,
              {{BINxOP, "*"}, {SIMPLExVAR, "a"}, {SIMPLExVAR, "a"}}
            }
          }
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {NUMLITxVAL, "7"}
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "c"},
          {FUNCxCALL, "sq"}
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=7,["c"]=49,["return"]=49}, a={}, f={["sq"]=
      {STMTxLIST, {RETURNxSTMT, {{BINxOP, "*"}, {SIMPLExVAR, "a"},
      {SIMPLExVAR, "a"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Assigning a return value")

    -- Returning a return value
    ast =
      {STMTxLIST,
        {FUNCxDEF, "p",
          {STMTxLIST,
            {RETURNxSTMT,
              {{BINxOP, "+"}, {SIMPLExVAR, "a"}, {NUMLITxVAL, "2"}}
            }
          }
        },
        {FUNCxDEF, "sq2",
          {STMTxLIST,
            {RETURNxSTMT,
              {{BINxOP, "*"}, {FUNCxCALL, "p"}, {FUNCxCALL, "p"}}
            }
          }
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {NUMLITxVAL, "7"}
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "c"},
          {FUNCxCALL, "sq2"}
        }
          }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=7,["c"]=81,["return"]=81}, a={}, f={["p"]=
      {STMTxLIST, {RETURNxSTMT, {{BINxOP, "+"}, {SIMPLExVAR, "a"},
      {NUMLITxVAL, "2"}}}},["sq2"]={STMTxLIST, {RETURNxSTMT,
      {{BINxOP, "*"}, {FUNCxCALL, "p"}, {FUNCxCALL, "p"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Returning a return value")

    -- Returning a value that is not used
    ast =
      {STMTxLIST,
        {FUNCxDEF, "sq",
          {STMTxLIST,
            {RETURNxSTMT,
              {{BINxOP, "*"}, {SIMPLExVAR, "a"}, {SIMPLExVAR, "a"}}
            }
          }
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {NUMLITxVAL, "7"}
        },
        {FUNCxCALL, "sq"},
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["a"]=7,["return"]=49}, a={}, f={["sq"]=
      {STMTxLIST, {RETURNxSTMT, {{BINxOP, "*"}, {SIMPLExVAR, "a"},
      {SIMPLExVAR, "a"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Returning a value that is not used")

    -- Using a return value when nothing is returned
    ast =
      {STMTxLIST,
        {FUNCxDEF, "f",
          {STMTxLIST,
            {ASSNxSTMT,
              {SIMPLExVAR, "b"},
              {{BINxOP, "*"}, {SIMPLExVAR, "a"}, {SIMPLExVAR, "a"}}
            }
          }
        },
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {NUMLITxVAL, "7"}
        },
        {PRINTxSTMT,
          {FUNCxCALL, "f"},
          {STRLITxOUT, "'\\n'"}
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"0","\n"}
    expstateout = {v={["a"]=7,["b"]=49}, a={}, f={["f"]=
      {STMTxLIST, {ASSNxSTMT, {SIMPLExVAR, "b"}, {{BINxOP, "*"},
      {SIMPLExVAR, "a"}, {SIMPLExVAR, "a"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Using a return value when nothing is returned")

    -- Using a previous return value
    ast =
      {STMTxLIST,
        {FUNCxDEF, "f",
          {STMTxLIST,
            {RETURNxSTMT,
              {NUMLITxVAL, "8"}
            }
          }
        },
        {FUNCxDEF, "g",
          {STMTxLIST,
            {PRINTxSTMT,
              {STRLITxOUT, "'x'"}
            }
          }
        },
        {FUNCxCALL, "f"},
        {ASSNxSTMT,
          {SIMPLExVAR, "a"},
          {FUNCxCALL, "g"}
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"x"}
    expstateout = {v={["a"]=8,["return"]=8}, a={}, f={["f"]={STMTxLIST,
      {RETURNxSTMT, {NUMLITxVAL, "8"}}}, ["g"]={STMTxLIST, {PRINTxSTMT,
      {STRLITxOUT, "'x'"}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Using a previous return value")
end


function test_fancy(t)
    io.write("Test Suite: fancy programs\n")

    local ast, statein, expoutput, expstateout
    local emptystate = {v={}, a={}, f={}}

    -- Recursion
    ast =
      {STMTxLIST,
        {FUNCxDEF, "x",
          {STMTxLIST,
            {PRINTxSTMT, {SIMPLExVAR, "c"}},
            {ASSNxSTMT,
              {SIMPLExVAR, "c"},
              {{BINxOP, "-"}, {SIMPLExVAR, "c"}, {NUMLITxVAL, "1"}}
            },
            {IFxSTMT,
              {{BINxOP, ">"}, {SIMPLExVAR, "c"}, {NUMLITxVAL, "0"}},
              {STMTxLIST, {FUNCxCALL, "x"}}
            }
          }
        },
        {ASSNxSTMT, {SIMPLExVAR, "c"}, {NUMLITxVAL, "3"}},
        {FUNCxCALL, "x"}
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"3", "2", "1"}
    expstateout = {v={["c"]=0}, a={}, f={["x"]=
      {STMTxLIST, {PRINTxSTMT, {SIMPLExVAR, "c"}},
      {ASSNxSTMT, {SIMPLExVAR, "c"},
      {{BINxOP, "-"}, {SIMPLExVAR, "c"}, {NUMLITxVAL, "1"}}},
      {IFxSTMT, {{BINxOP, ">"}, {SIMPLExVAR, "c"}, {NUMLITxVAL, "0"}},
      {STMTxLIST, {FUNCxCALL, "x"}}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Recursion")

    -- Using complex expression as array index
    ast =
      {STMTxLIST,
        {ASSNxSTMT,
          {SIMPLExVAR, "i"},
          {NUMLITxVAL, "0"}
        },
        {WHILExSTMT,
          {{BINxOP, "<"},
            {SIMPLExVAR, "i"},
            {NUMLITxVAL, "100"}
          },
          {STMTxLIST,
            {ASSNxSTMT,
              {ARRAYxVAR,
                "a",
                {{BINxOP, "=="},
                  {{BINxOP, "%"},
                    {SIMPLExVAR, "i"},
                    {NUMLITxVAL, "3"}
                  },
                  {NUMLITxVAL, "0"}
                }
              },
              {{BINxOP, "+"},
                {ARRAYxVAR,
                  "a",
                  {{BINxOP, "=="},
                    {{BINxOP, "%"},
                      {SIMPLExVAR, "i"},
                      {NUMLITxVAL, "3"}
                    },
                    {NUMLITxVAL, "0"}
                  }
                },
                {NUMLITxVAL, "1"}
              }
            },
            {ASSNxSTMT,
              {SIMPLExVAR, "i"},
              {{BINxOP, "+"},
                {SIMPLExVAR, "i"},
                {NUMLITxVAL, "1"}
              }
            }
          }
        }
      }
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {}
    expstateout = {v={["i"]=100}, a={["a"]={[0]=66,[1]=34}}, f={}}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Using complex expression as array index")

    -- Fibonacci example
    ast =
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
        {NUMLITxVAL,"1"}}}}}}
    input = {}
    statein = deepcopy(emptystate)
    expoutput = {"Fibonacci Numbers\n",
                 "F(", "0", ") = ", "0", "\n",
                 "F(", "1", ") = ", "1", "\n",
                 "F(", "2", ") = ", "1", "\n",
                 "F(", "3", ") = ", "2", "\n",
                 "F(", "4", ") = ", "3", "\n",
                 "F(", "5", ") = ", "5", "\n",
                 "F(", "6", ") = ", "8", "\n",
                 "F(", "7", ") = ", "13", "\n",
                 "F(", "8", ") = ", "21", "\n",
                 "F(", "9", ") = ", "34", "\n",
                 "F(", "10", ") = ", "55", "\n",
                 "F(", "11", ") = ", "89", "\n",
                 "F(", "12", ") = ", "144", "\n",
                 "F(", "13", ") = ", "233", "\n",
                 "F(", "14", ") = ", "377", "\n",
                 "F(", "15", ") = ", "610", "\n",
                 "F(", "16", ") = ", "987", "\n",
                 "F(", "17", ") = ", "1597", "\n",
                 "F(", "18", ") = ", "2584", "\n",
                 "F(", "19", ") = ", "4181", "\n"}
    expstateout = {["v"]={["return"]=4181,["j"]=20,["i"]=19,
      ["tmp"]=6765,["next_fibo"]=6765,["n"]=19,["curr_fibo"]=4181,
      ["how_many_to_print"]=20},["a"]={},["f"]={["fibo"]=
        {STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"curr_fibo"},
          {NUMLITxVAL,"0"}},{ASSNxSTMT,{SIMPLExVAR,"next_fibo"},
          {NUMLITxVAL,"1"}},{ASSNxSTMT,{SIMPLExVAR,"i"},
          {NUMLITxVAL,"0"}},{WHILExSTMT,{{BINxOP,"<"},{SIMPLExVAR,"i"},
          {SIMPLExVAR,"n"}},{STMTxLIST,{ASSNxSTMT,{SIMPLExVAR,"tmp"},
          {{BINxOP,"+"},{SIMPLExVAR,"curr_fibo"},
          {SIMPLExVAR,"next_fibo"}}},{ASSNxSTMT,
          {SIMPLExVAR,"curr_fibo"},{SIMPLExVAR,"next_fibo"}},
          {ASSNxSTMT,{SIMPLExVAR,"next_fibo"},{SIMPLExVAR,"tmp"}},
          {ASSNxSTMT,{SIMPLExVAR,"i"},{{BINxOP,"+"},{SIMPLExVAR,"i"},
          {NUMLITxVAL,"1"}}}}},{RETURNxSTMT,{SIMPLExVAR,"curr_fibo"}}}
    }}
    checkInterp(t, ast, input, statein, expoutput, expstateout,
      "Fibonacci example")
end


function test_interpit(t)
    io.write("TEST SUITES FOR MODULE interpit\n")
    test_pre_written(t)
    test_simple(t)
    test_state(t)
    test_special_chars(t)
    test_expr(t)
    test_intconv(t)
    test_if(t)
    test_while(t)
    test_return(t)
    test_fancy(t)
end


-- *********************************************************************
-- Main Program
-- *********************************************************************


test_interpit(tester)
io.write("\n")
endMessage(tester:allPassed())

-- Wait for user
io.write("\nPress ENTER to quit ")
io.read("*l")

