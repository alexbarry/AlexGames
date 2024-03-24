local puzzles = {}

local core = require("games/crossword_letters/crossword_letters_core")

puzzles.puzzles = {

--+------------+
--|other  shot |
--|t       o   |
--|h       rest|
--|e t   r s o |
--|r h shore r |
--|short s   t |
--|  s o e  s  |
--|  e r   toes|
--|   hers  r  |
--|hero  hose  |
--|   s  o     |
--|   t  e     |
--+------------+
--
{
	letters = {"r", "e", "s", "t", "o", "h"},
	word_positions = {
		{ word = "others"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "hero"              , pos = { y = 10, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "toes"              , pos = { y =  8, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y =  4, x =  7 }, orientation = core.VERTICAL    },
		{ word = "rest"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "shore"             , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "store"             , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "host"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "other"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "sort"              , pos = { y =  3, x = 11 }, orientation = core.VERTICAL    },
		{ word = "those"             , pos = { y =  4, x =  3 }, orientation = core.VERTICAL    },
		{ word = "shot"              , pos = { y =  1, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "shoe"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "sore"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "hose"              , pos = { y = 10, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "short"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "hers"              , pos = { y =  9, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "horse"             , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|moral   meal|
--|o e  r  a  a|
--|real oral  m|
--|a l  l  e  e|
--|l more m    |
--|e   o  are  |
--|    a  r r  |
--|    mole arm|
--|      o     |
--|      r     |
--|   aloe     |
--|            |
--+------------+
--
{
	letters = {"e", "m", "r", "o", "l", "a"},
	word_positions = {
		{ word = "mole"              , pos = { y =  8, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "lame"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "oral"              , pos = { y =  3, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "real"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "male"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "are"               , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "moral"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lore"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "more"              , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "era"               , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "realm"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "arm"               , pos = { y =  8, x = 10 }, orientation = core.HORIZONTAL  },
		{ word = "roam"              , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "meal"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "aloe"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "role"              , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "mare"              , pos = { y =  5, x =  8 }, orientation = core.VERTICAL    },
		{ word = "morale"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|f  h    heat|
--|after   a   |
--|t  a    r   |
--|h  r fare   |
--|earth  a f  |
--|r   a  frat |
--|    t  t t f|
--|   hear fear|
--|    r a e  e|
--|      tear t|
--|   hate t   |
--|            |
--+------------+
--
{
	letters = {"a", "h", "f", "t", "e", "r"},
	word_positions = {
		{ word = "after"             , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "hare"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fare"              , pos = { y =  4, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "father"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "raft"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "fret"              , pos = { y =  7, x = 12 }, orientation = core.VERTICAL    },
		{ word = "hate"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "feat"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
		{ word = "earth"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "fate"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "heat"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "tear"              , pos = { y = 10, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "heart"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "rate"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "hater"             , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "fear"              , pos = { y =  8, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "frat"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "hear"              , pos = { y =  8, x =  4 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|heard  herd |
--|e  e   a  a |
--|r hard d  r |
--|a  l e   her|
--|l    a   a  |
--|d  held  r  |
--|   e  e heal|
--| read are  e|
--|   d  r a  a|
--|        r  d|
--|            |
--|            |
--+------------+
--
{
	letters = {"r", "a", "h", "e", "d", "l"},
	word_positions = {
		{ word = "her"               , pos = { y =  4, x = 10 }, orientation = core.HORIZONTAL  },
		{ word = "dear"              , pos = { y =  6, x =  7 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y =  1, x = 11 }, orientation = core.VERTICAL    },
		{ word = "held"              , pos = { y =  6, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "real"              , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "herald"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "heard"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "are"               , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "head"              , pos = { y =  6, x =  4 }, orientation = core.VERTICAL    },
		{ word = "hard"              , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "had"               , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "hear"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "read"              , pos = { y =  8, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "herd"              , pos = { y =  1, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "lead"              , pos = { y =  7, x = 12 }, orientation = core.VERTICAL    },
		{ word = "hare"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "deal"              , pos = { y =  3, x =  6 }, orientation = core.VERTICAL    },
		{ word = "heal"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|merit  trim |
--|e   e  i    |
--|timer  rite |
--|r   mice  m |
--|i t   i   i |
--|crime t mite|
--|  m   e e   |
--|item    t   |
--| i  i       |
--| e  c       |
--| rice       |
--|            |
--+------------+
--
{
	letters = {"m", "r", "i", "e", "c", "t"},
	word_positions = {
		{ word = "crime"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "time"              , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "mite"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "term"              , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "metric"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "timer"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tire"              , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "mice"              , pos = { y =  4, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rice"              , pos = { y = 11, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "item"              , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "merit"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ice"               , pos = { y =  9, x =  5 }, orientation = core.VERTICAL    },
		{ word = "trim"              , pos = { y =  1, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "cite"              , pos = { y =  4, x =  7 }, orientation = core.VERTICAL    },
		{ word = "met"               , pos = { y =  6, x =  9 }, orientation = core.VERTICAL    },
		{ word = "emit"              , pos = { y =  3, x = 11 }, orientation = core.VERTICAL    },
		{ word = "tier"              , pos = { y =  8, x =  2 }, orientation = core.VERTICAL    },
		{ word = "rite"              , pos = { y =  3, x =  8 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|break  b b  |
--|a    brake  |
--|care a c a  |
--|k a  k k r  |
--|e cake      |
--|r e  rack   |
--|   b  c   b |
--|   a  r   e |
--|  brace r c |
--|   e r bark |
--|     a  k   |
--|     bake   |
--+------------+
--
{
	letters = {"b", "c", "a", "k", "e", "r"},
	word_positions = {
		{ word = "bear"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "acre"              , pos = { y =  6, x =  7 }, orientation = core.VERTICAL    },
		{ word = "cake"              , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "bake"              , pos = { y = 12, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "baker"             , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "brace"             , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "rack"              , pos = { y =  6, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "backer"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "brake"             , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "race"              , pos = { y =  3, x =  3 }, orientation = core.VERTICAL    },
		{ word = "rake"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "bare"              , pos = { y =  7, x =  4 }, orientation = core.VERTICAL    },
		{ word = "break"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "back"              , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "crab"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "bark"              , pos = { y = 10, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "beck"              , pos = { y =  7, x = 11 }, orientation = core.VERTICAL    },
		{ word = "care"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|votes       |
--|o     t  r  |
--|t  overs o  |
--|e s o o  s  |
--|r t t vote  |
--|store e o   |
--|  v r   r t |
--|over s veto |
--|v  e o    e |
--|e  sort vest|
--|r  t e      |
--|t           |
--+------------+
--
{
	letters = {"e", "v", "t", "o", "r", "s"},
	word_positions = {
		{ word = "overt"             , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "toes"              , pos = { y =  7, x = 11 }, orientation = core.VERTICAL    },
		{ word = "rose"              , pos = { y =  2, x = 10 }, orientation = core.VERTICAL    },
		{ word = "over"              , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rest"              , pos = { y =  8, x =  4 }, orientation = core.VERTICAL    },
		{ word = "vote"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "overs"             , pos = { y =  3, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "store"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "veto"              , pos = { y =  8, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "voters"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sort"              , pos = { y = 10, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "stove"             , pos = { y =  4, x =  3 }, orientation = core.VERTICAL    },
		{ word = "sore"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "tore"              , pos = { y =  5, x =  9 }, orientation = core.VERTICAL    },
		{ word = "voter"             , pos = { y =  3, x =  5 }, orientation = core.VERTICAL    },
		{ word = "vest"              , pos = { y = 10, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "votes"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "trove"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|cheap       |
--|h      heap |
--|a e pace    |
--|place  a    |
--|e c a clap p|
--|l h c    l a|
--|    help e l|
--|      e lace|
--|     cape   |
--|      c ache|
--|     chap   |
--|            |
--+------------+
--
{
	letters = {"h", "c", "p", "e", "l", "a"},
	word_positions = {
		{ word = "cape"              , pos = { y =  9, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "help"              , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "peach"             , pos = { y =  3, x =  5 }, orientation = core.VERTICAL    },
		{ word = "cheap"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "each"              , pos = { y =  3, x =  3 }, orientation = core.VERTICAL    },
		{ word = "chapel"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "pale"              , pos = { y =  5, x = 12 }, orientation = core.VERTICAL    },
		{ word = "clap"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "plea"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "leap"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
		{ word = "ache"              , pos = { y = 10, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "lace"              , pos = { y =  8, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "heal"              , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "leach"             , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "place"             , pos = { y =  4, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "pace"              , pos = { y =  3, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "chap"              , pos = { y = 11, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "heap"              , pos = { y =  2, x =  8 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|farmed  farm|
--|r    r  a   |
--|a armed deaf|
--|m    a  e  a|
--|e frame  f r|
--|d a     dare|
--|  made   m  |
--|  e e fared |
--|  d a e   a |
--|    read  m |
--|      r   e |
--|            |
--+------------+
--
{
	letters = {"d", "r", "e", "f", "m", "a"},
	word_positions = {
		{ word = "made"              , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "fare"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "famed"             , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "armed"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "fade"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "deaf"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "fared"             , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "dream"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "frame"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "dear"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "fame"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "read"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "dame"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "farmed"            , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "fear"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "framed"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "farm"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|steaks      |
--|t    k s    |
--|a   takes  a|
--|k  e t a   s|
--|e take tasks|
--|s  s s s t e|
--|   t     a t|
--|a    steak  |
--|sets k a e  |
--|k a  a t    |
--|s seat sake |
--|  k  e      |
--+------------+
--
{
	letters = {"t", "a", "s", "s", "e", "k"},
	word_positions = {
		{ word = "steak"             , pos = { y =  8, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "seat"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "skates"            , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "asset"             , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "stakes"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "asks"              , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "tasks"             , pos = { y =  5, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "steaks"            , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "task"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "sake"              , pos = { y = 11, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "skate"             , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "take"              , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "eats"              , pos = { y =  8, x =  8 }, orientation = core.VERTICAL    },
		{ word = "sets"              , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "east"              , pos = { y =  4, x =  4 }, orientation = core.VERTICAL    },
		{ word = "stake"             , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "seats"             , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "takes"             , pos = { y =  3, x =  5 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|p u     puts|
--|upset   u  p|
--|r e     r  u|
--|e  s  step r|
--|super u     |
--|t  t  rest  |
--|  purse  r  |
--|   p   r u  |
--|     p user |
--|    pets  u |
--|     s t  s |
--|     t    e |
--+------------+
--
{
	letters = {"s", "e", "t", "r", "u", "p"},
	word_positions = {
		{ word = "use"               , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "sure"              , pos = { y =  4, x =  7 }, orientation = core.VERTICAL    },
		{ word = "step"              , pos = { y =  4, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "rest"              , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "pest"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "purse"             , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "pure"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "spur"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "setup"             , pos = { y =  4, x =  4 }, orientation = core.VERTICAL    },
		{ word = "super"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "pets"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "upset"             , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "user"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "ruse"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "rust"              , pos = { y =  8, x =  8 }, orientation = core.VERTICAL    },
		{ word = "true"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "purest"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "puts"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|flare       |
--|l  e f      |
--|a fared     |
--|r  l r l  d |
--|e   dare  e |
--|deal l a  a |
--|   e   fear |
--| read    r  |
--|   d f fled |
--|     l a  e |
--|     e r  a |
--|    fade  f |
--+------------+
--
{
	letters = {"r", "l", "a", "d", "f", "e"},
	word_positions = {
		{ word = "dear"              , pos = { y =  4, x = 11 }, orientation = core.VERTICAL    },
		{ word = "fare"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "real"              , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "feral"             , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "flare"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "fade"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "deaf"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "fared"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "flared"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "flea"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "are"               , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "read"              , pos = { y =  8, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "deal"              , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lead"              , pos = { y =  6, x =  4 }, orientation = core.VERTICAL    },
		{ word = "fear"              , pos = { y =  7, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "fled"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "leaf"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|finder      |
--|r  i        |
--|i infer  f  |
--|e  e  i  i  |
--|n fried  r  |
--|d i   e fern|
--|  r     i   |
--|fiend finer |
--|i d i i e e |
--|n   r n   i |
--|e  nerd dine|
--|d           |
--+------------+
--
{
	letters = {"d", "i", "f", "e", "n", "r"},
	word_positions = {
		{ word = "dire"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "friend"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "finer"             , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "fined"             , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "fiend"             , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ride"              , pos = { y =  3, x =  7 }, orientation = core.VERTICAL    },
		{ word = "rein"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "find"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "diner"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "infer"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "fired"             , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "finder"            , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "fine"              , pos = { y =  6, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fried"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "dine"              , pos = { y = 11, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "nerd"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "fern"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "fire"              , pos = { y =  3, x = 10 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|laden       |
--|o          l|
--|alone   lane|
--|n       o  a|
--|e  d  loan n|
--|done  e d   |
--| n a  a   a |
--| e land lone|
--|     o  e d |
--|     dean   |
--|  aloe  d   |
--|            |
--+------------+
--
{
	letters = {"o", "l", "n", "e", "d", "a"},
	word_positions = {
		{ word = "done"              , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "alone"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "dean"              , pos = { y = 10, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "lone"              , pos = { y =  8, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "node"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "aloe"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "loan"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "load"              , pos = { y =  3, x =  9 }, orientation = core.VERTICAL    },
		{ word = "one"               , pos = { y =  6, x =  2 }, orientation = core.VERTICAL    },
		{ word = "land"              , pos = { y =  8, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "laden"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lend"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
		{ word = "loaned"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "deal"              , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "lead"              , pos = { y =  5, x =  7 }, orientation = core.VERTICAL    },
		{ word = "lean"              , pos = { y =  2, x = 12 }, orientation = core.VERTICAL    },
		{ word = "lane"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "and"               , pos = { y =  7, x = 11 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|birds b    b|
--|r a airs   i|
--|a i i a arid|
--|i d d i  a s|
--|d s   drab  |
--|s   b    i  |
--|    a bird  |
--| bard a a   |
--| r i  r i   |
--| a bias d   |
--| d s        |
--|            |
--+------------+
--
{
	letters = {"s", "b", "r", "d", "i", "a"},
	word_positions = {
		{ word = "drab"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "raid"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "bars"              , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "ribs"              , pos = { y =  8, x =  4 }, orientation = core.VERTICAL    },
		{ word = "raids"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "bids"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "airs"              , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "birds"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "braid"             , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "bird"              , pos = { y =  7, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "bias"              , pos = { y = 10, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "brad"              , pos = { y =  8, x =  2 }, orientation = core.VERTICAL    },
		{ word = "bard"              , pos = { y =  8, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "arid"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "said"              , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "bad"               , pos = { y =  6, x =  5 }, orientation = core.VERTICAL    },
		{ word = "braids"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "rabid"             , pos = { y =  3, x = 10 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|c curse     |
--|o    c      |
--|u euros     |
--|r    r  c   |
--|source  u  c|
--|e   o   e  u|
--|  cures sour|
--|    e    u e|
--| rouse sore |
--| o   u u s  |
--|user r r    |
--| e  core    |
--+------------+
--
{
	letters = {"u", "e", "r", "c", "o", "s"},
	word_positions = {
		{ word = "cores"             , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "curse"             , pos = { y =  1, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "cures"             , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "score"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "course"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "source"            , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "cues"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "ours"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "euros"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "cure"              , pos = { y =  5, x = 12 }, orientation = core.VERTICAL    },
		{ word = "sour"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "sore"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "user"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rouse"             , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "euro"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "core"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y =  9, x =  2 }, orientation = core.VERTICAL    },
		{ word = "sure"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|cheat       |
--|h    e      |
--|a  leach    |
--|l  a c a l  |
--|e  t h t a  |
--|teach heat l|
--|   h  e  e a|
--|      a    c|
--|    halt the|
--|     c e e  |
--|     h chat |
--|  tale h l  |
--+------------+
--
{
	letters = {"c", "l", "h", "e", "t", "a"},
	word_positions = {
		{ word = "the"               , pos = { y =  9, x = 10 }, orientation = core.HORIZONTAL  },
		{ word = "teach"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "latch"             , pos = { y =  3, x =  4 }, orientation = core.VERTICAL    },
		{ word = "teal"              , pos = { y =  9, x = 10 }, orientation = core.VERTICAL    },
		{ word = "heat"              , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "tale"              , pos = { y = 12, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "each"              , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "tech"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "ache"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "hate"              , pos = { y =  3, x =  8 }, orientation = core.VERTICAL    },
		{ word = "chat"              , pos = { y = 11, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "lace"              , pos = { y =  6, x = 12 }, orientation = core.VERTICAL    },
		{ word = "chalet"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "leach"             , pos = { y =  3, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "cheat"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "late"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "halt"              , pos = { y =  9, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "heal"              , pos = { y =  6, x =  7 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|scale       |
--|c  e        |
--|a  a l   d c|
--|l  deals e a|
--|e  s c laces|
--|d c  e a a e|
--|  lead d l  |
--|  a    e    |
--|  deal  l s |
--|     a  aces|
--|  sled  c a |
--|     sale l |
--+------------+
--
{
	letters = {"c", "l", "e", "a", "d", "s"},
	word_positions = {
		{ word = "sled"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "laces"             , pos = { y =  5, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "seal"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "scaled"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "lads"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "sale"              , pos = { y = 12, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "case"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "aces"              , pos = { y = 10, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "scale"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "slade"             , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "clad"              , pos = { y =  6, x =  3 }, orientation = core.VERTICAL    },
		{ word = "lace"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "deals"             , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "deal"              , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "lead"              , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "laced"             , pos = { y =  3, x =  6 }, orientation = core.VERTICAL    },
		{ word = "leads"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "decal"             , pos = { y =  3, x = 10 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|c     t acre|
--|u truce  a  |
--|r  e  acute |
--|a  a  r  e  |
--|trace  care |
--|e  t   r    |
--|    c  a c  |
--| c  u  true |
--| a  race t  |
--| rate u  e  |
--| t   are    |
--|      t     |
--+------------+
--
{
	letters = {"r", "a", "c", "e", "t", "u"},
	word_positions = {
		{ word = "cute"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "acre"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "truce"             , pos = { y =  2, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "care"              , pos = { y =  5, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "react"             , pos = { y =  2, x =  4 }, orientation = core.VERTICAL    },
		{ word = "acute"             , pos = { y =  3, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "crate"             , pos = { y =  5, x =  8 }, orientation = core.VERTICAL    },
		{ word = "cater"             , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "curate"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "curt"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "tear"              , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "cart"              , pos = { y =  8, x =  2 }, orientation = core.VERTICAL    },
		{ word = "trace"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rate"              , pos = { y = 10, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "are"               , pos = { y = 11, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "race"              , pos = { y =  9, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "cure"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "true"              , pos = { y =  8, x =  8 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|score     c |
--|c r  rose o |
--|o code o  r |
--|r s  d rode |
--|e  c o e o  |
--|decor    s  |
--|   d    red |
--|cores   o   |
--|o  s cord   |
--|r       s   |
--|does        |
--|s           |
--+------------+
--
{
	letters = {"r", "o", "d", "s", "c", "e"},
	word_positions = {
		{ word = "redo"              , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "cores"             , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "cords"             , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "rose"              , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "core"              , pos = { y =  1, x = 11 }, orientation = core.VERTICAL    },
		{ word = "score"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rode"              , pos = { y =  4, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "dose"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "decor"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "does"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "sore"              , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "cord"              , pos = { y =  9, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "codes"             , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "red"               , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "scored"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "rods"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "orcs"              , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "code"              , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|horse       |
--|o  h  hero  |
--|r horde     |
--|d  r  r  d  |
--|e  e  d  o  |
--|s     shred |
--|       e s  |
--|       r  h |
--|rose s shoe |
--|o o  h  o r |
--|d rode  s d |
--|s e  dose   |
--+------------+
--
{
	letters = {"o", "s", "e", "d", "h", "r"},
	word_positions = {
		{ word = "hers"              , pos = { y =  6, x =  8 }, orientation = core.VERTICAL    },
		{ word = "hero"              , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "horde"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "shore"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "herds"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "rode"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "dose"              , pos = { y = 12, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "hordes"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "shred"             , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "does"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "shoe"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "sore"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "herd"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "hose"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "rods"              , pos = { y =  9, x =  1 }, orientation = core.VERTICAL    },
		{ word = "shed"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "horse"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|s  c score  |
--|escort  e c |
--|c  r o  sort|
--|t  sore t e |
--|o  e e    s |
--|r  t   cost |
--|    o  o    |
--|    r  rose |
--|  t core c  |
--| toes  s o  |
--|  r      t  |
--| sect       |
--+------------+
--
{
	letters = {"o", "s", "r", "e", "t", "c"},
	word_positions = {
		{ word = "cores"             , pos = { y =  6, x =  8 }, orientation = core.VERTICAL    },
		{ word = "toes"              , pos = { y = 10, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y =  8, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "rest"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "orcs"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "store"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "escort"            , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "sort"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "sect"              , pos = { y = 12, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "corset"            , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "sore"              , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "tore"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "core"              , pos = { y =  9, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "sector"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "scot"              , pos = { y =  8, x = 10 }, orientation = core.VERTICAL    },
		{ word = "score"             , pos = { y =  1, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "cost"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "crest"             , pos = { y =  2, x = 11 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|angel   d  l|
--|n l angle  e|
--|g and l a  a|
--|l n e a land|
--|end n d  g  |
--|d       lend|
--|         d e|
--|           a|
--|        lean|
--|        a g |
--|        n e |
--|       led  |
--+------------+
--
{
	letters = {"g", "l", "e", "d", "a", "n"},
	word_positions = {
		{ word = "dean"              , pos = { y =  6, x = 12 }, orientation = core.VERTICAL    },
		{ word = "led"               , pos = { y = 12, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "lend"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "aged"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "gland"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "angel"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "angled"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "land"              , pos = { y =  4, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "age"               , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "end"               , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "angle"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "lead"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "and"               , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "deal"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "laden"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "lean"              , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "lane"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "glad"              , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|feast       |
--|i  i fast   |
--|e  t a  i   |
--|s feats e  s|
--|t    e  safe|
--|a  east    a|
--| f a    feat|
--|fist    a   |
--| a s  fits  |
--| t    a e   |
--|      t     |
--|   teas     |
--+------------+
--
{
	letters = {"f", "e", "s", "t", "a", "i"},
	word_positions = {
		{ word = "fist"              , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "site"              , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "seat"              , pos = { y =  4, x = 12 }, orientation = core.VERTICAL    },
		{ word = "feast"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "safe"              , pos = { y =  5, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "feats"             , pos = { y =  4, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "fast"              , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "teas"              , pos = { y = 12, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "ties"              , pos = { y =  2, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fate"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fates"             , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "fats"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "eats"              , pos = { y =  6, x =  4 }, orientation = core.VERTICAL    },
		{ word = "fiesta"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "east"              , pos = { y =  6, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "fiat"              , pos = { y =  7, x =  2 }, orientation = core.VERTICAL    },
		{ word = "fits"              , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "feat"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|m    mail   |
--|a  e i  a c |
--|l  male meal|
--|i  a e  e m |
--|claim     e |
--|e  l    calm|
--|        a  i|
--| lice lime c|
--|   l  a e  e|
--|   a  c     |
--|   mace     |
--|            |
--+------------+
--
{
	letters = {"l", "c", "a", "m", "e", "i"},
	word_positions = {
		{ word = "mile"              , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "lame"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "camel"             , pos = { y =  2, x = 11 }, orientation = core.VERTICAL    },
		{ word = "email"             , pos = { y =  2, x =  4 }, orientation = core.VERTICAL    },
		{ word = "lime"              , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "male"              , pos = { y =  3, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "clam"              , pos = { y =  8, x =  4 }, orientation = core.VERTICAL    },
		{ word = "claim"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "mice"              , pos = { y =  6, x = 12 }, orientation = core.VERTICAL    },
		{ word = "lice"              , pos = { y =  8, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "came"              , pos = { y =  6, x =  9 }, orientation = core.VERTICAL    },
		{ word = "mace"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "ice"               , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "mail"              , pos = { y =  1, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "lace"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "calm"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "malice"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "meal"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|tries     s |
--|i       rite|
--|gets      i |
--|e      tier |
--|rites  i    |
--|s i    rigs |
--|  g rise r  |
--|  e e i  i  |
--|tires t  t  |
--|i   tiers   |
--|e           |
--|sire        |
--+------------+
--
{
	letters = {"i", "s", "t", "e", "g", "r"},
	word_positions = {
		{ word = "ties"              , pos = { y =  9, x =  1 }, orientation = core.VERTICAL    },
		{ word = "stir"              , pos = { y =  1, x = 11 }, orientation = core.VERTICAL    },
		{ word = "rest"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "rigs"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "sire"              , pos = { y = 12, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "gets"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "grit"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "site"              , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "tier"              , pos = { y =  4, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "tire"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "rise"              , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tiger"             , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "rites"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tries"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tiers"             , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tigers"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "tires"             , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rite"              , pos = { y =  2, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|break       |
--|a       b b |
--|near  brake |
--|k  a  a r a |
--|earn  k e n |
--|r  kane  b b|
--|      rake a|
--|         a r|
--|      b bran|
--|     bake   |
--|      n a   |
--|   bark k   |
--+------------+
--
{
	letters = {"r", "a", "e", "k", "n", "b"},
	word_positions = {
		{ word = "barn"              , pos = { y =  6, x = 12 }, orientation = core.VERTICAL    },
		{ word = "bear"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "bake"              , pos = { y = 10, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "baker"             , pos = { y =  3, x =  7 }, orientation = core.VERTICAL    },
		{ word = "beak"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "rank"              , pos = { y =  3, x =  4 }, orientation = core.VERTICAL    },
		{ word = "bran"              , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "near"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "banker"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "break"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "bean"              , pos = { y =  2, x = 11 }, orientation = core.VERTICAL    },
		{ word = "bare"              , pos = { y =  2, x =  9 }, orientation = core.VERTICAL    },
		{ word = "earn"              , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "brake"             , pos = { y =  3, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "rake"              , pos = { y =  7, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "bark"              , pos = { y = 12, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "bank"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "kane"              , pos = { y =  6, x =  4 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|b        b  |
--|a r      e  |
--|near r   t  |
--|t t  e bear |
--|e earn e  a |
--|r  n tear n |
--|   t   t  t |
--|  bean   b  |
--|  r  e barn |
--|  a bare a  |
--|  t  t n n  |
--|       t    |
--+------------+
--
{
	letters = {"b", "n", "r", "e", "a", "t"},
	word_positions = {
		{ word = "rant"              , pos = { y =  4, x = 11 }, orientation = core.VERTICAL    },
		{ word = "bear"              , pos = { y =  4, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "beta"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "earn"              , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "neat"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "bran"              , pos = { y =  8, x = 10 }, orientation = core.VERTICAL    },
		{ word = "tear"              , pos = { y =  6, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "brat"              , pos = { y =  8, x =  3 }, orientation = core.VERTICAL    },
		{ word = "banter"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "rent"              , pos = { y =  3, x =  6 }, orientation = core.VERTICAL    },
		{ word = "near"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "bare"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "beat"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "rate"              , pos = { y =  2, x =  3 }, orientation = core.VERTICAL    },
		{ word = "bean"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "ante"              , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "bent"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "barn"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|d        b  |
--|e b      r  |
--|brides  bird|
--|r r      e i|
--|i dries    e|
--|s s   i ribs|
--|   bride  i |
--|    i e   d |
--|  ride beds |
--|  i e  r i  |
--|  s sire r  |
--|  e    d e  |
--+------------+
--
{
	letters = {"r", "b", "i", "e", "s", "d"},
	word_positions = {
		{ word = "beds"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "brie"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "ribs"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "bride"             , pos = { y =  7, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "rides"             , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "ride"              , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "side"              , pos = { y =  5, x =  7 }, orientation = core.VERTICAL    },
		{ word = "sire"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "dies"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "bird"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "brides"            , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "debris"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "bids"              , pos = { y =  6, x = 11 }, orientation = core.VERTICAL    },
		{ word = "birds"             , pos = { y =  2, x =  3 }, orientation = core.VERTICAL    },
		{ word = "bred"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "dries"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "rise"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "dire"              , pos = { y =  9, x = 10 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|s           |
--|a t         |
--|turns      a|
--|u a   t r  r|
--|rants u u  t|
--|n s t r nuts|
--|    aunts s |
--|    r  u  a |
--|rats aunt r |
--|a  t n a    |
--|n rust      |
--|t  n s      |
--+------------+
--
{
	letters = {"r", "t", "n", "s", "u", "a"},
	word_positions = {
		{ word = "rant"              , pos = { y =  9, x =  1 }, orientation = core.VERTICAL    },
		{ word = "arts"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "ants"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "saturn"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "turns"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "runs"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "trans"             , pos = { y =  2, x =  3 }, orientation = core.VERTICAL    },
		{ word = "aunt"              , pos = { y =  9, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "rants"             , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rats"              , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tsar"              , pos = { y =  6, x = 11 }, orientation = core.VERTICAL    },
		{ word = "turn"              , pos = { y =  4, x =  7 }, orientation = core.VERTICAL    },
		{ word = "aunts"             , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tuna"              , pos = { y =  7, x =  8 }, orientation = core.VERTICAL    },
		{ word = "rust"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "stun"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "nuts"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "star"              , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|units       |
--|n   unite   |
--|i   i  u  u |
--|t  stein  n |
--|e   e  e  i |
--|site   sent |
--|  i      u  |
--|  e      t  |
--|  suit nest |
--|     e e  u |
--|  stun t  n |
--|     s sine |
--+------------+
--
{
	letters = {"t", "e", "u", "i", "n", "s"},
	word_positions = {
		{ word = "ties"              , pos = { y =  6, x =  3 }, orientation = core.VERTICAL    },
		{ word = "site"              , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "units"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "unit"              , pos = { y =  3, x = 11 }, orientation = core.VERTICAL    },
		{ word = "nets"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "nest"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "sine"              , pos = { y = 12, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "unite"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tens"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "stein"             , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "tune"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "sent"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "suit"              , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "stun"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "tunes"             , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "suite"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "nuts"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "unites"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|slide s dies|
--|l    rise   |
--|i  d  d lies|
--|d  ride i  l|
--|e  i       i|
--|rides   lied|
--| s s     d  |
--| l       l  |
--| e l  sire  |
--|   i  l     |
--|   dire     |
--|   s  d     |
--+------------+
--
{
	letters = {"r", "d", "e", "i", "s", "l"},
	word_positions = {
		{ word = "lids"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "idle"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "sled"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "slid"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "lies"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "rise"              , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "rides"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ride"              , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "side"              , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "deli"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "dies"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "slider"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "isle"              , pos = { y =  6, x =  2 }, orientation = core.VERTICAL    },
		{ word = "slide"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "sire"              , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "lied"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "dries"             , pos = { y =  3, x =  4 }, orientation = core.VERTICAL    },
		{ word = "dire"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|p s o s     |
--|o p pines o |
--|noise i   p |
--|i n n poise |
--|e e s e o n |
--|s    n  n   |
--|  p  ones   |
--|  i  s   p  |
--|  nope pies |
--|  e o  i n  |
--|    spin s  |
--|    e  s    |
--+------------+
--
{
	letters = {"p", "i", "s", "o", "e", "n"},
	word_positions = {
		{ word = "poise"             , pos = { y =  4, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "ones"              , pos = { y =  7, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "open"              , pos = { y =  2, x = 11 }, orientation = core.VERTICAL    },
		{ word = "pose"              , pos = { y =  9, x =  5 }, orientation = core.VERTICAL    },
		{ word = "pies"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "noise"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "pine"              , pos = { y =  7, x =  3 }, orientation = core.VERTICAL    },
		{ word = "ponies"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "pens"              , pos = { y =  8, x = 10 }, orientation = core.VERTICAL    },
		{ word = "pines"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "nope"              , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "spin"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "nose"              , pos = { y =  6, x =  6 }, orientation = core.VERTICAL    },
		{ word = "snipe"             , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "spine"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "ions"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "pins"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "opens"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|h s  a  s  h|
--|a a  seals e|
--|sale h  a  a|
--|s e  e  seal|
--|lashes  h   |
--|e  e        |
--| leash  l   |
--| e l   sash |
--| s seas s   |
--| s    has   |
--|      e     |
--|    lash    |
--+------------+
--
{
	letters = {"l", "e", "h", "a", "s", "s"},
	word_positions = {
		{ word = "slash"             , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "lash"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "less"              , pos = { y =  7, x =  2 }, orientation = core.VERTICAL    },
		{ word = "seal"              , pos = { y =  4, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "seals"             , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "sash"              , pos = { y =  8, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "sale"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ashes"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "has"               , pos = { y = 10, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "lashes"            , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "leash"             , pos = { y =  7, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "hassle"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sales"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "seas"              , pos = { y =  9, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "lass"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "shes"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "heals"             , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "heal"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|wears  h    |
--|a   wares  h|
--|share  a   e|
--|h   a  r w a|
--|e wars shear|
--|r a      a  |
--|  s    ears |
--|  hers      |
--|    a was   |
--| eras  r    |
--|    hare    |
--|            |
--+------------+
--
{
	letters = {"a", "s", "e", "r", "h", "w"},
	word_positions = {
		{ word = "hers"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "hare"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "shear"             , pos = { y =  5, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "was"               , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "ears"              , pos = { y =  7, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "are"               , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "rash"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "wear"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "swear"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "eras"              , pos = { y = 10, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "washer"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "wash"              , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "wares"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "wars"              , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "wears"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "hears"             , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "share"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "hear"              , pos = { y =  2, x = 12 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|grave   gear|
--|r       a  a|
--|a rages v  g|
--|v   e ages e|
--|e   a v     |
--|saver ears  |
--|  a s    are|
--|  s    r g  |
--|age   rave  |
--|       g    |
--|    eras    |
--|            |
--+------------+
--
{
	letters = {"r", "a", "e", "g", "v", "s"},
	word_positions = {
		{ word = "ears"              , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "grave"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "are"               , pos = { y =  7, x = 10 }, orientation = core.HORIZONTAL  },
		{ word = "rave"              , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "sage"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "save"              , pos = { y =  3, x =  7 }, orientation = core.VERTICAL    },
		{ word = "age"               , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rage"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "rages"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "ages"              , pos = { y =  4, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "gears"             , pos = { y =  3, x =  5 }, orientation = core.VERTICAL    },
		{ word = "eras"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "graves"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "saver"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rags"              , pos = { y =  8, x =  8 }, orientation = core.VERTICAL    },
		{ word = "vase"              , pos = { y =  6, x =  3 }, orientation = core.VERTICAL    },
		{ word = "gear"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "gave"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|ratio s     |
--|a r arts    |
--|t i t i s  o|
--|i o s riot a|
--|o  r    a  r|
--|stair   rats|
--|   o  i  i  |
--| s t  tsar  |
--|roast s  s  |
--| r          |
--|star        |
--|            |
--+------------+
--
{
	letters = {"i", "t", "s", "o", "r", "a"},
	word_positions = {
		{ word = "oats"              , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "ratio"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "stir"              , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "arts"              , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rats"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "riot"              , pos = { y =  4, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "airs"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "stair"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "oars"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "ratios"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "soar"              , pos = { y =  3, x =  9 }, orientation = core.VERTICAL    },
		{ word = "tsar"              , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "roast"             , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "its"               , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "trio"              , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "riots"             , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "sort"              , pos = { y =  8, x =  2 }, orientation = core.VERTICAL    },
		{ word = "star"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|s rings     |
--|i e    r  r |
--|n i risen i |
--|g g e  s  s |
--|e n i rinse |
--|resign n i  |
--|    n   grin|
--| s       e  |
--| i r  reins |
--| rein i   i |
--| e g  n   g |
--|   sing   n |
--+------------+
--
{
	letters = {"s", "n", "r", "e", "g", "i"},
	word_positions = {
		{ word = "risen"             , pos = { y =  3, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "siren"             , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "rinse"             , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "rigs"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "reigns"            , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "grin"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "rein"              , pos = { y = 10, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "reign"             , pos = { y =  3, x =  5 }, orientation = core.VERTICAL    },
		{ word = "reins"             , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "singer"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sire"              , pos = { y =  8, x =  2 }, orientation = core.VERTICAL    },
		{ word = "resign"            , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "resin"             , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "rings"             , pos = { y =  1, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "sign"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "rise"              , pos = { y =  2, x = 11 }, orientation = core.VERTICAL    },
		{ word = "sing"              , pos = { y = 12, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "ring"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|d    gain   |
--|a  g r      |
--|r drain     |
--|i  a n r    |
--|n  i drag   |
--|grand  i    |
--| i   rang   |
--| n    r r   |
--| grid i air |
--|  a i d d   |
--|  i n       |
--|and grin    |
--+------------+
--
{
	letters = {"i", "a", "g", "n", "d", "r"},
	word_positions = {
		{ word = "grind"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "raid"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "drag"              , pos = { y =  5, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "ding"              , pos = { y =  9, x =  5 }, orientation = core.VERTICAL    },
		{ word = "grin"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rang"              , pos = { y =  7, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "grand"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "drain"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "grain"             , pos = { y =  2, x =  4 }, orientation = core.VERTICAL    },
		{ word = "daring"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "gain"              , pos = { y =  1, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "air"               , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "rain"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "arid"              , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "and"               , pos = { y = 12, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "grid"              , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "grad"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "ring"              , pos = { y =  6, x =  2 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|grant  s    |
--|r n rants   |
--|a g a  a    |
--|n s n arts  |
--|t t s    a  |
--|s        n  |
--|       tags |
--|r       n n |
--|a  r  r tsar|
--|n  a rats g |
--|tang  n     |
--|   stag     |
--+------------+
--
{
	letters = {"g", "r", "a", "t", "n", "s"},
	word_positions = {
		{ word = "rant"              , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "arts"              , pos = { y =  4, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "ants"              , pos = { y =  7, x =  9 }, orientation = core.VERTICAL    },
		{ word = "rats"              , pos = { y = 10, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "grant"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "trans"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "sang"              , pos = { y =  4, x = 10 }, orientation = core.VERTICAL    },
		{ word = "rang"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "rants"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tang"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tsar"              , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "stag"              , pos = { y = 12, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "tags"              , pos = { y =  7, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "angst"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "rags"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "snag"              , pos = { y =  7, x = 11 }, orientation = core.VERTICAL    },
		{ word = "grants"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "star"              , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|s        p  |
--|press pesos |
--|o     o  s  |
--|roses r  s r|
--|e o   e repo|
--|s ropes    p|
--|  e     pose|
--|poses     o |
--|r   p   pore|
--|o  rose r e |
--|s   r   o   |
--|e   e   s   |
--+------------+
--
{
	letters = {"e", "r", "s", "p", "o", "s"},
	word_positions = {
		{ word = "spore"             , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "pesos"             , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "ropes"             , pos = { y =  6, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y = 10, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "repo"              , pos = { y =  5, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "prose"             , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "spores"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sores"             , pos = { y =  4, x =  3 }, orientation = core.VERTICAL    },
		{ word = "pores"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "pros"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "press"             , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "sore"              , pos = { y =  7, x = 11 }, orientation = core.VERTICAL    },
		{ word = "pose"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "roses"             , pos = { y =  4, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "pore"              , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "poses"             , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "posse"             , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "rope"              , pos = { y =  4, x = 12 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|hire    h   |
--|e    timer  |
--|r  m i  i   |
--|m term trim |
--|i  r e h    |
--|their  emit |
--| e t   m  i |
--| r      i e |
--|      m tire|
--|     rite   |
--|      t m   |
--|    the     |
--+------------+
--
{
	letters = {"t", "m", "i", "e", "h", "r"},
	word_positions = {
		{ word = "time"              , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "them"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "mite"              , pos = { y =  9, x =  7 }, orientation = core.VERTICAL    },
		{ word = "term"              , pos = { y =  4, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "timer"             , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "their"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tire"              , pos = { y =  9, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "hermit"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "tier"              , pos = { y =  6, x = 11 }, orientation = core.VERTICAL    },
		{ word = "merit"             , pos = { y =  3, x =  4 }, orientation = core.VERTICAL    },
		{ word = "heir"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "her"               , pos = { y =  6, x =  2 }, orientation = core.VERTICAL    },
		{ word = "trim"              , pos = { y =  4, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "rite"              , pos = { y = 10, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "item"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
		{ word = "hire"              , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "the"               , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "emit"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|atoms       |
--|l  o a      |
--|m  salt    m|
--|o  t s     o|
--|s s lost o a|
--|t l a l malt|
--| lots a  t  |
--|  t t mats  |
--|       t  l |
--|    alto  o |
--|       mast |
--|            |
--+------------+
--
{
	letters = {"l", "m", "a", "o", "s", "t"},
	word_positions = {
		{ word = "oats"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "most"              , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "lost"              , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "salt"              , pos = { y =  3, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "atoms"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "malt"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "lots"              , pos = { y =  7, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "atom"              , pos = { y =  8, x =  8 }, orientation = core.VERTICAL    },
		{ word = "almost"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "mast"              , pos = { y = 11, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "last"              , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "alto"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "slot"              , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "lot"               , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "mats"              , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "slam"              , pos = { y =  5, x =  7 }, orientation = core.VERTICAL    },
		{ word = "also"              , pos = { y =  2, x =  6 }, orientation = core.VERTICAL    },
		{ word = "moat"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|modes    d  |
--|o e   dose s|
--|domes o  m t|
--|e o o e mode|
--|s s most   m|
--|t   e  o    |
--|       e    |
--|    dots    |
--|   m  o     |
--|   e  mods  |
--|   dome  e  |
--|   s     t  |
--+------------+
--
{
	letters = {"t", "d", "e", "o", "s", "m"},
	word_positions = {
		{ word = "most"              , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "demos"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "dots"              , pos = { y =  8, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "tome"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "some"              , pos = { y =  3, x =  5 }, orientation = core.VERTICAL    },
		{ word = "demo"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "meds"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "modest"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "does"              , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "dome"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "stem"              , pos = { y =  2, x = 12 }, orientation = core.VERTICAL    },
		{ word = "set"               , pos = { y = 10, x = 10 }, orientation = core.VERTICAL    },
		{ word = "toes"              , pos = { y =  5, x =  8 }, orientation = core.VERTICAL    },
		{ word = "mode"              , pos = { y =  4, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "mods"              , pos = { y = 10, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "domes"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "modes"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "dose"              , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|float       |
--|l  l  last  |
--|o  o   l   l|
--|a  flats   o|
--|t  t l o   f|
--|s    t  slot|
--|  f lost o  |
--|  l o    a  |
--| fast  soft |
--|  t sofa    |
--|       l    |
--|     fats   |
--+------------+
--
{
	letters = {"o", "l", "f", "t", "s", "a"},
	word_positions = {
		{ word = "flats"             , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "lost"              , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "salt"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "aloft"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "sofa"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "loaf"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "fast"              , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "loft"              , pos = { y =  3, x = 12 }, orientation = core.VERTICAL    },
		{ word = "last"              , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "float"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "alto"              , pos = { y =  4, x =  6 }, orientation = core.VERTICAL    },
		{ word = "flat"              , pos = { y =  7, x =  3 }, orientation = core.VERTICAL    },
		{ word = "fats"              , pos = { y = 12, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "floats"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "lots"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "soft"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "also"              , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "slot"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|heard    h  |
--|a r read e  |
--|r m e    a  |
--|m e a  hard |
--|e d made  e |
--|d      a  a |
--|    herd  r |
--|    a       |
--|    r  m  d |
--|    mare  a |
--|     r a  m |
--|  hare dare |
--+------------+
--
{
	letters = {"m", "r", "e", "d", "a", "h"},
	word_positions = {
		{ word = "dear"              , pos = { y =  4, x = 11 }, orientation = core.VERTICAL    },
		{ word = "harmed"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y = 12, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "armed"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "heard"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "mare"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "head"              , pos = { y =  4, x =  8 }, orientation = core.VERTICAL    },
		{ word = "dream"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "hard"              , pos = { y =  4, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "hare"              , pos = { y = 12, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "hear"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "made"              , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "read"              , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "dame"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
		{ word = "are"               , pos = { y = 10, x =  6 }, orientation = core.VERTICAL    },
		{ word = "harm"              , pos = { y =  7, x =  5 }, orientation = core.VERTICAL    },
		{ word = "herd"              , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "mead"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|based      b|
--|i    bead  i|
--|aside   idea|
--|s d     e  s|
--|e e a base  |
--|d abide     |
--|  s d a  s  |
--|    e d  i  |
--| beds said  |
--| i     i e  |
--| d   bad    |
--| s     e    |
--+------------+
--
{
	letters = {"d", "b", "a", "i", "e", "s"},
	word_positions = {
		{ word = "base"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "abide"             , pos = { y =  6, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "said"              , pos = { y =  9, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "beads"             , pos = { y =  5, x =  7 }, orientation = core.VERTICAL    },
		{ word = "based"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "side"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "dies"              , pos = { y =  2, x =  9 }, orientation = core.VERTICAL    },
		{ word = "ideas"             , pos = { y =  3, x =  3 }, orientation = core.VERTICAL    },
		{ word = "bias"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "aside"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "biased"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "aides"             , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "bad"               , pos = { y = 11, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "beds"              , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "bead"              , pos = { y =  2, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "aide"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "bids"              , pos = { y =  9, x =  2 }, orientation = core.VERTICAL    },
		{ word = "idea"              , pos = { y =  3, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|gears say   |
--|r  a   r e  |
--|easy   eras |
--|a  s     r  |
--|s r   rags  |
--|years   r   |
--|  g   gear  |
--| year r y   |
--|  s ages    |
--|    g y     |
--| sage       |
--|            |
--+------------+
--
{
	letters = {"r", "a", "s", "y", "e", "g"},
	word_positions = {
		{ word = "easy"              , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rays"              , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "ears"              , pos = { y =  2, x = 10 }, orientation = core.VERTICAL    },
		{ word = "are"               , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "years"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ages"              , pos = { y =  9, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "sage"              , pos = { y = 11, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "eras"              , pos = { y =  3, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "rages"             , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "gray"              , pos = { y =  5, x =  9 }, orientation = core.VERTICAL    },
		{ word = "year"              , pos = { y =  8, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "rage"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "greasy"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "grey"              , pos = { y =  7, x =  7 }, orientation = core.VERTICAL    },
		{ word = "gears"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rags"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "gear"              , pos = { y =  7, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "say"               , pos = { y =  1, x =  7 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|makes       |
--|a   marks   |
--|k   e       |
--|e  maker    |
--|r   r a     |
--|same  r     |
--|  a mask    |
--|sake r    r |
--|e e  mark a |
--|a    s a  k |
--|mesa   mare |
--|    eras    |
--+------------+
--
{
	letters = {"k", "a", "m", "s", "e", "r"},
	word_positions = {
		{ word = "smear"             , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "same"              , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ears"              , pos = { y =  4, x =  7 }, orientation = core.VERTICAL    },
		{ word = "makers"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "mare"              , pos = { y = 11, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "makes"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "make"              , pos = { y =  6, x =  3 }, orientation = core.VERTICAL    },
		{ word = "seam"              , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sake"              , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rake"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "eras"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "arms"              , pos = { y =  7, x =  6 }, orientation = core.VERTICAL    },
		{ word = "marks"             , pos = { y =  2, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rams"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "mark"              , pos = { y =  9, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "maker"             , pos = { y =  4, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "mesa"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "mask"              , pos = { y =  7, x =  5 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|prime    t t|
--|e  e  time i|
--|r  r  e  m e|
--|m timer  per|
--|i  t  m i m |
--|t       trip|
--|   r tire t |
--|  pier  m   |
--| m p i      |
--|rite m      |
--| t          |
--| e          |
--+------------+
--
{
	letters = {"t", "p", "m", "r", "e", "i"},
	word_positions = {
		{ word = "temp"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "mite"              , pos = { y =  9, x =  2 }, orientation = core.VERTICAL    },
		{ word = "trip"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "per"               , pos = { y =  4, x = 10 }, orientation = core.HORIZONTAL  },
		{ word = "pier"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "timer"             , pos = { y =  4, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "tire"              , pos = { y =  7, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "prime"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "tier"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "merit"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "item"              , pos = { y =  5, x =  9 }, orientation = core.VERTICAL    },
		{ word = "emit"              , pos = { y =  4, x = 11 }, orientation = core.VERTICAL    },
		{ word = "trim"              , pos = { y =  7, x =  6 }, orientation = core.VERTICAL    },
		{ word = "term"              , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "ripe"              , pos = { y =  7, x =  4 }, orientation = core.VERTICAL    },
		{ word = "rite"              , pos = { y = 10, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "time"              , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "permit"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|blame       |
--|l  e  m  d  |
--|a  d  able  |
--|m  a  d  a  |
--|e blade  l  |
--|d e  a l  b |
--|  a  mead e |
--|  male m  a |
--|    e  bald |
--|  meal   a  |
--|    d    m  |
--|      bale  |
--+------------+
--
{
	letters = {"l", "d", "m", "a", "e", "b"},
	word_positions = {
		{ word = "beam"              , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "made"              , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "blade"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "blame"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "bead"              , pos = { y =  6, x = 11 }, orientation = core.VERTICAL    },
		{ word = "male"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "blamed"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "meal"              , pos = { y = 10, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "deal"              , pos = { y =  2, x = 10 }, orientation = core.VERTICAL    },
		{ word = "lead"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "medal"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "bale"              , pos = { y = 12, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "bald"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "dame"              , pos = { y =  5, x =  6 }, orientation = core.VERTICAL    },
		{ word = "able"              , pos = { y =  3, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "lame"              , pos = { y =  9, x = 10 }, orientation = core.VERTICAL    },
		{ word = "lamb"              , pos = { y =  6, x =  8 }, orientation = core.VERTICAL    },
		{ word = "mead"              , pos = { y =  7, x =  6 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|place leap p|
--|a  l     l a|
--|r pearl  e c|
--|c  a e  race|
--|e  r care a |
--|l a  a  a p |
--|  clap  l e |
--|  r   l     |
--| reap a     |
--|    e c     |
--|   pale     |
--|    r       |
--+------------+
--
{
	letters = {"e", "r", "a", "c", "p", "l"},
	word_positions = {
		{ word = "acre"              , pos = { y =  6, x =  3 }, orientation = core.VERTICAL    },
		{ word = "cape"              , pos = { y =  4, x = 11 }, orientation = core.VERTICAL    },
		{ word = "care"              , pos = { y =  5, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "recap"             , pos = { y =  3, x =  6 }, orientation = core.VERTICAL    },
		{ word = "pale"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "clap"              , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "place"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "clear"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "parcel"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "pear"              , pos = { y =  9, x =  5 }, orientation = core.VERTICAL    },
		{ word = "lace"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "pearl"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "plea"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "real"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "race"              , pos = { y =  4, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "pace"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "leap"              , pos = { y =  1, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "reap"              , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|dance       |
--|a  a  care  |
--|n crane     |
--|c  e  d r  n|
--|e  d raced e|
--|r     r a  a|
--|   d    dear|
--|   acre  a  |
--|   r a card |
--|acne c a n  |
--|    dean    |
--|       e    |
--+------------+
--
{
	letters = {"n", "d", "c", "r", "a", "e"},
	word_positions = {
		{ word = "dancer"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "dear"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "dean"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "care"              , pos = { y =  2, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "crane"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "cared"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "cedar"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "race"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "near"              , pos = { y =  4, x = 12 }, orientation = core.VERTICAL    },
		{ word = "cane"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "acne"              , pos = { y = 10, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "card"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "read"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "earn"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "raced"             , pos = { y =  5, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "dare"              , pos = { y =  7, x =  4 }, orientation = core.VERTICAL    },
		{ word = "dance"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "acre"              , pos = { y =  8, x =  4 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|finder      |
--|r  i        |
--|i infer  f  |
--|e  e  i  i  |
--|n fried  r  |
--|d i   e fern|
--|  r     i   |
--|fiend finer |
--|i d i i e e |
--|n   r n   i |
--|e  nerd dine|
--|d           |
--+------------+
--
{
	letters = {"i", "n", "e", "d", "f", "r"},
	word_positions = {
		{ word = "dire"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "friend"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "finer"             , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "fined"             , pos = { y =  8, x =  1 }, orientation = core.VERTICAL    },
		{ word = "fiend"             , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ride"              , pos = { y =  3, x =  7 }, orientation = core.VERTICAL    },
		{ word = "rein"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "find"              , pos = { y =  8, x =  7 }, orientation = core.VERTICAL    },
		{ word = "diner"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "infer"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "fired"             , pos = { y =  5, x =  3 }, orientation = core.VERTICAL    },
		{ word = "finder"            , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "fine"              , pos = { y =  6, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fried"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "dine"              , pos = { y = 11, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "nerd"              , pos = { y = 11, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "fern"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "fire"              , pos = { y =  3, x = 10 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|learn   rain|
--|i l e l e  a|
--|n i a i a  i|
--|e e renal  l|
--|a n   e     |
--|r     rail  |
--|         i  |
--|       lane |
--|  liar e e  |
--|  a  e a    |
--|  i lien    |
--|earn n      |
--+------------+
--
{
	letters = {"a", "i", "e", "l", "r", "n"},
	word_positions = {
		{ word = "rail"              , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "earn"              , pos = { y = 12, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "liar"              , pos = { y =  9, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "real"              , pos = { y =  1, x =  9 }, orientation = core.VERTICAL    },
		{ word = "nail"              , pos = { y =  1, x = 12 }, orientation = core.VERTICAL    },
		{ word = "alien"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "liner"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "lair"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "rein"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "line"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "renal"             , pos = { y =  4, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rain"              , pos = { y =  1, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "lien"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "learn"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "near"              , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "lean"              , pos = { y =  8, x =  8 }, orientation = core.VERTICAL    },
		{ word = "lane"              , pos = { y =  8, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "linear"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|c curse     |
--|o    c      |
--|u euros     |
--|r    r  c   |
--|source  u  c|
--|e   o   e  u|
--|  cures sour|
--|    e    u e|
--| rouse sore |
--| o   u u s  |
--|user r r    |
--| e  core    |
--+------------+
--
{
	letters = {"o", "e", "r", "c", "s", "u"},
	word_positions = {
		{ word = "cores"             , pos = { y =  5, x =  5 }, orientation = core.VERTICAL    },
		{ word = "curse"             , pos = { y =  1, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "cures"             , pos = { y =  7, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "score"             , pos = { y =  1, x =  6 }, orientation = core.VERTICAL    },
		{ word = "course"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "source"            , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "cues"              , pos = { y =  4, x =  9 }, orientation = core.VERTICAL    },
		{ word = "ours"              , pos = { y =  7, x = 10 }, orientation = core.VERTICAL    },
		{ word = "euros"             , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "cure"              , pos = { y =  5, x = 12 }, orientation = core.VERTICAL    },
		{ word = "sour"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "sore"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "user"              , pos = { y = 11, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "rouse"             , pos = { y =  9, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "euro"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "core"              , pos = { y = 12, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rose"              , pos = { y =  9, x =  2 }, orientation = core.VERTICAL    },
		{ word = "sure"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|dealt land  |
--|e  a  a  a  |
--|n  delta t  |
--|tale  e deal|
--|a  n       e|
--|l        d a|
--|        tend|
--|         a  |
--|  l  l lane |
--|  e  e e    |
--|  n  neat   |
--|  dent n    |
--+------------+
--
{
	letters = {"l", "t", "n", "a", "d", "e"},
	word_positions = {
		{ word = "dealt"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "dean"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "dental"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "dent"              , pos = { y = 12, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "neat"              , pos = { y = 11, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "lend"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "lent"              , pos = { y =  9, x =  6 }, orientation = core.VERTICAL    },
		{ word = "tale"              , pos = { y =  4, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "land"              , pos = { y =  1, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "date"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "delta"             , pos = { y =  3, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "lead"              , pos = { y =  4, x = 12 }, orientation = core.VERTICAL    },
		{ word = "lean"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "deal"              , pos = { y =  4, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "laden"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "late"              , pos = { y =  1, x =  7 }, orientation = core.VERTICAL    },
		{ word = "lane"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "tend"              , pos = { y =  7, x =  9 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|r     dine  |
--|aired    a  |
--|i      nerd |
--|n r d  e n  |
--|e e idea  d |
--|drain  ride |
--|  d e     a |
--|    rain  r |
--|   r i  d   |
--|   a dare   |
--|  dire  a   |
--|   d    n   |
--+------------+
--
{
	letters = {"d", "r", "e", "n", "i", "a"},
	word_positions = {
		{ word = "dire"              , pos = { y = 11, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "dear"              , pos = { y =  5, x = 11 }, orientation = core.VERTICAL    },
		{ word = "dean"              , pos = { y =  9, x =  9 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y = 10, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "rained"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "ride"              , pos = { y =  6, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "idea"              , pos = { y =  5, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "rain"              , pos = { y =  8, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "nerd"              , pos = { y =  3, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "diner"             , pos = { y =  4, x =  5 }, orientation = core.VERTICAL    },
		{ word = "aired"             , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "raid"              , pos = { y =  9, x =  4 }, orientation = core.VERTICAL    },
		{ word = "read"              , pos = { y =  4, x =  3 }, orientation = core.VERTICAL    },
		{ word = "earn"              , pos = { y =  1, x = 10 }, orientation = core.VERTICAL    },
		{ word = "dine"              , pos = { y =  1, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "aide"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "near"              , pos = { y =  3, x =  8 }, orientation = core.VERTICAL    },
		{ word = "drain"             , pos = { y =  6, x =  1 }, orientation = core.HORIZONTAL  },
	},
},

--+------------+
--|blade  b    |
--|a      e    |
--|ideal bald  |
--|l  b   d i  |
--|e  idea  a  |
--|d  d  bail  |
--| lied l     |
--|  d  deal a |
--|bale e  e i |
--|  e  l laid |
--|     i  d e |
--|            |
--+------------+
--
{
	letters = {"i", "a", "e", "b", "l", "d"},
	word_positions = {
		{ word = "abide"             , pos = { y =  3, x =  4 }, orientation = core.VERTICAL    },
		{ word = "laid"              , pos = { y = 10, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "blade"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ideal"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "bead"              , pos = { y =  1, x =  8 }, orientation = core.VERTICAL    },
		{ word = "bald"              , pos = { y =  3, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "lied"              , pos = { y =  7, x =  2 }, orientation = core.HORIZONTAL  },
		{ word = "deli"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "idea"              , pos = { y =  5, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "dial"              , pos = { y =  3, x = 10 }, orientation = core.VERTICAL    },
		{ word = "bail"              , pos = { y =  6, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "bailed"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "lead"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
		{ word = "deal"              , pos = { y =  8, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "bale"              , pos = { y =  9, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "aide"              , pos = { y =  8, x = 11 }, orientation = core.VERTICAL    },
		{ word = "able"              , pos = { y =  5, x =  7 }, orientation = core.VERTICAL    },
		{ word = "idle"              , pos = { y =  7, x =  3 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|wander      |
--|a  r  r     |
--|r warden    |
--|n  w  a     |
--|earn  draw  |
--|d    w   e  |
--|     a near |
--|     d e r  |
--|  w dear  d |
--|  a r  dare |
--|  r e     a |
--|  dawn warn |
--+------------+
--
{
	letters = {"r", "e", "n", "a", "d", "w"},
	word_positions = {
		{ word = "draw"              , pos = { y =  5, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "dear"              , pos = { y =  9, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "wander"            , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "ward"              , pos = { y =  9, x =  3 }, orientation = core.VERTICAL    },
		{ word = "dare"              , pos = { y = 10, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "drew"              , pos = { y =  9, x =  5 }, orientation = core.VERTICAL    },
		{ word = "wear"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "warned"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "near"              , pos = { y =  7, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "wade"              , pos = { y =  6, x =  6 }, orientation = core.VERTICAL    },
		{ word = "earn"              , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "dawn"              , pos = { y = 12, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "read"              , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "warden"            , pos = { y =  3, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "warn"              , pos = { y = 12, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "nerd"              , pos = { y =  7, x =  8 }, orientation = core.VERTICAL    },
		{ word = "drawn"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "dean"              , pos = { y =  9, x = 11 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|s s       s |
--|often f ones|
--|f o o o n n |
--|t n tones t |
--|e e e t e   |
--|n   s s tone|
--|       t  o |
--|  tens o  t |
--|    e  nose |
--|    toes o  |
--|    s    f  |
--|      nest  |
--+------------+
--
{
	letters = {"s", "o", "f", "e", "n", "t"},
	word_positions = {
		{ word = "note"              , pos = { y =  6, x = 11 }, orientation = core.VERTICAL    },
		{ word = "ones"              , pos = { y =  2, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "tons"              , pos = { y =  7, x =  8 }, orientation = core.VERTICAL    },
		{ word = "toes"              , pos = { y = 10, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "often"             , pos = { y =  2, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "nets"              , pos = { y =  8, x =  5 }, orientation = core.VERTICAL    },
		{ word = "onset"             , pos = { y =  2, x =  9 }, orientation = core.VERTICAL    },
		{ word = "fonts"             , pos = { y =  2, x =  7 }, orientation = core.VERTICAL    },
		{ word = "tone"              , pos = { y =  6, x =  9 }, orientation = core.HORIZONTAL  },
		{ word = "soften"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "sent"              , pos = { y =  1, x = 11 }, orientation = core.VERTICAL    },
		{ word = "tens"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "nose"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "tones"             , pos = { y =  4, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "nest"              , pos = { y = 12, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "soft"              , pos = { y =  9, x = 10 }, orientation = core.VERTICAL    },
		{ word = "stone"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "notes"             , pos = { y =  2, x =  5 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|lines     l |
--|e o o  lose |
--|s i i  i  n |
--|i s lions s |
--|ones   e l  |
--|n  o  i  i  |
--| l lies  e  |
--|nose  lion  |
--| n    e i   |
--| e      l   |
--|     ions   |
--|            |
--+------------+
--
{
	letters = {"o", "i", "l", "e", "n", "s"},
	word_positions = {
		{ word = "ones"              , pos = { y =  5, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "soil"              , pos = { y =  1, x =  5 }, orientation = core.VERTICAL    },
		{ word = "noise"             , pos = { y =  1, x =  3 }, orientation = core.VERTICAL    },
		{ word = "lone"              , pos = { y =  7, x =  2 }, orientation = core.VERTICAL    },
		{ word = "lies"              , pos = { y =  7, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "lien"              , pos = { y =  5, x = 10 }, orientation = core.VERTICAL    },
		{ word = "lion"              , pos = { y =  8, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "line"              , pos = { y =  2, x =  8 }, orientation = core.VERTICAL    },
		{ word = "lions"             , pos = { y =  4, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "ions"              , pos = { y = 11, x =  6 }, orientation = core.HORIZONTAL  },
		{ word = "lose"              , pos = { y =  2, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "isle"              , pos = { y =  6, x =  7 }, orientation = core.VERTICAL    },
		{ word = "lesion"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "lines"             , pos = { y =  1, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "nose"              , pos = { y =  8, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lens"              , pos = { y =  1, x = 11 }, orientation = core.VERTICAL    },
		{ word = "sole"              , pos = { y =  5, x =  4 }, orientation = core.VERTICAL    },
		{ word = "oils"              , pos = { y =  8, x =  9 }, orientation = core.VERTICAL    },
	},
},

--+------------+
--|a  plain    |
--|l  a    p   |
--|plane plan  |
--|i  e  e i   |
--|n alien n   |
--|e     a  l  |
--|   p  line  |
--|  lien   a  |
--|   n a lane |
--|pale i e    |
--|    plea    |
--|       pile |
--+------------+
--
{
	letters = {"p", "e", "l", "n", "i", "a"},
	word_positions = {
		{ word = "pile"              , pos = { y = 12, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "plain"             , pos = { y =  1, x =  4 }, orientation = core.HORIZONTAL  },
		{ word = "alpine"            , pos = { y =  1, x =  1 }, orientation = core.VERTICAL    },
		{ word = "nail"              , pos = { y =  8, x =  6 }, orientation = core.VERTICAL    },
		{ word = "alien"             , pos = { y =  5, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "pale"              , pos = { y = 10, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lien"              , pos = { y =  8, x =  3 }, orientation = core.HORIZONTAL  },
		{ word = "pine"              , pos = { y =  7, x =  4 }, orientation = core.VERTICAL    },
		{ word = "plea"              , pos = { y = 11, x =  5 }, orientation = core.HORIZONTAL  },
		{ word = "leap"              , pos = { y =  9, x =  8 }, orientation = core.VERTICAL    },
		{ word = "line"              , pos = { y =  7, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "panel"             , pos = { y =  1, x =  4 }, orientation = core.VERTICAL    },
		{ word = "penal"             , pos = { y =  3, x =  7 }, orientation = core.VERTICAL    },
		{ word = "plan"              , pos = { y =  3, x =  7 }, orientation = core.HORIZONTAL  },
		{ word = "plane"             , pos = { y =  3, x =  1 }, orientation = core.HORIZONTAL  },
		{ word = "lean"              , pos = { y =  6, x = 10 }, orientation = core.VERTICAL    },
		{ word = "lane"              , pos = { y =  9, x =  8 }, orientation = core.HORIZONTAL  },
		{ word = "pain"              , pos = { y =  2, x =  9 }, orientation = core.VERTICAL    },
	},
},

}

return puzzles

