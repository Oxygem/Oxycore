// File: app/inc/js/debug.js
// Desc: debugging

'use strict';

var debug = {
    log: function() {
        if(oxypanel.debug)
            console.log.apply(console, arguments);
    }
};