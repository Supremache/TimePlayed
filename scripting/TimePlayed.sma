#include <amxmodx>
#include <nvault_array>

#if !defined client_disconnected
	#define client_disconnected client_disconnect
#endif

#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32
#endif

#if !defined MAX_NAME_LENGTH
	const MAX_NAME_LENGTH = 32
#endif

#if !defined MAX_AUTHID_LENGTH
	const MAX_AUTHID_LENGTH = 64
#endif

#if !defined MAX_IP_LENGTH
	const MAX_IP_LENGTH = 16
#endif

new const Version[ ] = "1.0.0";

const TASK_TIME_PLAYED = 969969

enum PlayerData
{ 
	Name[ MAX_NAME_LENGTH ],
	AuthID[ MAX_AUTHID_LENGTH ],
	IP[ MAX_IP_LENGTH ],
	Time_Played,
	First_Seen,
	Last_Seen,
	bool:bBot_HLTV
}

new g_iPlayer[ MAX_PLAYERS + 1 ][ PlayerData ], g_iVault, g_cNvaultMethod

public plugin_init( ) 
{
	register_plugin( "Time Played", Version, "Supremache" )
	
	#if !defined bind_pcvar_num
	register_cvar( "TimePlayed", Version, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
	g_cNvaultMethod = register_cvar( "tp_nvault_method", "1" )
	#else
	create_cvar( "TimePlayed", Version, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED, "For saves the time played of the player and first & last seen on the server." )
	bind_pcvar_num( create_cvar( "tp_nvault_method", "1", .description = "Save method using nvault." ), g_cNvaultMethod )
	#endif
	
	if ( ( g_iVault = nvault_open( "Time_Played" ) ) == INVALID_HANDLE )
		set_fail_state("Time Played: Failed to open the vault.");
}

public plugin_end( )
{
	nvault_close( g_iVault );
}

public client_putinserver( id )
{
	if( !( g_iPlayer[ id ][ bBot_HLTV ] = bool:( is_user_bot( id ) || is_user_hltv( id ) ) ) )
	{
		get_user_name( id , g_iPlayer[ id ][ Name ] , charsmax( g_iPlayer[ ][ Name ] ) );
		get_user_authid( id , g_iPlayer[ id ][ AuthID ] , charsmax( g_iPlayer[ ][ AuthID ] ) );
		get_user_ip( id, g_iPlayer[ id ][ IP ] , charsmax(g_iPlayer[ ][ IP ]), true );
		
		UseNvault( id, false )
		if( !g_iPlayer[ id ][ First_Seen ] ) g_iPlayer[ id ][ First_Seen ] = get_systime( );
		set_task( 1.0, "DisplayTimePlayed", id + TASK_TIME_PLAYED, .flags = "b" ); // Faster than get_user_time
	}
}

public client_disconnected( id )
{
	if( !g_iPlayer[ id ][ bBot_HLTV ] )
	{
		g_iPlayer[ id ][ Last_Seen ] = get_systime( );
		UseNvault( id, true );
		
		arrayset( g_iPlayer[ id ][ Name ], 0, sizeof( g_iPlayer[ ][ Name ] ) );
		arrayset( g_iPlayer[ id ][ AuthID ], 0, sizeof( g_iPlayer[ ][ AuthID ] ) );
		arrayset( g_iPlayer[ id ][ IP ], 0, sizeof( g_iPlayer[ ][ IP ] ) );
		arrayset( g_iPlayer[ id ][ Time_Played ], 0, sizeof( g_iPlayer[ ][ Time_Played ] ) );
		arrayset( g_iPlayer[ id ][ First_Seen ], 0, sizeof( g_iPlayer[ ][ First_Seen ] ) );
		arrayset( g_iPlayer[ id ][ Last_Seen ], 0, sizeof( g_iPlayer[ ][ Last_Seen ] ) );
		arrayset( g_iPlayer[ id ][ bBot_HLTV ], false, sizeof( g_iPlayer[ ][ bBot_HLTV ] ) );
		remove_task( id + TASK_TIME_PLAYED );
	}
}

public DisplayTimePlayed( id )
{
	g_iPlayer[ ( id -= TASK_TIME_PLAYED ) ][ Time_Played ]++;
}

UseNvault( id, bool:bSave )
{
	new szKey[ 64 ];
	
	switch( g_cNvaultMethod )
	{
		case 2: formatex( szKey, charsmax( szKey ), "%s-NAME", g_iPlayer[ id ][ Name ] );
		case 3: formatex( szKey, charsmax( szKey ), "%s-IP", g_iPlayer[ id ][ IP ] );
		default: formatex( szKey, charsmax( szKey ), "%s-ID", g_iPlayer[ id ][ AuthID ] );
	}
	
	if( bSave )
	{
		nvault_set_array( g_iVault, szKey, g_iPlayer[ id ][ PlayerData:0 ], sizeof( g_iPlayer[ ] ) );
	}
	else
	{
		nvault_get_array( g_iVault, szKey, g_iPlayer[ id ][ PlayerData:0 ], sizeof( g_iPlayer[ ] ) );
	}
}

public plugin_natives( )
{
	register_library("timeplayed");
	register_native( "get_time_played", "_get_time_played" );
	register_native( "get_first_seen", "_get_first_seen" );
	register_native( "get_last_seen", "_get_last_seen" );
}

public _get_time_played( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ Time_Played ];
}

public _get_first_seen( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ First_Seen ];
}
public _get_last_seen( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ Last_Seen ];
}
