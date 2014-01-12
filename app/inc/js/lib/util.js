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

(function() {
	var util = {
		// Ajax call
		ajax: function( method, url, options ) {
			var req = new XMLHttpRequest();
			req.open( method, url, options.sync ? false : true );

			if( method == 'POST' && options.data ) {
				var encoded_data = [];

				this.each( options.data, function( key, value ) {
					encoded_data.push( encodeURIComponent( key ) + '=' + encodeURIComponent( value ));
				});
				encoded_data = encoded_data.join( '&' );

				options.data = encoded_data;
				req.setRequestHeader( 'Content-type', 'application/x-www-form-urlencoded' );
			}

			req.onreadystatechange = function() {
				if( req.readyState == 4 ) {
					if( req.status != 200 ) {
						return options.error( req.status, 'Bad HTTP response' );
					}

					try {
						var data = JSON.parse( req.responseText );
						return options.success( req.status, data );
					} catch( e ) {
						return options.error( req.status, e.message, req.responseText );
					}
				}
			}

			req.send( options.data ? options.data : null );
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


		// Parse cookies
		parseCookies: function() {
			this.cookies = {};
			var pairs = document.cookie.split( ';' ),
				self = this;

			this.each( pairs, function( key, value ) {
				var data = value.split( '=' );
				self.cookies[data[0].trim()] = data[1].trim();
			});
		},

		// Get cookie
		getCookie: function( key ) {
			if( !this.cookies ) {
				this.parseCookies();
			}

			return this.cookies[key];
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
				return this;
			}
			out.animate = function( data, duration ) {
				self.each( this, function( key, element ) {
					element.animate( data, duration );
				});
				return this;
			}
			out.addClass = function( class_name ) {
				self.each( this, function( key, element ) {
					element.addClass( class_name );
				});
				return this;
			}
			out.removeClass = function( class_name ) {
				self.each( this, function( key, element ) {
					element.removeClass( class_name );
				});
				return this;
			}

			return out;
		},


		// Get util element
		element: function( selector, element, target ) {
			var target = target || document,
				element = element || target.querySelector( selector ),
				self = this;

			if( !element ) return;

			element.css = function( data ) {
				for( key in data ) {
					this.style.setProperty( key, data[key] );
				}
				return this;
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
				return this;
			}

			element.append = function( content ) {
				this.innerHTML += content;
				return this;
			},
			element.prepend = function( content ) {
				this.innerHTML = content + this.innerHTML;
				return this;
			}

			element.hasClass = function( css_class ) {
				return this.className.match( new RegExp( css_class, 'g' ) );
			},
			element.addClass = function( css_class ) {
				if( !this.hasClass( css_class ) )
					this.className += ' ' + css_class;
				return this;
			}
			element.removeClass = function( css_class ) {
				this.className = this.className.replace( new RegExp( ' ?' + css_class, 'g' ), '' );
				return this;
			}

			// Run util.elements with this element as the target
			element.elements = function( selector ) {
				return self.elements( selector, this );
			}
			element.element = function( selector ) {
				return self.element( selector, false, this );
			}

			return element;
		},


		// Build elements
		build: function( tag, data ) {
			var root_element = document.createElement( tag ),
				stack = [],
				self = this;

			stack.push( root_element );

			root_element.add = function( tag, data ) {
				if( !data ) {
					var new_element = document.createElement( tag );
					stack[stack.length - 1].appendChild( new_element );
					stack.push( new_element );
				} else {
					self.each( data, function( key, value ) {
						var new_element = document.createElement( tag );
						new_element.innerHTML = value;
						stack[stack.length -1].appendChild( new_element );
					});
				}

				return this;
			}

			root_element.build = function( tag, data ) {
				var new_element = self.build( tag, data );
				new_element.stack = stack;
				stack[stack.length - 1].appendChild( new_element );

				return new_element;
			}

			root_element.up = function() {
				stack.pop();
				return this;
			}

			return root_element;
		}
	}

	window.util = util;
})();