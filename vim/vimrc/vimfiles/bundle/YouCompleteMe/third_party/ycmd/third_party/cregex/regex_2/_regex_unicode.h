typedef unsigned char RE_UINT8;
typedef signed char RE_INT8;
typedef unsigned short RE_UINT16;
typedef signed short RE_INT16;
typedef unsigned int RE_UINT32;
typedef signed int RE_INT32;

typedef unsigned char BOOL;
#if !defined(FALSE) || !defined(TRUE)
#define FALSE 0
#define TRUE 1
#endif

#define RE_ASCII_MAX 0x7F
#define RE_LOCALE_MAX 0xFF
#define RE_UNICODE_MAX 0x10FFFF

#define RE_MAX_CASES 4
#define RE_MAX_FOLDED 3
#define RE_MAX_SCX 19

typedef struct RE_Property {
    RE_UINT16 name;
    RE_UINT8 id;
    RE_UINT8 value_set;
} RE_Property;

typedef struct RE_PropertyValue {
    RE_UINT16 name;
    RE_UINT8 value_set;
    RE_UINT16 id;
} RE_PropertyValue;

typedef RE_UINT32 (*RE_GetPropertyFunc)(RE_UINT32 ch);

#define RE_PROP_GC 0x0
#define RE_PROP_CASED 0xB
#define RE_PROP_UPPERCASE 0xA
#define RE_PROP_LOWERCASE 0x9
#define RE_PROP_SCX 0x3

#define RE_PROP_C 30
#define RE_PROP_L 31
#define RE_PROP_M 32
#define RE_PROP_N 33
#define RE_PROP_P 34
#define RE_PROP_S 35
#define RE_PROP_Z 36
#define RE_PROP_ASSIGNED 38
#define RE_PROP_CASEDLETTER 37

#define RE_PROP_CN 0
#define RE_PROP_LU 1
#define RE_PROP_LL 2
#define RE_PROP_LT 3
#define RE_PROP_LM 4
#define RE_PROP_LO 5
#define RE_PROP_MN 6
#define RE_PROP_ME 7
#define RE_PROP_MC 8
#define RE_PROP_ND 9
#define RE_PROP_NL 10
#define RE_PROP_NO 11
#define RE_PROP_ZS 12
#define RE_PROP_ZL 13
#define RE_PROP_ZP 14
#define RE_PROP_CC 15
#define RE_PROP_CF 16
#define RE_PROP_CO 17
#define RE_PROP_CS 18
#define RE_PROP_PD 19
#define RE_PROP_PS 20
#define RE_PROP_PE 21
#define RE_PROP_PC 22
#define RE_PROP_PO 23
#define RE_PROP_SM 24
#define RE_PROP_SC 25
#define RE_PROP_SK 26
#define RE_PROP_SO 27
#define RE_PROP_PI 28
#define RE_PROP_PF 29

#define RE_PROP_C_MASK 0x00078001
#define RE_PROP_L_MASK 0x0000003E
#define RE_PROP_M_MASK 0x000001C0
#define RE_PROP_N_MASK 0x00000E00
#define RE_PROP_P_MASK 0x30F80000
#define RE_PROP_S_MASK 0x0F000000
#define RE_PROP_Z_MASK 0x00007000

#define RE_PROP_ALNUM 0x530001
#define RE_PROP_ALPHA 0x080001
#define RE_PROP_ANY 0x540001
#define RE_PROP_ASCII 0x010001
#define RE_PROP_BLANK 0x550001
#define RE_PROP_CNTRL 0x00000F
#define RE_PROP_DIGIT 0x000009
#define RE_PROP_GRAPH 0x560001
#define RE_PROP_LOWER 0x090001
#define RE_PROP_PRINT 0x570001
#define RE_PROP_SPACE 0x1A0001
#define RE_PROP_UPPER 0x0A0001
#define RE_PROP_WORD 0x580001
#define RE_PROP_XDIGIT 0x590001
#define RE_PROP_POSIX_ALNUM 0x5B0001
#define RE_PROP_POSIX_DIGIT 0x5A0001
#define RE_PROP_POSIX_PUNCT 0x5C0001
#define RE_PROP_POSIX_XDIGIT 0x5D0001

