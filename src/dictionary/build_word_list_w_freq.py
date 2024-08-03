#!/usr/bin/env python
#
# This script generates:
# * `out/words-en.txt`: the plain text file meant to be loaded at runtime,
#                       containing all the words and their frequencies
#                       (and some metadata to filter out weird or vulgar words)
# * `out/word_dict.db`: an sqlite3 version of the same thing. At one point
#                       I used this instead of a text file, but it was big
#                       and bundling all of sqlite3 just to read it didn't
#                       make sense. I still use it to generate some word
#                       puzzles.

import re
import math
import os
import sys
import collections
import dict_utils

# TODO I don't think I use this anymore?
output_sqlite_db  = False

output_ascii_list = True

print_word_len_dist = False


if output_sqlite_db:
	import sqlite3

# https://github.com/rspeer/wordfreq
import wordfreq

only_output_words_len = None

# https://github.com/wordnik/wordlist 
wordlist_fname = 'third_party/wordlist/wordlist-20210729.txt'

skip_words_fname  = 'src/dictionary/wip/words_to_remove.txt'
bad_word_list_fname2  = 'src/dictionary/wip/vulgar_or_weird_words.txt'
db_fname_dst   = 'out/word_dict.db'
ascii_list_output_fname = 'out/words-en.txt'
LANGUAGE = 'en'

word_info_entry = collections.namedtuple('word_info_entry', field_names=['word', 'freq', 'is_vulgar_or_weird'])
word_info_list = []

word_counts_by_length = {}

skip_words            = dict_utils.read_word_list(skip_words_fname)
vulgar_or_weird_words = dict_utils.read_word_list(bad_word_list_fname2)

#word_info_list = sorted(word_info_list, key = lambda x: x.freq, reverse=True)
# NOTE: the word dictionary must be sorted alphabetically, now that I'm using bisection search
# to find words that I need.
word_info_list = sorted(word_info_list, key = lambda x: x.word, reverse=False)

#n = len(word_info_list) - 80000
#n = 10
#print(word_info_list[n-10:n])

#print(len(word_info_list))

def to_sqlite_bool(bool_val):
	# This doesn't seem to work for me
	#if bool_val: return 'TRUE'
	#else: return 'FALSE'
	if bool_val: return '1'
	else: return '0'

if output_sqlite_db:
	os.makedirs(os.path.dirname(db_fname_dst), exist_ok=True)
	con = sqlite3.connect(db_fname_dst)
	
	cur = con.cursor()
	
	cur.execute("CREATE TABLE words(word TEXT, freq REAL, is_vulgar_or_weird INTEGER)")
	
	for info in word_info_list:
		if only_output_words_len is not None and len(info.word) != only_output_words_len: continue

		cur.execute("INSERT INTO words VALUES (?, ?, ?)", (info.word, info.freq, to_sqlite_bool(info.is_vulgar_or_weird)))
	
	con.commit()
	
	#print(cur.execute("SELECT * from words ORDER BY freq DESC LIMIT 10").fetchall())
	print('Wrote %d words to sqlite3 database %s' % (len(word_info_list), db_fname_dst))

def small_float_sci(f):
	if f == 0: return '0'
	else:
		if f < 0: raise Exception()
		# TODO does this work for negative exponents?
		pow_val = math.floor(math.log10(f))
		base_val = f / 10**pow_val

		# an easy way to save ~100 kB uncompressed (12 kB compressed)
		# is to omit the negative sign on the exponents.
		# (then just add it to the data when processing).
		# But for now, this doesn't seem worth it.
		#pow_val = -pow_val

		base_val_str = None
		if ('%.1f' % base_val).endswith('.0'):
			base_val_str = '%d' % base_val
		else:
			base_val_str = '%.1f' % base_val
		s =  '%se%d' % (base_val_str, pow_val)
		return s
		

input_files = [
	wordlist_fname,
	skip_words_fname,
	bad_word_list_fname2,
]

if output_ascii_list:
	if (os.path.isfile(ascii_list_output_fname) and
	    os.path.getmtime(ascii_list_output_fname) >= max(map(lambda fname: os.path.getmtime(fname), input_files))):
		print('Skipping generating wordlist because output exists and is newer than input')
		print(f'inputs: %s' % input_files)
		print(f'output: {ascii_list_output_fname}')
		sys.exit(0)
	
	words_map = {}
	
	
	for line in open(wordlist_fname, 'r'):
		m = re.match(r'"([a-zA-Z-]+)"', line)
		if not m: raise Exception('line %s did not match' % line)
		word, = m.groups()
		if word in skip_words: continue
		freq = wordfreq.word_frequency(word, LANGUAGE)
		is_vulgar_or_weird = (word in vulgar_or_weird_words)
		word_info_list.append( word_info_entry(word, freq, is_vulgar_or_weird=is_vulgar_or_weird) )
		if len(word) not in word_counts_by_length:
			word_counts_by_length[len(word)] = 0
		word_counts_by_length[len(word)] += 1
		words_map[word] = freq


	os.makedirs(os.path.dirname(ascii_list_output_fname), exist_ok=True)
	with open(ascii_list_output_fname, 'w') as f:
		for info in word_info_list:
			if only_output_words_len is not None and len(info.word) != only_output_words_len: continue
			extra = ''
			if info.is_vulgar_or_weird:
				extra = ',1'
			line = ('%s,%s%s\n' % (info.word, small_float_sci(info.freq), extra))
			f.write(line)

if print_word_len_dist:
	print('####################')
	print('### Distribution by word length')
	print('####################')
	for word_length in range(35):
		if word_length in word_counts_by_length:
			print('%2d: %8d words' % (word_length, word_counts_by_length[word_length]))
	
print('Wrote a total of %d words to %s' % (len(word_info_list), ascii_list_output_fname))
