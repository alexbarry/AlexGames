#!/usr/bin/env python
#
# This script loops through each English word and finds other words that can be
# made by rearranging all, or a subset of, its letters.
#
# It depends on `out/word_dict.db`, so run `src/dictionary/build_word_list_w_freq.py`
# before running it.
#
# The useful output of this script is just interesting sets of letters which
# can make up many other common words.
# I run this script and then pick sets of letters and hardcode them into
# crossword_letters_gen_puzzles.lua. 
#
# TODO after trying some puzzles made from the max score letters, I'm realizing that
# the current score isn't ideal. The crosswords can only fit so many words, say 15-20 max.
# It's not as fun to guess words that don't fit in the crossword.
#
# So the score should actually penalize letters that find more than 15-20 common words.
#
# The highest score should be letters that can come up with 15-20 common words (above 1e-6 or so),
# have barely any common words beyond that 15-20,
# and maybe have few rare words
#
# So the score should be something like:
#     fit_words_score     = sum(freq) for words where freq >= 1e-6 LIMIT 20; -- not sure if LIMIT works here.
#     not_fit_words_score = fit_words_score - (sum(freq) for words where freq >= 1e-6) -- not sure if there's a way to do this in a single SQL query
# score = fit_words_score - weight * not_fit_words_score
#
# I'm not sure what "weight" should be. See what happens if it is like 100 at first.
# Maybe finding up to say 5 more is not a big deal, perhaps the weight for that can be 0 or less.
#
# TODO:
# * consider lowering frequency threshold for longer words in crossword letters. I defined 1e-6 from looking at 3 letter words. I think longer words have lower frequency even if they are more well known than the obscure 3 letter words that I saw.
#* consider including letter combinations that make many words, and just ensuring a certain minimum umber of easy-to-guess 3 and 4 letter words. Those will provide hints for the longer ones.
#

import re
import string
import itertools
import collections
import sys
import argparse

import shelve
import sqlite3

parser = argparse.ArgumentParser(
	prog='gen_crossword_letters',
	description='Loops through combinations of letters, finding sets of letters that '
	            'can make up a certain number of other English words. A subset of '
	            'letters can be used. Sorts all sets of letters based on "score" (highest '
	            'frequency) and outputs the highest ones.',
	epilog='Intended to be used to generate sets of letters to be used to generate '
	       'crossword puzzles for the `crossword_letters` game.')

parser.add_argument('--min_word_len', type=int,   default=4   ,
                    help='Minimum length of words to be included in score calculation')
parser.add_argument('--min_freq',     type=float, default=1e-6,
                    help='Minimum frequency for a word to be included in score calculation')
parser.add_argument('--min_words',    type=int,   default=3   ,
                    help='Only include sets of letters that can make up this many words or more.')
parser.add_argument('--max_words',    type=int,   default=20  ,
                    help='Exclude sets of letters that make up more than this many words.')

parser.add_argument('--min_letters',  type=int,   default=None   ,
                    help='Only bother trying sets of letters with at least this many letters. '
                         'Must be >= than min_word_len. '
                         'If not set, defaults to min_word_len.')

parser.add_argument('--max_letters',  type=int,   default=8   ,
                    help='Maximum length of sets of letters to try.')

# TODO not sure that I want to do this,
# since changing any of the parameters can mess up the score.
parser.add_argument('--cache_file', default='out/word_scores.shelve',
                    help='Cache scores in this file, so future executions of this program '
                         'can be faster when looking up the same words.')

args = parser.parse_args()

min_freq    = args.min_freq
min_words   = args.min_words
max_words   = args.max_words

max_letters = args.max_letters
min_word_len   = args.min_word_len
min_letters    = args.min_letters

if min_letters is None:
	min_letters = min_word_len

if min_letters < min_word_len:
	raise Exception('arg min_letters (%r) must be >= min_word_len (%r)' % (min_letters, min_word_len))

db_lookups     = 0
shelve_lookups = 0

def sql_regexp(pattern, item):
	reg = re.compile(pattern)
	return reg.search(item) is not None




def get_letter_counts_in_list(letter_list):
	counts = {}
	for letter in letter_list:
		if letter not in counts: counts[letter] = 0
		counts[letter] += 1
	return counts


