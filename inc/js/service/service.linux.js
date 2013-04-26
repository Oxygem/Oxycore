var linux = {};

//service start
linux.start = function() {
	//capture status request
	if( oxypanel.service.status_request_key ) {
        service.disable();
		this.status( oxypanel.service.status_request_key );
	} else {
        service.showError( status_request_error );
    }
}

//firewall list
linux.list_firewall = function( key ) {
    service.showCommand( 'Listing firewall rules...' );

    ssh.new( key, function( data ) {
        $( '#tabs .firewall .content' ).html( '<pre>' + data + '</pre>' );
    }, function( err ) {
        service.showError( err );
        service.enable();
    }, function() {
        service.completeCommand( 'success', 'Complete' );
        service.enable();
    });
}

//update packages
linux.update_packages = function( key ) {
    service.showCommand( 'Updating packages...' );

    ssh.new( key, function( data ) {
        $( '#tabs .packages .content' ).html( '<pre>' + data + '</pre>' );
    }, function( err ) {
        service.showError( err );
        service.enable();
    }, function() {
        service.completeCommand( 'success', 'Complete' );
        service.enable();
    });
}

//search packages
linux.search_packages = function( key ) {
    service.showCommand( 'Searching packages...' );

    ssh.new( key, function( data ) {
        $( '#tabs .packages .content' ).html( '<pre>' + data + '</pre>' );
    }, function( err ) {
        service.showError( err );
        service.enable();
    }, function() {
        service.completeCommand( 'success', 'Complete' );
        service.enable();
    });
}

//install package
linux.install_package = function( key ) {
    service.showCommand( 'Installing package...' );

    ssh.new( key, function( data ) {
        $( '#tabs .packages .content' ).html( '<pre>' + data + '</pre>' );
    }, function( err ) {
        service.showError( err );
        service.enable();
    }, function() {
        service.completeCommand( 'success', 'Complete' );
        service.enable();
    });
}

//service status
linux.status = function( key ) {
    service.showCommand( 'Updating status...' );

    $( '#status_text' ).html( '<img src="/inc/img/loader.gif" alt="loading..." />' );
    $( '#disk_bars' ).html( '<img src="/inc/img/loader.gif" alt="loading..." />' );
    $( '#memory_bars' ).html( '<img src="/inc/img/loader.gif" alt="loading..." />' );

	//make new request
    ssh.new( key, function( data ) {
        switch( this.command ) {
        	case 'uptime':
        		var re = RegExp( 'load average: ([0-9\.\s, ]+)' );
        		$( '#status_text' ).append( re.exec( data )[1] );
        		$( '#status_text img' ).remove();
        		break;
        	case 'disk':
        		var partitions = data.split( '\n' );
        		for( i = 1; i < partitions.length; i++ ) {
                    part = service.tabsToArray( partitions[i] );
        			if( part.length == 6 ) {
        				$( '#disk_bars' ).append( service.buildBar( part[0], part[2], part[1] ) );
        			}
        		}

        		//remove disk bars image
        		$( '#disk_bars img' ).remove();
        		break;
        	case 'memory':
        		var partitions = data.split( '\n' );
        		var total = 0;
        		for( i = 1; i < partitions.length; i++ ) {
        			part = service.tabsToArray( partitions[i] );
        			if( part.length == 7 ) {
        				total = part[1];
        			}
        			if( part.length == 4 ) {
        				if( part[0] == 'Swap:' )
        					$( '#memory_bars' ).append( service.buildBar( 'Swap', part[2], part[1] ) );
        				else
        					$( '#memory_bars' ).append( service.buildBar( 'Real', part[2], total ) );
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
        service.showError( err );
        service.enable();
    //complete function
    }, function() {
        service.completeCommand( 'success', 'Status complete' );
        service.enable();
    });
}


//add our commands to service
$( document ).ready( function() {
    service.addCommands( 'linux' );

    //bind so firewall tab auto loads rules
    $( 'li.service_tab[data-tab=firewall] a' ).bind( 'click', function( ev ) {
        if( !service.disabled )
            service.commandRequest( 'list_firewall' );
    });
});