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
    window.util = {
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
                        return options.error( req.status, e, req.responseText );
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
        setCookie: function( key, value, options ) {
            document.cookie = key + '=' + value;
        },


        // Get util elements
        elementArguments: ['css', 'set', 'setData', 'addClass', 'removeClass', 'addEventListener'],
        elements: function( selector, target ) {
            var target = target || document,
                elements = target.querySelectorAll( selector ),
                out = [],
                self = this,
                i;

            this.each( elements, function( key, element ) {
                out.push( self.element( false, element ));
            });

            // Make certain element functions available on elements
            this.each( this.elementArguments, function( key, func ) {
                out[func] = function() {
                    var args = arguments;
                    self.each( out, function( key, element ) {
                        element[func].apply( element, args );
                    });

                    return out;
                };
            });

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

            // Set this.<key>, chainable
            element.set = function( key, value ) {
                this[key] = value;
                return this;
            },

            element.getData = function( key ) {
                return this.getAttribute( 'data-' + key );
            }
            element.setData = function( key, value ) {
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

            element.addClass = function( css_class ) {
                this.classList.add( css_class );
                return this;
            }
            element.removeClass = function( css_class ) {
                this.classList.remove( css_class );
                return this;
            }

            // Build a new element as child of this
            element.build = function( tag ) {
                var element = self.build( tag );
                this.appendChild( element );
                return element;
            },

            element.each = function( data, callback ) {
                var el_this = this;
                self.each( data, function( key, value ) {
                    callback.call( el_this, key, value );
                });
                return this;
            },

            // Run util.elements with this element as the target
            element.elements = function( selector ) {
                return self.elements( selector, this );
            }
            element.element = function( selector ) {
                return self.element( selector, false, this );
            }

            return element;
        },

        // Build an element
        build: function( tag ) {
            var element = document.createElement( tag );
            return this.element( false, element );
        }
    }
})();