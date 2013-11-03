var popinfos = {};

util.each( document.querySelectorAll( 'a.pop' ), function( key, link ) {
	var type = link.getAttribute( 'data-object-type' ),
		id = link.getAttribute( 'data-object-id' );

	link.addEventListener( 'mouseover', function( ev ) {
		var self = this,
			type = this.getAttribute( 'data-object-type' ),
			id = this.getAttribute( 'data-object-id' );

		//cached popinfo?
		if( popinfos[type + id] != undefined ) {
			return this.querySelector( 'strong' ).innerHTML = popinfos[type + id];
		}

		//make request
		util.ajax( 'GET', window.location.origin + '/' + type + '/' + id + '?_api', {
			error: function( status, error ) {
				console.error( error );
			},
			success: function( status, data ) {
				self.querySelector( 'strong' ).innerHTML = data[type].name;

				//cache
				popinfos[type + id] = data[type].name;
			}
		});
	});

	//add html
	link.innerHTML ='<span class="container"><strong><img src="/inc/core/img/loader.gif" /></strong><span class="meta">' + type.charAt(0).toUpperCase() + type.slice(1) + '</span><span class="arrow"></span></span>' + link.innerHTML;
});