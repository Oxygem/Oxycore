$.each( $( 'a.show' ), function( key, show ) {
	//get bits
	var show = $( show ),
		select = $( '#' + $( show.parent() ).attr( 'for' ) ),
		type = $( show ).attr( 'data-object-type' ),
		module = $( show ).attr( 'data-object-module' ),
		current = $( show ).attr( 'data-current-id' ),
		current_in_owned = false;

	//work out if current is in existing list
	if( current > 0 ) {
		$.each( $( 'option', select ), function( key, opt ) {
			if( $( opt ).attr( 'value' ) == current ) {
				current_in_owned = true;
			}
		});
		//not in owned list?
		if( !current_in_owned ) {
			select.after( '<div class="message warning">This object is currently assigned to <a href="/' + type + '/' + current + '">a ' + type + '</a> you don\'t own. Updating will remove the ' + type + ', if you have permission you can retrieve the ' + type + ' with the show all function above.</div>' );
		}
	}

	//bind clicks
	show.bind( 'click', function( ev ) {
		ev.preventDefault();

		if( show.html() == 'Show All' ) {
			$.ajax( window.location.origin + '/' + module + '/' + type + 's/all?_api', {
				type: 'GET',
				error: function( req, status, error ) {
					console.error( error );
				},
				success: function( data, status ) {
					showall.createSelect( select, type, current, data );
					show.removeClass( 'red' ).html( 'Show Owned' );
				}
			});
		} else {
			$.ajax( window.location.origin + '/' + module + '/' + type + 's?_api', {
				type: 'GET',
				error: function( req, status, error ) {
					console.error( error );
				},
				success: function( data, status ) {
					showall.createSelect( select, type, current, data );
					show.addClass( 'red' ).html( 'Show All' );

				}
			});
		}
	});
});

var showall = {
	createSelect: function( select, type, current, data ) {
		select.html( '<option value="0">Select ' + type.charAt( 0 ).toUpperCase() + type.slice( 1 ) + '</option>' );
		for( key in data[type + 's'] ) {
			var item = data[type + 's'][key];
			if( item.id == current ) {
				select.append( '<option value="' + item.id + '" selected>' + item.name + '</option>' );
			} else {
				select.append( '<option value="' + item.id + '">' + item.name + '</option>' );
			}
		}
		select.append( '<option value="0">None</option>' );
	}
}