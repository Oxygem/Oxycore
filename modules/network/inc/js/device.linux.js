var linux = {};

//service start
linux.start = function() {
	//capture status request
	if( oxypanel.device.status_request_key ) {
        server.disable();
		this.status( oxypanel.device.status_request_key );
	} else {
        server.showError( oxypanel.device.status_request_error );
    }
}

//server status
linux.status = function( key ) {
    server.showCommand( 'Updating status...' );

    //setup tab
    var tab = $( 'div[data-tab=overview] .content' );
    tab.html( '<div class="third"><h4>Loads:</h4><div id="status_text"><img src="/inc/core/img/loader.gif" alt="loading..." /></div></div>' );
    tab.append( '<div class="third"><h4>Memory:</h4><div id="memory_bars"><img src="/inc/core/img/loader.gif" alt="loading..." /></div></div>' );
    tab.append( '<div class="third last"><h4>Disk Space:</h4><div id="disk_bars"><img src="/inc/core/img/loader.gif" alt="loading..." /></div></div>' );

	//make new request
    ssh.new( key, function( data ) {
        switch( this.command ) {
        	case 'uptime':
        		var re = RegExp( 'load average: ([0-9\.\s, ]+)' );
                var uptime = re.exec( data );
                if( !uptime ) {
                    console.log( uptime + ' ' + data );
                    uptime = [ false, 'Error' ];
                }
        		$( '#status_text' ).append( uptime[1] );

                var re = RegExp( 'up ([aA-zZ0-9\s ]+),' );
                var uptime = re.exec( data );
                if( !uptime ) {
                    console.log( uptime + ' ' + data );
                    uptime = [ false, 'Error' ];
                }
                $( '#status_text' ).append( '<br />Uptime: ' + uptime[1] );

        		$( '#status_text img' ).remove();
        		break;
        	case 'disk':
        		var partitions = data.split( '\n' );
        		for( i = 1; i < partitions.length; i++ ) {
                    part = server.tabsToArray( partitions[i] );
        			if( part.length == 6 && part[0].substring( 0, 1 ) == '/' ) {
        				$( '#disk_bars' ).append( server.buildBar( part[5], part[2], part[1] ) );
        			}
        		}

        		//remove disk bars image
        		$( '#disk_bars img' ).remove();
        		break;
        	case 'memory':
        		var partitions = data.split( '\n' );
        		var total = 0;
        		for( i = 1; i < partitions.length; i++ ) {
        			part = server.tabsToArray( partitions[i] );
        			if( part.length == 7 ) {
        				total = part[1];
        			}
        			if( part.length == 4 ) {
        				if( part[0] == 'Swap:' )
        					$( '#memory_bars' ).append( server.buildBar( 'Swap', part[2], part[1] ) );
        				else
        					$( '#memory_bars' ).append( server.buildBar( 'Real', part[2], total ) );
        			}
        		}

        		//remove memory bars image
        		$( '#memory_bars img' ).remove();
        		break;
        	default:
        		console.log( 'Uncaught data: ' + this.command + ': ' + data );
        }
   	//error function
    }, function( err ) {
        server.showError( err );
        server.enable();
    //complete function
    }, function() {
        server.completeCommand( 'success', 'Status complete' );
        server.enable();
    });
}

//add our commands to server
$( document ).ready( function() {
    server.addCommands( linux );
});