//ssh object
var ssh = {
    //store current request LIMIT 1 at a time! (might be changed?)
    request: false,
    error: false,
    complete: false,

    //make a request
    new: function( key, data_func, error_func, complete_func ) {
        //no socket? active request?
        if( !this.socket || this.request != false )
            return false;
        this.request = data_func;
        this.error = error_func;
        this.complete = complete_func;
        //user keys
        var user = {};
        for( var i = 1; i <= oxypanel.user_strength; i++ ) {
            user['key' + i] = $.cookie( 'key' + i );
        }
        //send request to node
        this.socket.emit( 'capture_request', JSON.stringify({
            key: key,
            user: user
        }));
    },

    //end a request
    end: function() {
        this.complete();
        this.request = false;
        this.error = false;
        this.complete = false;
    }
}

//connect to node & build ssh socket
$( document ).ready( function() {
    //node port defined (should be when included)
    if( oxypanel.node_port ) {
        //connect
        ssh.socket = io.connect( 'http://' + window.location.hostname + ':' + oxypanel.node_port );

        //fail to connect?
        ssh.socket.on( 'error', function( err ) {
            server.showError( 'Could not connect to Node SSH-proxy' );
        });

        //connected
        ssh.socket.on( 'connect', function() {
            console.log( 'Connected to Node' );

            //error
            ssh.socket.on( 'error', function( data ) {
                if( ssh.error )
                    ssh.error( data );
            });

            //capture request start
            ssh.socket.on( 'request_start', function( data ) {
                if( ssh.request ) {
                    if( data != 'ACCEPTED' ) {
                        console.error( data );
                    }
                } else {
                    console.log( 'Uncaptured request_start: ' + data );
                }
            });
            //capture request end
            ssh.socket.on( 'request_end', function( data ) {
                if( ssh.request ) {
                    ssh.end();
                } else {
                    console.log( 'Uncaptured request_end: ' + data );
                }
            });

            //add command (response)
            ssh.socket.on( 'command_add', function( data ) {
                if( ssh.request ) {

                } else {
                    console.log( 'Uncaptured command_add: ' + data );
                }
            });
            //command start
            ssh.socket.on( 'command_start', function( data ) {
                if( ssh.request ) {
                    console.log( 'Command start: ' + data.out + ' : ' + data.in );
                    ssh.command = data.out;
                    ssh.buffer = '';
                } else {
                    console.log( 'Uncaptured command_start: ' + data.out );
                }
            });
            //command data (ALWAYS a string)
            ssh.socket.on( 'command_data', function( data ) {
                if( ssh.request ) {
                    $( '#device_console.terminal pre' ).append( data );
                    $( '#device_console.terminal pre' ).scrollTop( $( '#device_console.terminal pre' )[0].scrollHeight );
                    ssh.buffer = ssh.buffer + String( data );
                } else {
                    console.log( 'Uncaptured command_data: ' + data );
                }
            });
            //command end
            ssh.socket.on( 'command_end', function( data ) {
                if( ssh.request ) {
                    ssh.request( ssh.buffer );
                    console.log( 'Command complete: ' + ssh.command );
                    delete ssh.command;
                } else {
                    console.log( 'Uncaptured command_end: ' + data );
                }
            });

            //service?
            if( server )
                server.start();
        });
    }
});