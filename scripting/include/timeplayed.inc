#if defined _timeplayed_included
    #endinput
#endif

#define _timeplayed_included

/**
 * Returns the time played.
 *
 * @param id             Client index.
 * @return            Client time played.
 */
native get_time_played( id )

/**
 * Returns the first time seen.
 *
 * @param id             Client index.
 * @return            Client first seen.
 */

native get_first_seen( id )

/**
 * Returns the last time seen.
 *
 * @param id             Client index.
 * @return            Client last seen.
 */

native get_last_seen( id )