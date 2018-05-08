/*
 * enhanced.c
 *
 * Copyright 2017 Jonathan Goble <jcgoble3@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <ctype.h>
#include <string.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

#include "constant.h"

/* Define an integer type that is (hopefully) exactly 32 bits. */
#if LUAI_BITSINT >= 32
typedef int int32;
#else
typedef long int32;
#endif

typedef enum bool {
    false, true
} bool;

typedef struct PatternInfo {
    int captures;
    int flags;
    bool utf8;
    int codes[1];
} PatternInfo;

typedef struct CaptureInfo {
    int* start;
    int* end;
    int startbt;
    int endbt;
    bool started;
    bool ended;
} CaptureInfo;

typedef struct MatchInfo {
    PatternInfo* pattern;
    int32* source;
    int btluastack;  /* index to table on Lua stack */
    int btcount;
    CaptureInfo captures[1];
} MatchInfo;

#define VMCONST(name)  LMATCH_##name

#define VMOP(code)  VMCONST(OP_##code)
#define VMAT(code)  VMCONST(AT_##code)
#define VMCAT(code)  VMCONST(CATEGORY_##code)

#define NEXTOP  *(++op)
#define NEXTSRC  *(++src)
#define PEEKSRC  *(src + 1)
#define OP  *op
#define SRC  *src

#define VMCASE(code)  case VMOP(code):
/* this fails when called from inside an inner loop */
#define DISPATCH(code)  continue;
#define BACKTRACK()  fail()

#define FAILONEND() \
    if (NEXTSRC == VMCONST(ENDOFSTRING)) BACKTRACK();

#define CATCASE(code, func) \
    case VMCAT(code): result = func(SRC); break;

#define FRONTIERNONMATCH 0
#define FRONTIERMATCH 1
#define NOTFRONTIER 2

#define INTERNALERROR  \
    return luaL_error(L, "pattern matching internal error")

