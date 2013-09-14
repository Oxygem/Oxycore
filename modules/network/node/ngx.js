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


//small loop (evey minute) to cleanup dead requests (more than 5 min old)
setInterval( function() {
    for( key in requests ) {
        var req = requests[key];
        if( new Date().getTime() - req.time > 300000 ) {
            console.log( '[Request Cleanup]: cleaning up: ' + key );
            delete requests[key];
        }
    }
}, 60000 );

//nginx => requests
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
            if( !data.share_key || data.share_key != config.share_key )
                throw( 'share_key mismatch' );

            //key set? capturing
            if( data.key && requests[data.key] ) {
                //make & return our req, callbacks => nginx
                request.new( data.key, ngx, requests[data.key].server, requests[data.key].actions,
                    //on data
                    function( data ) {
                        ngx.write( JSON.stringify( { 'event': 'command_data', 'data': data + '' } ) + '\n' );
                    },
                    //on cmd start
                    function( command ) {
                        ngx.write( JSON.stringify( { 'event': 'command_start', 'data': command } ) + '\n' );
                    },
                    //on cmd end
                    function( command, code ) {
                        ngx.write( JSON.stringify( { 'event': 'command_end', 'data': { 'cmd': command, 'signal': code } } ) + '\n' );
                    },
                    //on end
                    function() {
                        ngx.write( JSON.stringify( { 'event': 'request_end', 'data': 'COMPLETE' } ) + '\n' );
                        ngx.end();
                    },
                    //on error
                    function( err ) {
                        ngx.write( JSON.stringify( { 'event': 'request_error', 'data': err } ) + '\n' );
                        ngx.end();
                    }
                );

                delete requests[data.key];
                return console.log( '[Nginx Listen]: request captured ' + data.key );
            }

            //adding user request
            if( !data.user || !data.commands || !data.server )
                throw( 'Missing user, commands or server' );
            for( i = 1; i <= config.user_strength; i++ )
                if( !data.user['key' + i] )
                    throw( 'Missing user key: ' + i );

            //generate key for request
            var key = randomstring.generate( 64 );
            //build our request
            requests[key] = {
                actions: data.commands,
                user: data.user,
                server: data.server,
                time: new Date().getTime()
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





//requests => client
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

            //make our req, callbacks => client
            request.new( data.key, client, req.server, req.actions,
                //on data
                function( data ) {
                    client.emit( 'command_data', data + '' );
                },
                //on cmd start
                function( command ) {
                    client.emit( 'command_start', command );
                },
                //on cmd end
                function( command, code ) {
                    client.emit( 'command_end', { command: command, signal: code } );
                },
                //on end
                function() {
                    client.emit( 'request_end', 'COMPLETE' );
                },
                //on error
                function( err ) {
                    client.emit( 'request_error', err );
                }
            );

            delete requests[data.key];
            console.log( '[Client Listen]: request captured ' + data.key )
        } catch( e ) {
            client.emit( 'request_start', 'INVALID REQUEST: ' + e );
        }
    });
});