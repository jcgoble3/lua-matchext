--[[
constant.lua

Copyright 2017 Jonathan Goble <jcgoble3@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Whenever the opcodes in this file change, you must run the
-- genconst.lua script to regenerate constant.h.

local const = {}
local n = 0

local opcodestr = [[
    FAILURE
    SUCCESS
    ANY
    LITERAL
    NOTLITERAL
    CATEGORY
    RANGE
    NOTRANGE
    SET
    FRONTIER
    BALANCE
    AT
    CAPTURE
    ENDCAPTURE
    CAPTUREPOS
    BACKREFERENCE

    SINGLEREPEAT
    SINGLELAZY
    SINGLEPOSSESSIVE
    GROUPREPEAT
    GROUPLAZY
    GROUPPOSSESSIVE
    BRANCH
    JUMP
]]

for name in string.gmatch(opcodestr, '%w+') do
    n = n + 1
    name = 'OP_' .. name
    const[n] = name
    const[name] = n
end

local categorylist = [[
    LETTER
    CONTROL
    DIGIT
    PRINTABLE
    LOWERCASE
    PUNCTUATION
    SPACE
    UPPERCASE
    ALPHANUMERIC
    HEXADECIMAL
]]

for name in string.gmatch(categorylist, '%w+') do
    n = n + 1
    name = 'CATEGORY_' .. name
    const[n] = name
    const[name] = n
end

local atlist = [[
    STARTSTRING
    ENDSTRING
    STARTLINE
    ENDLINE
]]

for name in string.gmatch(atlist, '%w+') do
    n = n + 1
    name = 'AT_' .. name
    const[n] = name
    const[name] = n
end

-- This value will be used as a dummy argument to OP_BALANCE to indicate
-- no escape character. Its value is arbitrary, but cannot be a valid
-- Unicode codepoint, thus it must be < 0 or > 0x10FFFF (1,114,111).
const.NOESCAPE = -1
const[-1] = 'NOESCAPE'
const.ENDOFSTRING = -2
const[-2] = 'ENDOFSTRING'

return const
