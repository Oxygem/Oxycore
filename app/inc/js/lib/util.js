// Useful functions
var util = {
	each: function( data, callback ) {
		// Array
		if( typeof( data.length ) == 'number' ) {
			for( var i = 0; i < data.length; i++ ) {
				callback( i, data[i] );
			}
			return;
		}
		// Object
		for( key in data ) {
			callback( key, data[key] );
		}
	},

	ajax: function( method, url, options ) {
		var req = new XMLHttpRequest();
		req.onreadystatechange = function() {
			if( req.readyState == 4 ) {
				if( req.status != 200 )
					return options.error( req.status, 'Bad HTTP response' );

				try {
					var data = JSON.parse( req.responseText );
					return options.success( req.status, data );
				} catch( e ) {
					return options.error( req.status, e.message );
				}
			}
		}
		req.open( method, url, options.async ? true : false );
		req.send();
	},

	approach: function( start, finish, step, callback ) {

	}
};

// Set an elements style
// data = { style_name: style_value }
Element.prototype.css = function( data ) {
	for( key in data ) {
		this.style.setProperty( key, data[key] );
	}
}
// Animate an element
Element.prototype.animate = function( duration, data ) {
	console.log('hi');
}