//import global config
var config = module.parent._autoconf;

//import external modules
var net = require( 'net' ),
    socketio = require( 'socket.io' ),
    randomstring = require( 'randomstring' );

//import local modules
var request = require( './app/request.js' ),
    ssh = require( './app/ssh.js' );

//store tmp requests (after coming in from nginx but before going to browser [ie before we ssh-connect])
var requests = [];




//socket.io listen for clients, add to valid request
var listen_clients = socketio.listen( config.client_port, { 'log level': 1 });
if( listen_clients ) console.log( '[Client Listen]: Started' );
listen_clients.sockets.on( 'connection', function( client ) {
    //make request
    client.on( 'capture_request', function( data ) {
        //try to convert to json
        try {
            //get data
            var data = JSON.parse( data );

            //validate
            if( !data.key || !data.user )
                throw( 'Missing key or user' );
            if( !requests[data.key] )
                throw( 'Invalid request key' );

            var req = requests[data.key];

            //user matches?
            if( req.user.id != data.user.id )
                throw( 'User id mismatch' );
            for( i = 1; i <= config.user_strength; i++ )
                if( !data.user['key' + i] || data.user['key' + i] != req.user['key' + i] )
                    throw( 'Invalid user keys' );

            //tell client we're going ahead
            client.emit( 'request_start', 'ACCEPTED' );
            console.log( '[Request: ' + data.key + '] Client connected' );

            //make our req onData, onCmdStart, onCmdEnd, onEnd, onError
            request.new( data.key, req.server, req.actions,
                //on data
                function( data ) {
                    client.emit( 'command_data', data + '' );
                },
                //on cmd start
                function( command ) {
                    client.emit( 'command_start', command );
                },
                //on cmd end
                function( command ) {
                    client.emit( 'command_end', command );
                },
                //on end
                function() {
                    client.emit( 'request_end', 'ENDED' );
                },
                //on error
                function( err ) {
                    client.emit( 'request_error', err );
                }
            );
        } catch( e ) {
            client.emit( 'request_start', 'INVALID REQUEST: ' + e );
        }
    });
});







//simple socket/net listen for requests from nginx
var listen_nginx = net.createServer( function( ngx ) {
    //text > binary
    ngx.setEncoding( 'utf8' );
    //receive json bundle
    ngx.on( 'data', function( data ) {
        //try to convert to json, if not valid w/e (up to lua to format correctly)
        try {
            //get data
            var data = JSON.parse( data );

            //validate
            if( !data.share_key )
                throw( 'Missing share_key' );

            //adding user request
            if( !data.user || !data.commands || !data.server )
                throw( 'Missing user, commands or server' );
            if( data.share_key != config.share_key )
                throw( 'share_key mismatch' );
            for( i = 1; i <= config.user_strength; i++ )
                if( !data.user['key' + i] )
                    throw( 'Missing user key: ' + i );

            //generate key for request
            var key = randomstring.generate( 64 );
            //build our request
            requests[key] = {
                actions: data.commands,
                user: data.user,
                server: data.server
            }

            //drop connection once data added
            ngx.write( 'ACCEPTED\n' + key + '\n' );
            ngx.end();
            console.log( '[Nginx Listen]: Request added ' + key );
        } catch( e ) {
            //cya!
            ngx.write( 'INVALID REQUEST\n' );
            ngx.end();
            console.log( '[Nginx Listen]: Invalid Request: ' + e );
        }
    });
});
listen_nginx.on( 'error', function( e ) {
    console.log( e );
});
listen_nginx.listen( config.server_port, function() { console.log( '[Nginx Listen]: Started' ) });