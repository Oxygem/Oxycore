// File: node/ngx/server.js
// Desc: talks to luawa/nginx to add + capture requests

'use strict';

// Imports
var config = module.parent.config,
    net = require( 'net' ),
    randomstring = require( 'randomstring' ),
    request = require( './request.js' );


// Server
// talks to oxypanel's lua/nginx server
var server = {
    start: function( requests, port ) {
        // nginx => requests
        // simple socket/net listen for requests from nginx
        var listen_nginx = net.createServer( function( ngx ) {
            // text > binary
            ngx.setEncoding( 'utf8' );
            // receive json bundle
            ngx.on( 'data', function( data ) {
                // try to convert to json, if not valid w/e (up to lua to format correctly)
                try {
                    // get data
                    var data = JSON.parse( data );

                    // validate
                    if( !data.share_key || data.share_key != config.share_key )
                        throw( 'share_key mismatch' );

                    // key set? capturing, callbacks => server
                    if( data.key && requests[data.key] ) {
                        ngx.write( JSON.stringify( { event: 'request_start', data: 'ACCEPTED' } ) + '\n' );
                        console.log( '[Nginx Listen]: Request captured ' + data.key );

                        // make & return our req, callbacks => nginx
                        request.new( data.key, ngx, requests[data.key].server, requests[data.key].actions, {
                            data: function( data ) {
                                ngx.write( JSON.stringify( { event: 'command_data', data: data } ) + '\n' );
                            },
                            cmdStart: function( command ) {
                                ngx.write( JSON.stringify( { event: 'command_start', data: command } ) + '\n' );
                            },
                            cmdEnd: function( command, code, parse_data ) {
                                ngx.write( JSON.stringify( { event: 'command_end', data: { command: command, signal: code } } ) + '\n' );
                            },
                            end: function( data ) {
                                ngx.write( JSON.stringify( { event: 'request_end', data: 'COMPLETE' } ) + '\n' );
                                ngx.end();
                            },
                            error: function( err ) {
                                ngx.write( JSON.stringify( { event: 'request_error', data: err } ) + '\n' );
                                ngx.end();
                            }
                        });

                        delete requests[data.key];


                    // Adding new request
                    } else {
                        // check basics
                        if( !data.user || !data.commands || !data.server )
                            throw( 'Missing user, commands or server' );
                        for( var i = 1; i <= config.user_keys; i++ )
                            if( !data.user['key' + i] )
                                throw( 'Missing user key: ' + i );

                        // generate key for request
                        var key = randomstring.generate( 64 );
                        // build our request
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
                    }
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
        listen_nginx.listen( port, function() { console.log( '[Nginx Listen]: Started' ) });

        // small loop (evey minute) to cleanup dead requests (more than 5 min old)
        setInterval( function() {
            for( var key in requests ) {
                var req = requests[key];
                if( new Date().getTime() - req.time > 300000 ) {
                    console.log( '[Request Cleanup]: cleaning up: ' + key );
                    delete requests[key];
                }
            }
        }, 60000 );
    }
}
module.exports = server;