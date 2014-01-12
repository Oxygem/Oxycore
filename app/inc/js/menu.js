// File: app/inc/js/menu.js
// Desc: minor UX improvements to the menu which CSS couldn't provide

'use strict';

util.each( util.elements( 'ul.dropdown ul' ), function( key, $item ) {
    $item.addEventListener( 'click', function( ev ) {
        if( ev.toElement == this ) {
            var target = ev.toElement.parentNode.parentNode.parentNode,
                links = target.querySelectorAll( 'a' );

            var link = links[links.length - 1].getAttribute( 'href' );
            window.location = link;
        }
    });
})