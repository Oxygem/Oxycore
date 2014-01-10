/*

	 __  __     ______   __     __                __     ______
	/\ \/\ \   /\__  _\ /\ \   /\ \              /\ \   /\  ___\
	\ \ \_\ \  \/_/\ \/ \ \ \  \ \ \____   __   _\_\ \  \ \___  \
	 \ \_____\    \ \_\  \ \_\  \ \_____\ /\_\ /\_____\  \/\_____\
	  \/_____/     \/_/   \/_/   \/_____/ \/_/ \/_____/   \/_____/

	util.js
	(c) Nick Barrett 2014, MIT license
	https://github.com/Fizzadar/util.js
*/

var util = (function() {
	var util = {
		// Ajax call
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


		// Loop object/array
		each: function( object, each_func ) {
			if( typeof object.length == 'number' ) {
				for( var i = 0; i < object.length; i++ ) {
					each_func( i, object[i] );
				}
			} else {
				for( key in object ) {
					each_func( key, object[key] );
				}
			}
		},


		// Search object/array
		search: function( object, search_func ) {
			var found_key;
			this.each( object, function( key, value ) {
				if( search_func( key, value, found_key ) ) {
					found_key = key;
				}
			});

			return this[found_key] || null;
		},


		// Get cookie
		getCookie: function( key ) {

		},

		// Set cookie
		setCookie: function( key, value ) {

		},


		// Get util elements
		elements: function( selector, target ) {
			var target = target || document,
				elements = target.querySelectorAll( selector ),
				out = [],
				self = this;

			for( var i = 0; i < elements.length; i++ ) {
				out.push( this.element( false, elements[i] ));
			}

			out.css = function( data ) {
				self.each( this, function( key, element ) {
					element.css( data );
				});
			}
			out.animate = function( data, duration ) {
				self.each( this, function( key, element ) {
					element.animate( data, duration );
				});
			}
			out.addClass = function( class_name ) {
				self.each( this, function( key, element ) {
					element.addClass( class_name );
				});
			}
			out.removeClass = function( class_name ) {
				self.each( this, function( key, element ) {
					element.removeClass( class_name );
				});
			}

			return out;
		},


		// Get util element
		element: function( selector, element, target ) {
			var target = target || document,
				element = element || target.querySelector( selector ),
				self = this;

			element.css = function( data ) {
				for( key in data ) {
					this.style.setProperty( key, data[key] );
				}
			}
			element.animate = function( data, duration ) {

			}

			// Get data-<key> attributes
			element.get = function( key ) {
				return this.getAttribute( 'data-' + key );
			}
			// Set data-<key> attributes
			element.set = function( key, value ) {
				this.setAttribute( 'data-' + key, value );
			}

			element.append = function( content ) {
				this.innerHTML += content;
			},
			element.prepend = function( content ) {
				this.innerHTML = this.innerHTML + content;
			}

			element.addClass = function( css_class ) {
				this.className += ' ' + css_class;
			}
			element.removeClass = function( css_class ) {
				this.className = this.className.replace( new RegExp( ' ?' + css_class, 'g' ), '' );
			}

			// Run util.elements with this element as the target
			element.elements = function( selector ) {
				return self.elements( selector, this );
			}
			element.element = function( selector ) {
				return self.element( selector, false, this );
			}

			return element;
		}
	}

	return util;
})();