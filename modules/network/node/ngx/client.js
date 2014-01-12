// File: node/ngx/client.js
// Desc: talk to browser/client to capture requests

'use strict';

// Imports
var config = module.parent.config,
    socketio = require( 'socket.io' ),
    request = require( './request.js' );;


// Client
// talks to browser via socket.io
var client = {
    start: function( requests, port ) {
        // requests => client
        // socket.io listen for clients, add to valid request
        var listen_clients = socketio.listen( port, { 'log level': 1 });
        if( listen_clients )
            console.log( '[Client Listen]: Started' );
        else
            throw new Error( 'Cannot bind on client port' );

        listen_clients.sockets.on( 'connection', function( client ) {
            // make request
            client.on( 'capture_request', function( data ) {
                // try to convert to json
                try {
                    // get data
                    var data = JSON.parse( data );

                    // validate
                    if( !data.key || !data.user )
                        throw( 'Missing key or user' );
                    if( !requests[data.key] )
                        throw( 'Invalid request key' );

                    var req = requests[data.key];

                    // user matches?
                    if( req.user.id != data.user.id )
                        throw( 'User id mismatch' );
                    for( var i = 1; i <= config.user_keys; i++ )
                        if( !data.user['key' + i] || data.user['key' + i] != req.user['key' + i] )
                            throw( 'Invalid user keys' );

                    // tell client we're going ahead
                    client.emit( 'request_start', 'ACCEPTED' );
                    console.log( '[Request: ' + data.key + '] Client connected' );

                    // make our req, callbacks => client
                    request.new( data.key, client, req.server, req.actions, {
                        data: function( data ) {
                            client.emit( 'command_data', data );
                        },
                        cmdStart: function( command ) {
                            client.emit( 'command_start', command );
                        },
                        cmdEnd: function( command, code, parse_data ) {
                            client.emit( 'command_end', { command: command, signal: code, parse_data: parse_data } );
                        },
                        end: function() {
                            client.emit( 'request_end', 'COMPLETE' );
                        },
                        error: function( err ) {
                            client.emit( 'request_error', err );
                        }
                    });

                    delete requests[data.key];
                    console.log( '[Client Listen]: request captured ' + data.key )
                } catch( e ) {
                    client.emit( 'request_start', 'INVALID REQUEST: ' + e );
                }
            });
        });
    }
}
module.exports = client;