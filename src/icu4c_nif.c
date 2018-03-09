/*
Things to note:

1. If less than "n" entries in the list, do a sort
2. If more than "n" generate sort keys and use them instead

3. What is the type of a binary from erlang in Unicode terms.
   ie. what is char16_t and what is UnicodeString  How can we
   process the binary data without copying

4. Probably we want to return sort keys as one api option,
   then we can do the sorting in Elixir if we want.


iterate of the the provided list so we know how many items we have
to sort

malloc (nif maclloc) a space to hold 'n' StringPiece pointers
populate the array with StringPieces that point bcak to to
the binaries passed in.  This appears to not copy anything so its
cheap.

Sort the array using unicode compare on the StringPieces.  Sort
algorithm to be determined.

Create a new erlang list and populate it with the binaries in
the new sorted order and return it.
*/

#include <erl_nif.h>

/*
 *
 * Sorts a list of binaries according to the UCA using the
 * ICU4C library.
 *
 */
static ERL_NIF_TERM sort(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    return enif_make_list(env, ......);

}

static collate(ERL_NIF_TERM list[], Locale locale, ECollationStrength strength)
{
  UErrorCode success = U_ZERO_ERROR;
  Collator* collator = Collator::createInstance(Locale::getUS(), success);
  collator->setStrength(strength);
}


/* Function exports */
static ErlNifFunc nif_funcs[] =
{
    {"sort", 2, sort}
};

ERL_NIF_INIT(icu4c_nif, nif_funcs, NULL, NULL, NULL, NULL)
