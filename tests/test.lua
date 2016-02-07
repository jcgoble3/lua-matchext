#!/usr/bin/env lua

require 'busted.runner'()

versionnum = tonumber(_VERSION:match('%d%.%d'))

matchext = require 'matchext'

-- Centralized listing of values for tests, for easy re-use and maintenance
vals = {}

vals.B = {
    str = 'test(test%)testB)test',
    patt = '%B(%)',
    result = '(test%)testB)'
}

vals.TM = {
    str = 'abcdefg',
    patt = 'b(c(d))e()f',
    result = {
        [0] = 'bcdef', 'cd', 'd', 6;
        startpos = {[0] = 2, 3, 4, 6};
        endpos = {[0] = 6, 4, 4, 6}
    }
}
vals.TM.result.source = vals.TM.str
vals.TM.result.pattern = vals.TM.patt

vals.TGM = {
    str = 'This is a test (hello)',
    patt = '(%a)%a*()',
    results = {
        {[0]='This', 'T', 5; startpos = {[0]=1, 1, 5}; endpos = {[0]=4, 1, 5}},
        {[0]='is', 'i', 8; startpos = {[0]=6, 6, 8}; endpos = {[0]=7, 6, 8}},
        {[0]='a', 'a', 10; startpos = {[0]=9, 9, 10}; endpos = {[0]=9, 9, 10}},
        {[0]='test', 't', 15; startpos = {[0]=11, 11, 15}; endpos = {[0]=14, 11, 15}},
        {[0]='hello', 'h', 22; startpos = {[0]=17, 17, 22}; endpos = {[0]=21, 17, 22}}
    }
}
for i, t in ipairs(vals.TGM.results) do
    t.source = vals.TGM.str
    t.pattern = vals.TGM.patt
end

vals.TGS = {
    str = 'abcdefg',
    patt = 'b(c(d))e()f',
    result = 'abcdef;cd;d;6::b(c(d))e()f!abcdefg-2:6g'
}

vals.EXP = {
    str = 'abcdefg',
    patt = 'b(c(d))e()f',
    result = '0=bcdef;1=cd;2=d;3=6'
}


describe('All tests:', function()
    it('Make sure functions are present', function()
        assert.is_function(matchext.find)
        assert.is_function(matchext.match)
        assert.is_function(matchext.gmatch)
        assert.is_function(matchext.gsub)
        assert.is_function(matchext.tmatch)
        assert.is_function(matchext.tgmatch)
        assert.is_function(matchext.tgsub)
        assert.is_function(matchext.monkeypatch)
    end)

    it('Test %B balancing with escape character', function()
        assert.equal(matchext.match(vals.B.str, vals.B.patt), vals.B.result)
    end)

    it('Stock match should throw error for unfinished capture', function()
        assert.error(function() vals.B.str:match(vals.B.patt) end)
    end)

    it('Table match test', function()
        assert.same(
            matchext.tmatch(vals.TM.str, vals.TM.patt),
            vals.TM.result
        )
    end)

    it('Table gmatch iteration', function()
        local results = {}
        for match in matchext.tgmatch(vals.TGM.str, vals.TGM.patt) do
            results[#results + 1] = match
        end
        assert.same(results, vals.TGM.results)
    end)

    it('Table gsub', function()
        local function callback(match)
            local t = {match[0], ';', match[1], ';', match[2], ';', match[3],
                       '::', match.pattern, '!', match.source, '-',
                       match.startpos[0], ':', match.endpos[0]}
            return table.concat(t)
        end
        assert.equal(
            matchext.tgsub(vals.TGS.str, vals.TGS.patt, callback),
            vals.TGS.result
        )
    end)

    it('Match table expand method', function()
        local match = matchext.tmatch(vals.EXP.str, vals.EXP.patt)
        assert.equal(match:expand('0=%0;1=%1;2=%2;3=%3'), vals.EXP.result)
        assert.error(function() match:expand('%4') end)
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
        assert.is_function(string.tmatch)
        assert.is_function(string.tgmatch)
        assert.is_function(string.tgsub)
    end)

    it('String.match should now handle %B', function()
        assert.has_no.errors(function() vals.B.str:match(vals.B.patt) end)
        assert.equal(vals.B.str:match(vals.B.patt), vals.B.result)
    end)

    it('Functions in string.original should still error on %b', function()
        assert.error(function()
            string.original.match(vals.B.str, vals.B.patt)
        end)
    end)
end)
