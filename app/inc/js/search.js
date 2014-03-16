// File: app/inc/js/search.js
// Desc: ajaxy search

'use strict';

var search = {
    element: util.element( '#search' ),

    toggle: function() {
        if( this.element.style.getPropertyValue( 'display' ) == 'block' ) {
            this.element.css( { display: 'none' } );
        } else {
            this.element.css( { display: 'block' } );
        }
    }
};


//bind
//util.element( '#header form.search' ).addEventListener( 'submit', function( ev ) {
 //   ev.preventDefault();
 //   search.toggle();
//});