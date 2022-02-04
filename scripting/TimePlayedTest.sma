#include <amxmodx>
#include <unixtime>

#if !defined client_print_color
	#define client_print_color client_print
	#define print_team_default print_chat
#endif

native get_time_played( id )
native get_first_seen( id )
native get_last_seen( id )
new const szFormatRule[ ] = "%m/%d/%Y %H:%M:%S"

public plugin_init( ) 
{
	register_plugin( "Time Played: Test", "", "Supremache" )
	register_clcmd( "say /time", "@TimePlayed" )
}


@TimePlayed( id )
{
	new szTime[ 64 ], iYear, iMonth, iDay, iHour, iMinute, iSecond;
	new iTime = get_time_played( id ), iFirst = get_first_seen( id ), iLast = get_last_seen( id );
	
	UnixToTime( iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond );
	
	client_print_color( id, print_team_default, "^4[Time Played]^1 Your Time^4(%d)^3 ->^4 (%02d/%02d/%02d %02d:%02d:%d)", iTime, iMonth, iDay, iYear, iHour, iMinute, iSecond );
	format_time( szTime, charsmax( szTime ), szFormatRule, iFirst )
	client_print_color( id, print_team_default, "^4[Time Played]^1 First Time:^4 %s", szTime );
	format_time( szTime, charsmax( szTime ), szFormatRule, iLast )
	client_print_color( id, print_team_default, "^4[Time Played]^1 Last Time:^4 %s", iLast ? szTime : "Hello, You are new here!" );
}