static int matchvm(lua_State* L, MatchInfo *mi) {
    int32 OP = mi->pattern->codes;
    int32 SRC = mi->source;
    int frontstatus = NOTFRONTIER;
    while (OP != VMCONST(ENDOFSTRING)) {
        switch (OP) {
            VMCASE(ANY) {
                FAILONEND();
                DISPATCH(NEXTOP);
            }
            VMCASE(LITERAL) {
                if (NEXTSRC == NEXTOP)
                    DISPATCH(NEXTOP);
                BACKTRACK();
            }
            VMCASE(NOTLITERAL) {
                FAILONEND();
                if (SRC != NEXTOP)
                    DISPATCH(NEXTOP);
                BACKTRACK();
            }
            VMCASE(CATEGORY) {
                bool result;
                FAILONEND();
                if (SRC > 0xFF)
                    result = false;
                switch(NEXTOP) {
                    CATCASE(LETTER, isalpha)
                    CATCASE(CONTROL, iscntrl)
                    CATCASE(DIGIT, isdigit)
                    CATCASE(PRINTABLE, isgraph)
                    CATCASE(LOWERCASE, islower)
                    CATCASE(PUNCTUATION, ispunct)
                    CATCASE(SPACE, isspace)
                    CATCASE(UPPERCASE, isupper)
                    CATCASE(ALPHANUMERIC, isalnum)
                    CATCASE(HEXADECIMAL, isxdigit)
                    default: INTERNALERROR;
                }
                if (result == NEXTOP)
                    DISPATCH(NEXTOP);
                BACKTRACK();
            }
            VMCASE(RANGE) {
                int32 s;
                int32 low = NEXTOP;
                FAILONEND();
                s = SRC;
                if (low <= s && s <= NEXTOP)
                    DISPATCH(NEXTOP);
                BACKTRACK();
            }
            VMCASE(NOTRANGE) {
                int32 s;
                int32 low = NEXTOP;
                FAILONEND();
                s = SRC;
                if (s < low || NEXTOP < s)
                    DISPATCH(NEXTOP);
                BACKTRACK();
            }
            VMCASE(FRONTIER) {
                frontstatus = FRONTIERNONMATCH;
                if (SRC == VMCONST(ENDOFSTRING))
                    BACKTRACK();
                /* FALLTHROUGH */
            }
            VMCASE(SET) {
                int32* pos = op;
                bool type = NEXTOP;
                int32 jump = NEXTOP;
                int32* next = op + jump;
                bool match;
                frontround2:
                if (frontstatus != FRONTIERNONMATCH)
                    FAILONEND();
                while (true) {
                    switch (NEXTOP) {
                        case VMOP(LITERAL): {
                            if (NEXTOP == SRC) {
                                match = true; goto finishset;
                            }
                            continue;
                        }
                        case VMOP(CATEGORY): {
                            bool result;
                            if (SRC > 0xFF)
                                result = false;
                            switch (NEXTOP) {
                                CATCASE(LETTER, isalpha)
                                CATCASE(CONTROL, iscntrl)
                                CATCASE(DIGIT, isdigit)
                                CATCASE(PRINTABLE, isgraph)
                                CATCASE(LOWERCASE, islower)
                                CATCASE(PUNCTUATION, ispunct)
                                CATCASE(SPACE, isspace)
                                CATCASE(UPPERCASE, isupper)
                                CATCASE(ALPHANUMERIC, isalnum)
                                CATCASE(HEXADECIMAL, isxdigit)
                                default: INTERNALERROR;
                            }
                            if (result == NEXTOP) {
                                match == true; goto finishset;
                            }
                            continue;
                        }
                        case VMOP(RANGE): {
                            int32 s = SRC;
                            int32 low = NEXTOP;
                            if (low <= s && s <= NEXTOP) {
                                match = true; goto finishset;
                            }
                            continue;
                        }
                        case VMOP(FAILURE): {
                            match = false; goto finishset;
                        }
                        default: INTERNALERROR;
                    }
                }
                finishset:
                switch (frontstatus) {
                    case FRONTIERMATCH: {
                        frontstatus = NOTFRONTIER;
                        src--;
                        /* FALLTHROUGH */
                    }
                    case NOTFRONTIER: {
                        if (match == type) {
                            op = next;
                            DISPATCH(OP);
                        }
                        BACKTRACK();
                    }
                    case FRONTIERNONMATCH: {
                        if (match != type) {
                            frontstatus = FRONTIERMATCH;
                            op = pos;
                            goto frontround2;
                        }
                        frontstatus = NOTFRONTIER;
                        BACKTRACK();
                    }
                    default: INTERNALERROR;
                }
            }
            VMCASE(BALANCE) {
                int32 start = NEXTOP;
                FAILONEND();
                if (start != NEXTSRC)
                    BACKTRACK();
                else {
                    int32 end = NEXTOP;
                    int32 escape = NEXTOP;
                    int32 level = 1;
                    while (NEXTSRC != VMCONST(ENDOFSTRING)) {
                        if (SRC == escape) {
                            if (NEXTSRC == VMCONST(ENDOFSTRING))
                                BACKTRACK();
                        }
                        else if (SRC == end) {
                            if (--level == 0)
                                DISPATCH(NEXTOP);
                        }
                        else if (SRC == start)
                            level++;
                    }
                    BACKTRACK();
                }
            }
            VMCASE(AT) {
                switch (NEXTOP) {
                    case VMAT(STARTLINE): {
                        if (SRC == '\n')
                            DISPATCH(NEXTOP);
                        /* FALLTHROUGH */
                    }
                    case VMAT(STARTSTRING): {
                        if (SRC == VMCONST(ENDOFSTRING))
                            DISPATCH(NEXTOP);
                        break;
                    }
                    case VMAT(ENDLINE): {
                        if (PEEKSRC == '\n')
                            DISPATCH(NEXTOP);
                        /* FALLTHROUGH */
                    }
                    case VMAT(ENDSTRING): {
                        if (PEEKSRC == VMCONST(ENDOFSTRING))
                            DISPATCH(NEXTOP);
                        break;
                    }
                }
                BACKTRACK();
            }
            default: INTERNALERROR;
        }
    }
}
