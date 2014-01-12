'use strict';

//ssh object
var ssh = {
    init: false,
    $console: util.element( '#device_console pre' ),

    //make a request
    new: function( key, options ) {
        //no socket? active request?
        if( !this.socket )
            return false;
        this.onCmdEnd = options.cmdEnd;
        this.onCmdStart = options.cmdStart;
        this.onError = options.error;
        this.onData = options.data;
        this.onStart = options.start;
        this.onEnd = options.end;
        //user keys
        var user = {};
        for( var i = 1; i <= oxypanel.user_keys; i++ ) {
            user['key' + i] = util.getCookie( 'key' + i );
        }
        //send request to node
        this.socket.emit( 'capture_request', JSON.stringify({
            key: key,
            user: user
        }));
    },

    //end a request
    end: function( data ) {
        this.onEnd( data );
        this.onCmdEnd = false;
        this.onCmdStart = false;
        this.onData = false;
        this.onError = false;
        this.onStart = false;
        this.onEnd = false;
    }
};

//connect to node & build ssh socket
//node port defined (should be when included)
if( oxypanel.node_port ) {
    //connect
    ssh.socket = io.connect( 'http://' + window.location.hostname + ':' + oxypanel.node_port );

    //fail to connect?
    ssh.socket.on( 'error', function( error ) {
        device.showError( 'Could not connect to Node SSH-proxy' );
    });

    //connected
    ssh.socket.on( 'connect', function() {
        debug.log( 'Connected to Node' );

        if( ssh.init )
            return;

        //error
        ssh.socket.on( 'request_error', function( data ) {
            ssh.onError( data );
        });

        //capture request start
        ssh.socket.on( 'request_start', function( data ) {
            if( data != 'ACCEPTED' ) {
                return console.log( data );
            }
            ssh.onStart( data );
        });

        //capture request end
        ssh.socket.on( 'request_end', function( data ) {
            ssh.onEnd( data );
        });

        //command start
        ssh.socket.on( 'command_start', function( data ) {
            ssh.onCmdStart( data );
        });

        //command data - just for console
        ssh.socket.on( 'command_data', function( data ) {
            ssh.onData( data );
        });

        //command end
        ssh.socket.on( 'command_end', function( data ) {
            ssh.onCmdEnd( data );
        });

        ssh.init = true;
    });
}