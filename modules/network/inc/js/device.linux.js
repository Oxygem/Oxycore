var linux = {};

//service start
linux.start = function() {
    //status cached in last 10 mins?
    var cache_check = localStorage.getItem( 'status_time_' + window.location.pathname );
    if( cache_check && cache_check > ( new Date().getTime() - 600000 ) ) {
        return $( 'div[data-tab=overview] .content' ).html( localStorage.getItem( 'status_' + window.location.pathname ) );
    }

	//capture status request
	if( oxypanel.device.status_request_key ) {
        device.disable();
		this.status( oxypanel.device.status_request_key );
	} else if( oxypanel.device.status_request_error ) {
        device.showError( oxypanel.device.status_request_error );
    }
};

//device status
linux.status = function( key ) {
    device.showCommand( 'Updating status...' );

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
                    part = device.tabsToArray( partitions[i] );
        			if( part.length == 6 && part[0].substring( 0, 1 ) == '/' ) {
        				$( '#disk_bars' ).append( device.buildBar( part[5], part[2], part[1] ) );
        			}
        		}

        		//remove disk bars image
        		$( '#disk_bars img' ).remove();
        		break;
        	case 'memory':
        		var partitions = data.split( '\n' );
        		var total = 0;
        		for( i = 1; i < partitions.length; i++ ) {
        			part = device.tabsToArray( partitions[i] );
        			if( part.length == 7 ) {
        				total = part[1];
        			}
        			if( part.length == 4 ) {
        				if( part[0] == 'Swap:' )
        					$( '#memory_bars' ).append( device.buildBar( 'Swap', part[2], part[1] ) );
        				else
        					$( '#memory_bars' ).append( device.buildBar( 'Real', part[2], total ) );
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
        device.showError( err );
        device.enable();
    //complete function
    }, function() {
        device.completeCommand( 'success', 'Status complete' );

        //cache status
        localStorage.setItem( 'status_time_' + window.location.pathname, new Date().getTime() );
        localStorage.setItem( 'status_' + window.location.pathname, $( 'div[data-tab=overview] .content' ).html() );

        device.enable();
    });
};

//add our commands to server
$( document ).ready( function() {
    device.addCommands( linux );
});