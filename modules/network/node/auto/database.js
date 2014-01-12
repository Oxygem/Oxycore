// File: node/auto/database.js
// Desc: talks to the database, 'models' devices

'use strict';

// Imports
var mysql = require( 'mysql' );

// Database
var database = {
    devices: {},
    automations: {},

    //get single device
    getDevice: function( id ) {
        return this.devices[id];
    },

    //reload single device
    reloadDevice: function( id ) {

    },

    //reload all devices
    reloadDevices: function() {

    },

    //get single automation
    getAutomation: function( id ) {
        return this.automations[id];
    },

    //reload single automation
    reloadAutomation: function( id ) {

    },

    //reload all automations
    reloadAutomations: function() {

    },

    //actually talks to the database
    fetch: function( object, id ) {

    }
};
module.exports = database;