// Useful functions
var util = {
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
	for( key in data )
		this.style.setProperty( key, data[key] );
}
// Animate an element
Element.prototype.animate = function( duration, data ) {
	console.log('hi');
}

// Loop an object
Object.prototype.each = function( callback ) {
	// Array
	if( typeof( this.length ) == 'number' )
		for( var i = 0; i < this.length; i++ )
			callback( i, this[i] );
	// Object
	else
		for( key in this )
			if( this.hasOwnProperty( key ) )
				callback( key, this[key] );
}