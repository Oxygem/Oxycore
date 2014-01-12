// File: app/inc/js/tabs.js
// Desc: toggle set of divs from a list

'use strict';

util.each( util.elements( 'ul[data-tabs]' ), function( key, $tabs ) {
    var container = util.element( '#' + $tabs.get( 'tabs' ) );

    util.each( $tabs.elements( 'li' ), function( key, $tab ) {
        $tab.addEventListener( 'click', function( ev ) {
            ev.preventDefault();

            $tabs.elements( 'li' ).removeClass( 'active' );
            $tab.addClass( 'active' );
            container.elements( 'div[data-tab]' ).addClass( 'hidden' ).removeClass( 'active' );
            container.element( 'div[data-tab="' + $tab.get( 'tab' ) + '"]' ).removeClass( 'hidden' ).addClass( 'active' );
        });
    });
});