#define RE_WBREAK_OTHER 0
#define RE_WBREAK_DOUBLEQUOTE 1
#define RE_WBREAK_SINGLEQUOTE 2
#define RE_WBREAK_HEBREWLETTER 3
#define RE_WBREAK_CR 4
#define RE_WBREAK_LF 5
#define RE_WBREAK_NEWLINE 6
#define RE_WBREAK_EXTEND 7
#define RE_WBREAK_REGIONALINDICATOR 8
#define RE_WBREAK_FORMAT 9
#define RE_WBREAK_KATAKANA 10
#define RE_WBREAK_ALETTER 11
#define RE_WBREAK_MIDLETTER 12
#define RE_WBREAK_MIDNUM 13
#define RE_WBREAK_MIDNUMLET 14
#define RE_WBREAK_NUMERIC 15
#define RE_WBREAK_EXTENDNUMLET 16
#define RE_WBREAK_ZWJ 17
#define RE_WBREAK_WSEGSPACE 18
#define RE_WBREAK_EBASE 19
#define RE_WBREAK_EBASEGAZ 20
#define RE_WBREAK_EMODIFIER 21
#define RE_WBREAK_GLUEAFTERZWJ 22

#define RE_GBREAK_OTHER 0
#define RE_GBREAK_PREPEND 1
#define RE_GBREAK_CR 2
#define RE_GBREAK_LF 3
#define RE_GBREAK_CONTROL 4
#define RE_GBREAK_EXTEND 5
#define RE_GBREAK_REGIONALINDICATOR 6
#define RE_GBREAK_SPACINGMARK 7
#define RE_GBREAK_L 8
#define RE_GBREAK_V 9
#define RE_GBREAK_T 10
#define RE_GBREAK_LV 11
#define RE_GBREAK_LVT 12
#define RE_GBREAK_ZWJ 13
#define RE_GBREAK_EBASE 14
#define RE_GBREAK_EBASEGAZ 15
#define RE_GBREAK_EMODIFIER 16
#define RE_GBREAK_GLUEAFTERZWJ 17

#define RE_LBREAK_UNKNOWN 0
#define RE_LBREAK_OPENPUNCTUATION 1
#define RE_LBREAK_CLOSEPUNCTUATION 2
#define RE_LBREAK_QUOTATION 3
#define RE_LBREAK_GLUE 4
#define RE_LBREAK_NONSTARTER 5
#define RE_LBREAK_EXCLAMATION 6
#define RE_LBREAK_BREAKSYMBOLS 7
#define RE_LBREAK_INFIXNUMERIC 8
#define RE_LBREAK_PREFIXNUMERIC 9
#define RE_LBREAK_POSTFIXNUMERIC 10
#define RE_LBREAK_NUMERIC 11
#define RE_LBREAK_ALPHABETIC 12
#define RE_LBREAK_IDEOGRAPHIC 13
#define RE_LBREAK_INSEPARABLE 14
#define RE_LBREAK_HYPHEN 15
#define RE_LBREAK_COMBININGMARK 16
#define RE_LBREAK_BREAKBEFORE 17
#define RE_LBREAK_BREAKAFTER 18
#define RE_LBREAK_SPACE 19
#define RE_LBREAK_MANDATORYBREAK 20
#define RE_LBREAK_CARRIAGERETURN 21
#define RE_LBREAK_LINEFEED 22
#define RE_LBREAK_CONTINGENTBREAK 23
#define RE_LBREAK_COMPLEXCONTEXT 24
#define RE_LBREAK_AMBIGUOUS 25
#define RE_LBREAK_BREAKBOTH 26
#define RE_LBREAK_SURROGATE 27
#define RE_LBREAK_ZWSPACE 28
#define RE_LBREAK_NEXTLINE 29
#define RE_LBREAK_WORDJOINER 30
#define RE_LBREAK_JL 31
#define RE_LBREAK_JV 32
#define RE_LBREAK_JT 33
#define RE_LBREAK_H2 34
#define RE_LBREAK_H3 35
#define RE_LBREAK_CLOSEPARENTHESIS 36
#define RE_LBREAK_HEBREWLETTER 37
#define RE_LBREAK_CONDITIONALJAPANESESTARTER 38
#define RE_LBREAK_REGIONALINDICATOR 39
#define RE_LBREAK_EBASE 40
#define RE_LBREAK_EMODIFIER 41
#define RE_LBREAK_ZWJ 42

