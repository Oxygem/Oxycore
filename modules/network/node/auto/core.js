// File: node/auto/core.js
// Desc: automation and stat monitoring, browsers/clients can subscribe to stats

'use strict';

/*
    server talks to database to reload/load stuff
    stat & auto read from database
    client needs stat to add callback to do live stats for browser
*/

// Imports
var database = require( './database.js' ),
    server = require( './server.js' ),
    client = require( './client.js' ),
    stat = require( './stat.js' ),
    auto = require( './auto.js' );

// Initialize/prep database
database.reloadDevices();
database.reloadAutomations();

// Start server w/ database
server.start( database );

// Start stat & auto w/ database
stat.start( database );
auto.start( database );

// Start client w/ stat
client.start( stat );