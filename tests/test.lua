#!/usr/bin/env lua

versionnum = tonumber(_VERSION:match('%d%.%d'))

matchext = require 'matchext'

-- Make sure all functions are present
assert(matchext.find)
assert(matchext.match)
assert(matchext.gmatch)
assert(matchext.gsub)
assert(matchext.monkeypatch)

-- Centralized listing of values for tests, for easy re-use and maintenance
vals = {
    B = {
        str = 'test(test%)testB)test',
        patt = '%B(%)',
        result = '(test%)testB)'
    }
}

-- Test %B balancing with escape character
assert(matchext.match(vals.B.str, vals.B.patt) == vals.B.result)
-- Stock match should throw error for unfinished capture group
assert(not pcall(string.match, vals.B.str, vals.B.patt))


-- This is where the fun begins :)
matchext.monkeypatch()

-- Assert that stock functions are present in "original" sub-table
assert(string.original)
assert(string.original.find)
assert(string.original.match)
assert(string.original.gmatch)
assert(string.original.gsub)

-- Test that functions were properly copied
-- For some reason, Lua 5.1 makes copies of the functions rather than
-- pointing to the same instance, so run this only on 5.2 and higher
if versionnum >= 5.2 then
    assert(string.find == matchext.find)
    assert(string.match == matchext.match)
    assert(string.gmatch == matchext.gmatch)
    assert(string.gsub == matchext.gsub)
end

-- Ensure that string.match now handles new features...
assert(vals.B.str:match(vals.B.patt) == vals.B.result)

-- ...and that functions in string.original do not
assert(not pcall(string.original.match, vals.B.str, vals.B.patt))