extern char* re_strings[1404];
extern RE_Property re_properties[168];
extern RE_PropertyValue re_property_values[1543];
extern RE_UINT16 re_expand_on_folding[104];
extern RE_GetPropertyFunc re_get_property[94];

RE_UINT32 re_get_general_category(RE_UINT32 ch);
RE_UINT32 re_get_block(RE_UINT32 ch);
RE_UINT32 re_get_script(RE_UINT32 ch);
int re_get_script_extensions(RE_UINT32 ch, RE_UINT8* scripts);
RE_UINT32 re_get_word_break(RE_UINT32 ch);
RE_UINT32 re_get_grapheme_cluster_break(RE_UINT32 ch);
RE_UINT32 re_get_sentence_break(RE_UINT32 ch);
RE_UINT32 re_get_math(RE_UINT32 ch);
RE_UINT32 re_get_alphabetic(RE_UINT32 ch);
RE_UINT32 re_get_lowercase(RE_UINT32 ch);
RE_UINT32 re_get_uppercase(RE_UINT32 ch);
RE_UINT32 re_get_cased(RE_UINT32 ch);
RE_UINT32 re_get_case_ignorable(RE_UINT32 ch);
RE_UINT32 re_get_changes_when_lowercased(RE_UINT32 ch);
RE_UINT32 re_get_changes_when_uppercased(RE_UINT32 ch);
RE_UINT32 re_get_changes_when_titlecased(RE_UINT32 ch);
RE_UINT32 re_get_changes_when_casefolded(RE_UINT32 ch);
RE_UINT32 re_get_changes_when_casemapped(RE_UINT32 ch);
RE_UINT32 re_get_id_start(RE_UINT32 ch);
RE_UINT32 re_get_id_continue(RE_UINT32 ch);
RE_UINT32 re_get_xid_start(RE_UINT32 ch);
RE_UINT32 re_get_xid_continue(RE_UINT32 ch);
RE_UINT32 re_get_default_ignorable_code_point(RE_UINT32 ch);
RE_UINT32 re_get_grapheme_extend(RE_UINT32 ch);
RE_UINT32 re_get_grapheme_base(RE_UINT32 ch);
RE_UINT32 re_get_grapheme_link(RE_UINT32 ch);
RE_UINT32 re_get_white_space(RE_UINT32 ch);
RE_UINT32 re_get_bidi_control(RE_UINT32 ch);
RE_UINT32 re_get_join_control(RE_UINT32 ch);
RE_UINT32 re_get_dash(RE_UINT32 ch);
RE_UINT32 re_get_hyphen(RE_UINT32 ch);
RE_UINT32 re_get_quotation_mark(RE_UINT32 ch);
RE_UINT32 re_get_terminal_punctuation(RE_UINT32 ch);
RE_UINT32 re_get_other_math(RE_UINT32 ch);
RE_UINT32 re_get_hex_digit(RE_UINT32 ch);
RE_UINT32 re_get_ascii_hex_digit(RE_UINT32 ch);
RE_UINT32 re_get_other_alphabetic(RE_UINT32 ch);
RE_UINT32 re_get_ideographic(RE_UINT32 ch);
RE_UINT32 re_get_diacritic(RE_UINT32 ch);
RE_UINT32 re_get_extender(RE_UINT32 ch);
RE_UINT32 re_get_other_lowercase(RE_UINT32 ch);
RE_UINT32 re_get_other_uppercase(RE_UINT32 ch);
RE_UINT32 re_get_noncharacter_code_point(RE_UINT32 ch);
RE_UINT32 re_get_other_grapheme_extend(RE_UINT32 ch);
RE_UINT32 re_get_ids_binary_operator(RE_UINT32 ch);
RE_UINT32 re_get_ids_trinary_operator(RE_UINT32 ch);
RE_UINT32 re_get_radical(RE_UINT32 ch);
RE_UINT32 re_get_unified_ideograph(RE_UINT32 ch);
RE_UINT32 re_get_other_default_ignorable_code_point(RE_UINT32 ch);
RE_UINT32 re_get_deprecated(RE_UINT32 ch);
RE_UINT32 re_get_soft_dotted(RE_UINT32 ch);
RE_UINT32 re_get_logical_order_exception(RE_UINT32 ch);
RE_UINT32 re_get_other_id_start(RE_UINT32 ch);
RE_UINT32 re_get_other_id_continue(RE_UINT32 ch);
RE_UINT32 re_get_sentence_terminal(RE_UINT32 ch);
RE_UINT32 re_get_variation_selector(RE_UINT32 ch);
RE_UINT32 re_get_pattern_white_space(RE_UINT32 ch);
RE_UINT32 re_get_pattern_syntax(RE_UINT32 ch);
RE_UINT32 re_get_prepended_concatenation_mark(RE_UINT32 ch);
RE_UINT32 re_get_regional_indicator(RE_UINT32 ch);
RE_UINT32 re_get_hangul_syllable_type(RE_UINT32 ch);
RE_UINT32 re_get_bidi_class(RE_UINT32 ch);
RE_UINT32 re_get_canonical_combining_class(RE_UINT32 ch);
RE_UINT32 re_get_decomposition_type(RE_UINT32 ch);
RE_UINT32 re_get_east_asian_width(RE_UINT32 ch);
RE_UINT32 re_get_joining_group(RE_UINT32 ch);
RE_UINT32 re_get_joining_type(RE_UINT32 ch);
RE_UINT32 re_get_line_break(RE_UINT32 ch);
RE_UINT32 re_get_numeric_type(RE_UINT32 ch);
RE_UINT32 re_get_numeric_value(RE_UINT32 ch);
RE_UINT32 re_get_bidi_mirrored(RE_UINT32 ch);
RE_UINT32 re_get_indic_positional_category(RE_UINT32 ch);
RE_UINT32 re_get_indic_syllabic_category(RE_UINT32 ch);
RE_UINT32 re_get_emoji(RE_UINT32 ch);
RE_UINT32 re_get_emoji_presentation(RE_UINT32 ch);
RE_UINT32 re_get_emoji_modifier(RE_UINT32 ch);
RE_UINT32 re_get_emoji_modifier_base(RE_UINT32 ch);
RE_UINT32 re_get_emoji_component(RE_UINT32 ch);
RE_UINT32 re_get_extended_pictographic(RE_UINT32 ch);
RE_UINT32 re_get_nfd_quick_check(RE_UINT32 ch);
RE_UINT32 re_get_nfc_quick_check(RE_UINT32 ch);
RE_UINT32 re_get_nfkd_quick_check(RE_UINT32 ch);
RE_UINT32 re_get_nfkc_quick_check(RE_UINT32 ch);
RE_UINT32 re_get_alphanumeric(RE_UINT32 ch);
RE_UINT32 re_get_any(RE_UINT32 ch);
RE_UINT32 re_get_blank(RE_UINT32 ch);
RE_UINT32 re_get_graph(RE_UINT32 ch);
RE_UINT32 re_get_print(RE_UINT32 ch);
RE_UINT32 re_get_word(RE_UINT32 ch);
RE_UINT32 re_get_xdigit(RE_UINT32 ch);
RE_UINT32 re_get_posix_digit(RE_UINT32 ch);
RE_UINT32 re_get_posix_alnum(RE_UINT32 ch);
RE_UINT32 re_get_posix_punct(RE_UINT32 ch);
RE_UINT32 re_get_posix_xdigit(RE_UINT32 ch);
int re_get_all_cases(RE_UINT32 ch, RE_UINT32* codepoints);
RE_UINT32 re_get_simple_case_folding(RE_UINT32 ch);
int re_get_full_case_folding(RE_UINT32 ch, RE_UINT32* codepoints);
