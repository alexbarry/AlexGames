#!/usr/bin/env python
#
# This script loops through every single combination of English letters
# (including at least one vowel), seeing what words you can make from them.
# Despite optimizing it with some good-enough hacks, it still takes forever to run.
# I think I got halfway through the 8 letter combinations (and a ~100 GB shelve
# file) before deciding that it would be better to only loop through combinations
# of letters that actually make up an English word (see gen_crossword_letters2.py).

import re
import string
import itertools
import collections
import sys

import shelve
import sqlite3

min_letters = 3
max_letters = 8
min_word_len   = 3

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


WordCombinationInfo = collections.namedtuple('WordCombinationInfo', field_names = ['word_count', 'total_score'])
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
		query_params = 'COUNT(1), SUM(freq)'
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
	cur.execute(query)
	#os.system("sqlite3 word_dict.db \"%s\"" % query)

	if score_only:
		word_count, total_score = cur.fetchone()
		if letter_combo_scores_shelve:
			#print("for key %r, storing count=%d, score=%e" % (letters_shelve_key, word_count, total_score))
			letter_combo_scores_shelve[letters_shelve_key] = (word_count, total_score)
		return WordCombinationInfo(word_count, total_score)

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

data_src_con = sqlite3.connect("word_dict.db")
data_src_cur = data_src_con.cursor()
rows = data_src_cur.execute("SELECT word, freq, LENGTH(word) from words")
for word, freq, word_length in rows:
	cur.execute("INSERT INTO words%d VALUES (?, ?)" % word_length, (word, freq))
	cur.execute("INSERT INTO words VALUES (?, ?)", (word, freq))
	


con.create_function("REGEXP", 2, sql_regexp)

LETTERS = string.ascii_lowercase
VOWELS  = [ 'a', 'e', 'i', 'o', 'u' ]

min_freq    = 3e-6
min_words   = 3

LetterCombinationInfo = collections.namedtuple("LetterCombinationInfo", field_names=["letters", "info", "words", "found_on_iter"])

letter_combo_scores = shelve.open("letter_combo_scores.shelve")
print("open shelve %r" % letter_combo_scores )

def find_all_word_combos():
	good_combos_found = 0
	i = 0
	for letters_len in range(min_letters-1,max_letters-1+1):
		good_combinations = []
		# TODO use "chain" and include the vowel in here...
		for other_letter_combinations in itertools.combinations_with_replacement(LETTERS, letters_len):
			for vowel in VOWELS:
				letter_combinations = list(other_letter_combinations) + [vowel]
				#print("trying letters  %r" % letter_combinations)
				info = get_words_containing_only_letters(cur, min_freq, letter_combinations, score_only=True, letter_combo_scores_shelve=letter_combo_scores)
				i += 1
				#if i % 100 == 0: print(i, letter_combinations)
				if info.word_count >= min_words:
	
					#words = get_words_containing_only_letters(cur, min_freq, letter_combinations, score_only=False)
					#combination_info = LetterCombinationInfo(letter_combinations, info, words, i)
					good_combinations.append((letter_combinations, info))
					#sys.stdout.write(' '.join([str(x) for x in [i, letter_combinations, info, words]]) + '\n')
					#sys.stdout.flush()
					good_combos_found += 1
					if good_combos_found % 1000 == 0: 
						sys.stdout.write(str(letter_combinations) + str(info))
						sys.stdout.write("\n")
						sys.stdout.flush()
	
		print("##########################")
		print("##########################")
		print("### sorted info ")
		print("##########################")
		good_combinations = sorted(good_combinations, key=lambda x: (x[1].word_count, x[1].total_score), reverse=True)
		print('len: %d' % len(good_combinations))
		for combination_info in good_combinations[:20]:
			letters, info = combination_info
			words = get_words_containing_only_letters(cur, min_freq, letters, score_only=False)
			sys.stdout.write('%s: %s, %s\n' % (letters, info, words))
			sys.stdout.flush()
				
	print(i)

try:
	find_all_word_combos()
except:
	letter_combo_scores.close()
	print("\n\n")
	print("db_lookups = %9d" % db_lookups)
	print("shelve_lookups = %9d" % shelve_lookups)
	raise
	
	
# get_words_containing_only_letters(cur, ["r", "m", "c", "i", "y", "e"])



