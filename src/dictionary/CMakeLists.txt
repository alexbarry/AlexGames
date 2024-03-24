set(dict_inputs build_word_list_w_freq.py wip/vulgar_or_weird_words.txt)
set(dict_output ${CMAKE_SOURCE_DIR}/../out/words-en.txt)

add_custom_command(
	OUTPUT ${dict_output}
	COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --cyan "Generating words-en.txt"
	COMMAND python ${PROJECT_ROOT}/src/dictionary/build_word_list_w_freq.py
	WORKING_DIRECTORY ${PROJECT_ROOT}
	DEPENDS ${dict_inputs}
)

add_custom_target(
	generate_dict_file ALL
	DEPENDS ${dict_output}
)
