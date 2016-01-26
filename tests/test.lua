#!/usr/bin/env lua

require 'busted.runner'()

versionnum = tonumber(_VERSION:match('%d%.%d'))

matchext = require 'matchext'

-- Centralized listing of values for tests, for easy re-use and maintenance
vals = {
    B = {
        str = 'test(test%)testB)test',
        patt = '%B(%)',
        result = '(test%)testB)'
    }
}

describe('All tests:', function()
    it('Make sure functions are present', function()
        assert.is_function(matchext.find)
        assert.is_function(matchext.match)
        assert.is_function(matchext.gmatch)
        assert.is_function(matchext.gsub)
        assert.is_function(matchext.monkeypatch)
    end)

    it('Test %B balancing with escape character', function()
        assert.equal(matchext.match(vals.B.str, vals.B.patt), vals.B.result)
    end)

    it('Stock match should throw error for unfinished capture', function()
        assert.error(function() vals.B.str:match(vals.B.patt) end)
    end)

    it('Monkey-patch string module', function()
        assert.has_no.errors(matchext.monkeypatch)
    end)

    it('Stock functions present in "original" sub-table', function()
        assert.is_table(string.original)
        assert.is_function(string.original.find)
        assert.is_function(string.original.match)
        assert.is_function(string.original.gmatch)
        assert.is_function(string.original.gsub)
    end)

    -- For some reason, Lua 5.1 makes copies of the functions rather than
    -- pointing to the same instance, so run this only on 5.2 and higher
    it('Test that functions were properly copied', function()
        if versionnum >= 5.2 then
            assert.equal(string.find, matchext.find)
            assert.equal(string.match, matchext.match)
            assert.equal(string.gmatch, matchext.gmatch)
            assert.equal(string.gsub, matchext.gsub)
        end
    end)

    it('String.match should now handles new features', function()
        assert.has_no.errors(function() vals.B.str:match(vals.B.patt) end)
        assert.equal(vals.B.str:match(vals.B.patt), vals.B.result)
    end)

    it('Functions in string.original should still error', function()
        assert.error(function()
            string.original.match(vals.B.str, vals.B.patt)
        end)
    end)
end)
