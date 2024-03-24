def read_word_list(fname):
	words = set()
	with open(fname, 'r') as f:
		for line in f:
			if line.startswith('#'): continue
			if not line.strip(): continue
			word = line.strip()
			words.add(word)
	return words

