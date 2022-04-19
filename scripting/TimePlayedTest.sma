#include <amxmodx>
#include <unixtime>
// #include <time> for using get_time_length

native get_time_played( id )
native get_first_seen( id )
native get_last_seen( id )

#if !defined client_print_color
    #define client_print_color client_print
    #define print_team_default print_chat
#endif

#if !defined MAX_FMT_LENGTH
    const MAX_FMT_LENGTH = 192
#endif

public plugin_init( ) 
{
    register_plugin( "Time Played: Test", "", "Supremache" )
    register_clcmd( "say /playedtime", "@TimePlayed" )
}

@TimePlayed( id )
{
	static szTime[ 64 ], iYear , iMonth , iDay , iHour , iMinute , iSecond;
	new iTime = get_time_played( id ), iFirst = get_first_seen( id ), iLast = get_last_seen( id );
    
	client_print_color( id, print_team_default, "^4[Time Played]^1 Your Time:^4 %s", get_time_length_ex( iTime ) );
	UnixToTime( iFirst , iYear , iMonth , iDay , iHour , iMinute , iSecond );
	client_print_color( id, print_team_default, "^4[Time Played]^1 Joined Date:^4 %s %d, %d at %02d:%02d:%02d", str_to_month( iMonth ) , iDay , iYear , iHour , iMinute , iSecond );
	format_time( szTime, charsmax( szTime ), "%m/%d/%Y %H:%M:%S", iLast )
	client_print_color( id, print_team_default, "^4[Time Played]^1 Last Seen:^4 %s", szTime );
}
    
get_time_length_ex( iTime ) 
{ 
	new szTime[ MAX_FMT_LENGTH ], iYear, iMonth, iWeek, iDay, iHour, iMinute, iSecond;
    
	iTime -= 31536000 * ( iYear = iTime / 31536000 ) 
	iTime -= 2678400 * ( iMonth = iTime / 2678400 ) 
	iTime -= 604800 * ( iWeek = iTime / 604800 ) 
	iTime -= 86400 * ( iDay = iTime / 86400 ) 
	iTime -= 3600 * ( iHour = iTime / 3600 ) 
	iTime -= 60 * ( iMinute = iTime / 60 ) 
	iSecond = iTime 
	
	formatex( szTime, charsmax( szTime ), "%d Second", iSecond )
	if( iMinute ) format( szTime, charsmax( szTime ), "%d Minute %s", iMinute, szTime )
	if( iHour ) format( szTime, charsmax( szTime ), "%d Hour %s", iHour, szTime )
	if( iDay ) format( szTime, charsmax( szTime ), "%d Day %s", iDay, szTime )
	if( iWeek ) format( szTime, charsmax( szTime ), "%d Week %s", iWeek, szTime )
	if( iMonth ) format( szTime, charsmax( szTime ), "%d Month %s", iMonth, szTime )
	if( iYear ) format( szTime, charsmax( szTime ), "%d Year %s", iYear, szTime )
    
	return szTime;
} 

str_to_month( iMonth )
{
	static szDate[ 32 ];
	
	switch( iMonth )
	{
		case 1: copy( szDate, charsmax( szDate ), "January" )
		case 2: copy( szDate, charsmax( szDate ), "February" )
		case 3: copy( szDate, charsmax( szDate ), "March" )
		case 4: copy( szDate, charsmax( szDate ), "April" )
		case 5: copy( szDate, charsmax( szDate ), "May" )
		case 6: copy( szDate, charsmax( szDate ), "June" )
		case 7: copy( szDate, charsmax( szDate ), "July" )
		case 8: copy( szDate, charsmax( szDate ), "August" )
		case 9: copy( szDate, charsmax( szDate ), "September" )
		case 10: copy( szDate, charsmax( szDate ), "October" )
		case 11: copy( szDate, charsmax( szDate ), "November" )
		case 12: copy( szDate, charsmax( szDate ), "December" )
	}
	return szDate;
}
