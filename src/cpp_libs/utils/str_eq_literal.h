// #include <stdlib.h>

// The idea is that you can do
// str_eq_literal(arg, "some_str", arg_len)
// and:
//     * will stop searching if arg does not contain a null
//     * will not match "some" (note strncmp("some", "some_str", len("some")) would match)
//     * will even fail if arg contains extra null characters, e.g. "some_str\x00\x00\x00\x00"
#define str_eq_literal(arg, literal, n) \
	((n == sizeof(literal)-1) && memcmp(arg, literal, sizeof(literal)) == 0)
