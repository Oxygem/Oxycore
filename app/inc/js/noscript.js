// File: app/inc/js/noscript.js
// Desc: hack around the no html inside noscript bullshit

'use strict';

util.each( util.elements( '.noscript' ), function( key, element ) {
    element.css({ 'display': 'none' });
});