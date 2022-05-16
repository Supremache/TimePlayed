#include <amxmodx>
#include <nvault>
#include <sqlx>
#include <fakemeta>
#include <cromchat>

new const Version[ ] = "1.1.2";

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

#if !defined MAX_FMT_LENGTH
	const MAX_FMT_LENGTH = 192
#endif

const MAX_QUERY_LENGTH = 256;
const MAX_TIME_LENGTH = 22;
const TASK_TIME_PLAYED = 969969;

new const SQL_HOST[ ] = "localhost"
new const SQL_USER[ ] = "root"
new const SQL_PASS[ ] = "password"
new const SQL_DATABASE[ ] = "database"
new const SQL_TABLE[ ] = "TimePlayed"
new const NVAULT_DATABASE[ ] = "TimePlayed"

enum DataTypes
{
	SAVE,
	LOAD,
	RESET,
	UPDATE
}

enum _:SaveTypes
{
	NICKNAME,
	IP,
	STEAMID
}

enum _:SaveMethods
{
	Nvault,
	MySQL,
	SQLite
}

enum PlayerData
{ 
	SaveInfo[ MAX_AUTHID_LENGTH ],
	Time_Played,
	First_Seen,
	Last_Seen,
	bool:BotOrHLTV
}

new g_iPlayer[ MAX_PLAYERS + 1 ][ PlayerData ],
	g_iVault,
	g_cSaveMethod,
	g_cSaveType,
	g_iFUserNameChanged,
	Handle:g_SQLTuple,
	g_szSQLError[ MAX_QUERY_LENGTH ];