WordCombinationInfo = collections.namedtuple('WordCombinationInfo', field_names = ['word_count', 'total_score', 'max_word_len'])
def get_words_containing_only_letters(cur, min_freq, letters, score_only, letter_combo_scores_shelve=None, only_word_len=None, recursive=True):
	global db_lookups
	global shelve_lookups

	letters_shelve_key = ''.join(sorted(letters))
	#print("trying letters key %r, only_word_len=%r" % (letters_shelve_key, only_word_len))

	if score_only:
		if letter_combo_scores_shelve is not None:
			try:
				cached_value = letter_combo_scores_shelve[letters_shelve_key]
				shelve_lookups += 1
				# print("found cached value %s" % repr(cached_value))
				word_count, total_score = cached_value
				return WordCombinationInfo(word_count, total_score)
			except KeyError:
				# print("could not find cached value for key %r" % letters_shelve_key)
				pass
	
		if recursive and not only_word_len:
			word_count  = 0
			total_score = 0
			for word_len in range(min_letters, len(letters)+1):
				#print("recursive, trying word_len %d" % word_len)
				for letters2 in itertools.combinations(letters, word_len):
					#print("trying letters2 %s" % repr(letters2))
					info = get_words_containing_only_letters(cur, min_freq, letters2, score_only=score_only,
					                                         letter_combo_scores_shelve=letter_combo_scores_shelve,
					                                         only_word_len=word_len,
					                                         recursive=recursive)
					#print("recvd info %s" % repr(info))
					word_count  += info.word_count
					if info.total_score:
						total_score += info.total_score

			if letter_combo_scores_shelve is not None:
				#print("storing key %r with value %r" % (letters_shelve_key, word_count))
				letter_combo_scores_shelve[letters_shelve_key] = (word_count, total_score)
			return WordCombinationInfo(word_count, total_score)
			
		

	# pattern matching words that only contain `letters`,
	# but may contain the same letter more than once
	word_pattern = '^[' + ''.join(letters) + ']+$'

	letter_counts = get_letter_counts_in_list(letters)

	# Create a list of conditions that would invalidate this match:
	# if it has any letter more than allowed.
	# I'm not aware of any fancy way to do this with a single regex,
	# e.g. "word matching any combination of this list of characters"
	letter_count_conditions = []
	for letter in letter_counts:
		excessive_letter_count = letter_counts[letter] + 1
		letter_count_conditions.append("'%" + "%".join([letter]*excessive_letter_count) + "%'")
	letter_count_conditions = 'word NOT LIKE' + ('AND word NOT LIKE '.join(letter_count_conditions))
		

	if score_only:
		query_params = 'COUNT(1), SUM(freq), MAX(LENGTH(word))'
	else:
		query_params = 'word, freq'

	if False and only_word_len:
		#length_condition = 'LENGTH(word) = %d AND ' % only_word_len
		length_condition = 'word_len = %d AND ' % only_word_len
	else:
		length_condition = ''

	query = ('SELECT {query_params} '
	         'FROM words{tbl_suffix} \n'
	         'WHERE \n'
	         '    LENGTH(word) >= {min_word_len} AND \n'
	         '    {length_condition} \n'
	         '    freq >= {min_freq} AND \n'
	         #'    length(word) >= 3 AND \n'
	         #'    word_len >= 3 AND \n'
	         '    word REGEXP "{word_pattern}" AND \n'
	         '    {letter_count_conditions} \n'
	         'ORDER BY \n'
	         '    LENGTH(word) DESC, \n'
	         '    freq DESC').format(min_word_len=min_word_len,
	                                 tbl_suffix= '%d' % only_word_len if only_word_len else '',
	                                 length_condition=length_condition,
	                                 query_params=query_params,
	                                 min_freq=min_freq,
	                                 word_pattern=word_pattern,
	                                 letter_count_conditions=letter_count_conditions)

	db_lookups += 1
	#print(query)
	#sys.exit()
	cur.execute(query)
	#os.system("sqlite3 word_dict.db \"%s\"" % query)

	if score_only:
		word_count, total_score, max_word_len = cur.fetchone()
		if letter_combo_scores_shelve:
			#print("for key %r, storing count=%d, score=%e" % (letters_shelve_key, word_count, total_score))
			letter_combo_scores_shelve[letters_shelve_key] = (word_count, total_score, max_word_len)
		return WordCombinationInfo(word_count, total_score, max_word_len)

	else:
		return cur.fetchall()
	
	#for item in cur.fetchall():
	#	word, freq = item
	#	show_info = 'shown' if freq >= 3e-6 else 'NOT SHOWN'
	#	print('%9s , %e, %s' % (word, freq, show_info))


con = sqlite3.connect(":memory:")
cur = con.cursor()
cur.execute("CREATE TABLE words (word, freq)")
for i in range(1,40):
	cur.execute("CREATE TABLE words%d (word, freq)" % i)

