# matchext

Fork of Lua 5.3's pattern matching library with some added features.

## Installation

```
luarocks install matchext
```

## Documentation

The complete pattern-matching facilities are not described here; for that, see the [official Lua 5.3 reference manual "String Manipulation" section](http://www.lua.org/manual/5.3/manual.html#6.4), specifically the functions `find`, `match`, `gmatch`, and `gsub`, and the "Patterns" sub-section. This library provides those same four functions with the same signatures and with all of the same behavior except for the added feature(s) listed below; additionally, the library provides extra functions, which are described in full below.

### Additional features in the four basic functions

#### Balanced pattern with escape (`%Bxyz`)
The pattern token `%Bxyz` acts like the stock `%bxz`, matching a balanced pair of the opening character `x` and the closing character `z`, but adds the feature of the middle character `y` acting as an escape character, where each instance of `y` in the source string causes the next character in the source string to be skipped. Thus, `%B(%)` will match `(foo%)bar)` in `test(foo%)bar)baz`. As seen in this example, all three arguments to the `%B` token are interpreted raw; that is, all three represent themselves and do not carry any of the special meanings normally associated with them in pattern matching. (The same is true of the two arguments to the stock `%b` token.)

### Extra functions

#### matchext.tmatch(s, pattern [, init])
Behaves the same as `matchext.match()`, but on a successful match, returns a table. This table contains any captures as a sequence (each at the index matching the order of returns from the stock `match()`), plus the entire match at index 0. Fields `startpos` and `endpos` are each a subtable containing the start and end positions, respectively, for each capture (the start and end position for a position capture is simply the value of that capture), as well as for the entire match at index 0. The table also contains the fields `source`, which contains the string over which the match was performed, and `pattern`, which contains the pattern used to perform the match. The table has one method, `:expand(repl)`, which performs `gsub`-style expansion of `repl` (which must be a string) based on the captures in the table.

#### matchext.tgmatch(s, pattern)
Behaves the same as `matchext.gmatch()`, but on each iteration, produces a single table, which is the same as the table described for `matchext.tmatch()` above.

#### matchext.tgsub(s, pattern, repl [, n])
Behaves the same as `matchext.gsub()` unless `repl` is a function. In that case, the `repl` function receives just a single argument, which is the table described for `matchext.tmatch()` above. If `repl` is a string or table, then it behaves exactly the same as `matchext.gsub()`, and you should probably use that instead.

#### matchext.monkeypatch()
`require 'matchext'` does not touch the standard library's `string` table; it simply returns a table of its own functions, like a well-behaved Lua library should. For those who want to use this library's functions as methods of strings, or who otherwise want to get their hands dirty, running `monkeypatch` will take all of this library's functions except itself and insert them into the `string` table. It will also create a subtable at `string.original`, into which the stock `find`, `match`, `gmatch`, and `gsub` functions will be moved to preserve them (although they will no longer be usable as methods).

## License

As a fork of the MIT-licensed Lua core, this library is also licensed under the MIT license. See the `LICENSE` file for more details.