public plugin_init( ) 
{
	register_plugin( "Time Played", Version, "Supremache" )
	register_cvar( "TimePlayed", Version, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
	CC_SetPrefix( "^4[ Time Played ]" );
	
	g_cSaveMethod = register_cvar( "tp_save_method", "0" ) // How to save player's preferences: 0 = nVault | 1 = MySQL | 2 = SQLite
	g_cSaveType = register_cvar( "tp_save_type", "0" ) // ; Save player's data:  0 = Name | 1= IP | 2 = SteamID
	
	register_event( "SayText", "OnSayText", "a", "2=#Cstrike_Name_Change" )
	
	switch( get_pcvar_num( g_cSaveMethod ) )
	{
		case Nvault:
		{
			if ( ( g_iVault = nvault_open( NVAULT_DATABASE ) ) == INVALID_HANDLE )
				set_fail_state("Time Played: Failed to open the vault.");
		}
		case MySQL, SQLite: 
		{
			if( get_pcvar_num( g_cSaveMethod ) == SQLite )
				SQL_SetAffinity( "sqlite" );
				
			g_SQLTuple = SQL_MakeDbTuple( SQL_HOST, SQL_USER, SQL_PASS, SQL_DATABASE );
			    
			new szQuery[ MAX_QUERY_LENGTH ], Handle:SQLConnection, iErrorCode;
			SQLConnection = SQL_Connect( g_SQLTuple, iErrorCode, g_szSQLError, charsmax( g_szSQLError ) );
			    
			if( SQLConnection == Empty_Handle )
				set_fail_state( g_szSQLError );
	
			formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` (`Player` VARCHAR(%i) NOT NULL,\
			`Time Played` INT(%i) NOT NULL, `First Seen` INT(%i) NOT NULL, `Last Seen` INT(%i) NOT NULL, PRIMARY KEY(Player));",\
			SQL_TABLE, MAX_AUTHID_LENGTH, MAX_TIME_LENGTH, MAX_TIME_LENGTH, MAX_TIME_LENGTH );
			
			RunQuery( SQLConnection, szQuery, g_szSQLError, charsmax( g_szSQLError ) );
		}
	}
	
	register_clcmd( "say", "@OnSay" )
	register_clcmd( "say_team", "@OnSay" )
}

public OnSayText( iMsg, iDestination, iEntity )
{
	g_iFUserNameChanged = register_forward( FM_ClientUserInfoChanged, "OnNameChange", 1 )
}

public OnNameChange( id )
{
	if( !is_user_connected( id ) )
	{
		return;
	}

	new szName[ MAX_NAME_LENGTH ]
	get_user_name( id, szName, charsmax( szName ) )

	if( get_pcvar_num( g_cSaveType ) == NICKNAME )
	{
		ReadData( id, SAVE );
		copy( g_iPlayer[ id ][ SaveInfo ], charsmax( g_iPlayer[ ][ SaveInfo ] ), szName )

		if( get_pcvar_num( g_cSaveMethod ) != Nvault )
		{
			ReadData( id, RESET );
		}
		
		ReadData( id, LOAD );
		ReadData( id, UPDATE );
	}

	unregister_forward( FM_ClientUserInfoChanged, g_iFUserNameChanged , 1 )
}

public client_connect( id )
{
	if( !( g_iPlayer[ id ][ BotOrHLTV ] = bool:( is_user_bot( id ) || is_user_hltv( id ) ) ) )
	{
		ReadData( id, RESET );
		
		switch( get_pcvar_num( g_cSaveType ) )
		{
			case NICKNAME: get_user_name( id, g_iPlayer[ id ][ SaveInfo ], charsmax( g_iPlayer[ ][ SaveInfo ] ) )
			case IP:       get_user_ip( id, g_iPlayer[ id ][ SaveInfo ], charsmax( g_iPlayer[ ][ SaveInfo ] ), 1 )
			case STEAMID:  get_user_authid( id, g_iPlayer[ id ][ SaveInfo ], charsmax( g_iPlayer[ ][ SaveInfo ] ) )
		}
		
		ReadData( id, LOAD );
		ReadData( id, UPDATE );
	}
}

public client_disconnected( id )
{
	if( !g_iPlayer[ id ][ BotOrHLTV ] )
	{
		g_iPlayer[ id ][ Last_Seen ] = get_systime( );
		ReadData( id, SAVE );
	}
}

@OnSay( id )
{
	static szMessage[ MAX_FMT_LENGTH ];
	read_args( szMessage, charsmax( szMessage ) ); remove_quotes( szMessage );
	
	if( equal( szMessage, "/time" ) || equal( szMessage, "/ptime" ) )
	{
		CC_SendMessage( id, "Total playing time:^4 %s", get_time_length_ex( g_iPlayer[ id ][ Time_Played ] ) ) 
	}
	else if( equal( szMessage, "/timelist" ) || equal( szMessage, "/ptimelist" ) )
	{
		TimeList( id )
	}
}

public TimeList( id )
{
	new iPlayers[ MAX_PLAYERS ], iNum, iMenu = menu_create( "Time List:", "TimeHandler" );
	get_players( iPlayers, iNum, "ch" ); SortCustom1D( iPlayers, iNum, "CompareTime" );
	
	for( new szData[ 64 ], szName[ MAX_NAME_LENGTH ], szTime[ MAX_TIME_LENGTH ], iPlayer, i; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		format_time( szTime, charsmax( szTime ), "%m/%d/%Y %H:%M:%S", g_iPlayer[ iPlayer ][ First_Seen ] )
		
		if( g_iPlayer[ iPlayer ][ Time_Played ] < 60 )
		{
			formatex( szData, charsmax( szData ), "\y%s\w Time:\r %i s\w Joined:\r %s", szName, g_iPlayer[ iPlayer ][ Time_Played ], szTime )
		}
		else 
		{
			formatex( szData, charsmax( szData ), "\y%s\w Time:\r %i m\w Joined:\r %s", szName, g_iPlayer[ iPlayer ][ Time_Played ] / 60, szTime )
		}
		
		menu_additem( iMenu, szData )
	}
	menu_display( id, iMenu );
	return PLUGIN_HANDLED;
}

public TimeHandler( id, iMenu, iItem ) 
{
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

ReadData( const id, DataTypes:iType )
{
	new szQuery[ MAX_QUERY_LENGTH ];

	switch( iType )
	{
		case SAVE:
		{
			switch( get_pcvar_num( g_cSaveMethod ) )
			{
				case Nvault:
				{
					formatex( szQuery , charsmax( szQuery ), "%i %i %i", g_iPlayer[ id ][ Time_Played ], g_iPlayer[ id ][ First_Seen ], g_iPlayer[ id ][ Last_Seen ]);
					nvault_set( g_iVault, g_iPlayer[ id ][ SaveInfo ], szQuery )
					//nvault_set_array( g_iVault, g_iPlayer[ id ][ SaveInfo ], g_iPlayer[ id ][ PlayerData:0 ], sizeof( g_iPlayer[ ] ) );
				}
				case MySQL, SQLite:
				{
					formatex( szQuery , charsmax( szQuery ), "REPLACE INTO `%s` (`Player`,`Time Played`,`First Seen`,`Last Seen`) VALUES ('%s','%i','%i','%i');",\
					SQL_TABLE, g_iPlayer[ id ][ SaveInfo ], g_iPlayer[ id ][ Time_Played ], g_iPlayer[ id ][ First_Seen ], g_iPlayer[ id ][ Last_Seen ] );
					SQL_ThreadQuery( g_SQLTuple, "QueryHandle", szQuery );
				}
			}
		}
		
		case LOAD:
		{
			switch( get_pcvar_num( g_cSaveMethod ) )
			{
				case Nvault:
				{
					new szVaultData[ 3 ][ MAX_TIME_LENGTH ];
					nvault_get( g_iVault, g_iPlayer[ id ][ SaveInfo ], szQuery, charsmax( szQuery ) )
					parse( szQuery, szVaultData[ 0 ], charsmax( szVaultData[ ] ), szVaultData[ 1 ], charsmax( szVaultData[ ] ), szVaultData[ 2 ], charsmax( szVaultData[ ] ) )
					
					g_iPlayer[ id ][ Time_Played ] = str_to_num( szVaultData[ 0 ] )
					g_iPlayer[ id ][ First_Seen ] = str_to_num( szVaultData[ 1 ] )
					g_iPlayer[ id ][ Last_Seen ] = str_to_num( szVaultData[ 2 ] )
					//nvault_get_array( g_iVault, g_iPlayer[ id ][ SaveInfo ], g_iPlayer[ id ][ PlayerData:0 ], sizeof( g_iPlayer[ ] ) );
				}
				case MySQL, SQLite:
				{
					formatex( szQuery , charsmax( szQuery ), "SELECT * FROM `%s` WHERE Player = '%s';", SQL_TABLE, g_iPlayer[ id ][ SaveInfo ] );
					new szData[ 1 ]; szData[ 0 ] = id
					SQL_ThreadQuery( g_SQLTuple, "QueryHandle", szQuery, szData, sizeof( szData ) );
				}
			}
		}
		
		case RESET:
		{
			g_iPlayer[ id ][ Time_Played ] = 0;
			g_iPlayer[ id ][ First_Seen ] = 0;
			g_iPlayer[ id ][ Last_Seen ] = 0;
			g_iPlayer[ id ][ BotOrHLTV ] = false;
			remove_task( id + TASK_TIME_PLAYED );
		}
		
		case UPDATE:
		{
			if( !g_iPlayer[ id ][ First_Seen ] ) 
			{
				g_iPlayer[ id ][ First_Seen ] = g_iPlayer[ id ][ Last_Seen ] = get_systime( );
			}
			
			set_task( 1.0, "DisplayTimePlayed", id + TASK_TIME_PLAYED, .flags = "b" );
		}
	}
}

RunQuery( Handle:SQLConnection, const szQuery[ ], szSQLError[ ], iErrLen )
{
	new Handle:iQuery = SQL_PrepareQuery( SQLConnection , szQuery );
	
	if( !SQL_Execute( iQuery ) )
	{
		SQL_QueryError( iQuery, szSQLError, iErrLen );
		set_fail_state( szSQLError );
	}
	
	SQL_FreeHandle( iQuery );
}

public QueryHandle( iFailState, Handle:iQuery, const szError[ ], iErrCode, szData[ ], iDataSize )
{
	switch( iFailState )
	{
		case TQUERY_CONNECT_FAILED: { log_amx( "[SQL Error] Connection failed (%i): %s", iErrCode, szError ); return; }
		case TQUERY_QUERY_FAILED: { log_amx( "[SQL Error] Query failed (%i): %s", iErrCode, szError ); return; }
	}
	
	new id = szData[ 0 ];
	
	if( SQL_NumResults( iQuery ) )
	{
		g_iPlayer[ id ][ Time_Played ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Time Played" ) )
		g_iPlayer[ id ][ First_Seen ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "First Seen" ) )
		g_iPlayer[ id ][ Last_Seen ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Last Seen" ) )
	}
} 

public CompareTime( id, Identity )
{
	return g_iPlayer[ Identity ][ Time_Played ] - g_iPlayer[ id ][ Time_Played ]
}

public DisplayTimePlayed( id )
{
	g_iPlayer[ ( id -= TASK_TIME_PLAYED ) ][ Time_Played ]++;
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

public plugin_end( )
{
	if( get_pcvar_num( g_cSaveMethod ) )
	{
		SQL_FreeHandle( g_SQLTuple );
	}
	else
	{
		nvault_close( g_iVault );
	}
}