data_src_con = sqlite3.connect("out/word_dict.db")
data_src_cur = data_src_con.cursor()
rows = data_src_cur.execute("""
SELECT word, freq, LENGTH(word) from words
WHERE NOT words.is_vulgar_or_weird""")
for word, freq, word_length in rows:
	cur.execute("INSERT INTO words%d VALUES (?, ?)" % word_length, (word, freq))
	cur.execute("INSERT INTO words VALUES (?, ?)", (word, freq))

skip_words = set([
	'tae',
	'dna',
	'dan',
	'ons',
	'opt',
	'nos',
	'das',
	'mar',
	'mae',
])
	


con.create_function("REGEXP", 2, sql_regexp)

LETTERS = string.ascii_lowercase
VOWELS  = [ 'a', 'e', 'i', 'o', 'u', 'y' ]



LetterCombinationInfo = collections.namedtuple("LetterCombinationInfo", field_names=["letters", "info", "words", "found_on_iter"])


"""
words = get_words_containing_only_letters(cur, min_freq, list("deeaft"), score_only=False)
for word in words:
	print(word)
sys.exit()
"""

letter_combo_scores = shelve.open(args.cache_file)
#letter_combo_scores = None
print("open shelve %r" % letter_combo_scores )

def get_all_words_by_length():
	words_by_len = {}
	data = cur.execute("SELECT word, freq FROM words WHERE LENGTH(word) >= ? AND freq >= ?", (min_word_len, min_freq))
	for word, freq in cur.fetchall():
		word_length = len(word)
		if word_length not in words_by_len:
			words_by_len[word_length] = []

		words_by_len[word_length].append( (word, freq) )
		
	return words_by_len

def find_all_word_combos():
	good_combos_found = 0
	i = 0

	words_by_len = get_all_words_by_length()

	for letters_len in range(min_letters,max_letters+1):
	#for letters_len in [4]:
		good_combinations = []

		for letter_combinations, freq in words_by_len[letters_len]:
			letter_combinations = list(letter_combinations)
			if True:
				#print("trying letters  %r" % letter_combinations)
				info = get_words_containing_only_letters(cur, min_freq, letter_combinations, score_only=True, letter_combo_scores_shelve=letter_combo_scores, recursive=False)
				i += 1
				#if i % 100 == 0: print(i, letter_combinations)
				#if min_words <= info.word_count:
				if min_words <= info.word_count <= max_words:
	
					#words = get_words_containing_only_letters(cur, min_freq, letter_combinations, score_only=False)
					#combination_info = LetterCombinationInfo(letter_combinations, info, words, i)
					good_combinations.append((letter_combinations, info))
					#sys.stdout.write(' '.join([str(x) for x in [i, letter_combinations, info, words]]) + '\n')
					#sys.stdout.flush()
					good_combos_found += 1
					if False and good_combos_found % 1000 == 0: 
						sys.stdout.write(str(letter_combinations) + str(info))
						sys.stdout.write("\n")
						sys.stdout.flush()
	
		print("##########################")
		print("##########################")
		print("### sorted info ")
		print("##########################")

		words_by_letters = {}
		words_seen_before = set()
		letter_combos_seen_before = set()
		good_combinations = sorted(good_combinations, key=lambda x: (x[1].max_word_len, x[1].total_score), reverse=True)
		print('len: %d' % len(good_combinations))
		j = 0
		for combination_info in good_combinations:
			letters, info = combination_info
			letters_key = ''.join(sorted(letters))
			if letters_key in letter_combos_seen_before: continue
			letter_combos_seen_before.add(letters_key)

			word_info = get_words_containing_only_letters(cur, min_freq, letters, score_only=False)
			#words = [ word for word, freq in word_info if word not in words_seen_before and word not in skip_words ]
			words = [ word for word, freq in word_info if word not in skip_words ]
			#print(words)
			for word in words: words_seen_before.add(word)
			words_by_letters[letters_key] = words

		good_combinations = sorted(good_combinations, key=lambda x: (len(words_by_letters[''.join(sorted(x[0]))]), x[1].total_score), reverse=True)

		words_seen_before = set()
		for combination_info in good_combinations:
			letters, info = combination_info
			letters_key = ''.join(sorted(letters))
			if letters_key in words_seen_before: continue
			words_seen_before.add(letters_key)
			words = words_by_letters[letters_key]
			sys.stdout.write('%4d %s: %s, %s\n' % (j, letters, info, words[:100]))
			sys.stdout.flush()
			j += 1
			if j >= 100: break
				
	print(i)

try:
	find_all_word_combos()
except:
	if letter_combo_scores is not None:
		letter_combo_scores.close()
	print("\n\n")
	print("db_lookups = %9d" % db_lookups)
	print("shelve_lookups = %9d" % shelve_lookups)
	raise
	
	



