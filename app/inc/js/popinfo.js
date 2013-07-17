var popinfos = {};

$.each( $( 'a.pop' ), function( key, pop ) {
	var link = $( pop ),
		type = link.attr( 'data-object-type' ),
		id = link.attr( 'data-object-id' );

	link.bind( 'mouseover', function( ev ) {
		var link = $( ev.delegateTarget ),
			type = link.attr( 'data-object-type' ),
			id = link.attr( 'data-object-id' );

		//cached popinfo?
		if( popinfos[type + id] != undefined ) {
			return $( 'strong', link ).html( popinfos[type + id] );
		}

		//make request
		$.ajax( window.location.origin + '/' + type + '/' + id + '?_api', {
			type: 'GET',
			error: function( req, status, error ) {
				console.error( error );
			},
			success: function( data, status ) {
				$( 'strong', link ).html( data[type].name );

				//cache
				popinfos[type + id] = data[type].name;
			}
		});
	});

	//add html
	link.prepend( '<span class="container"><strong><img src="/inc/core/img/loader.gif" /></strong><span class="meta">' + type.charAt(0).toUpperCase() + type.slice(1) + '</span><span class="arrow"></span></span>' );
});