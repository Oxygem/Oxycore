// File: node/ngx/request.js
// Desc: handles ssh requests

'use strict';

/*
	Request 'actions' can either be:
	1. 'exec'ute a command, parse the output
		returns data/json
	2. enter 'console' session
*/

// Modules
var randomstring = require( 'randomstring' ),
	ssh = require( '../ssh.js' );

// Request module
var request = {
	// store requests
	requests: [],


	// ------------------------------------- Start actions
	// Console session
	console: function( key, data ) {
		// get request
		var req = this.requests[key];

		//start console
		req.connection.shell( { rows: 50, cols: 140 }, function( err, stream ) {
			if( err ) request.end( key, err );

			console.log( '[Request: ' + key + '] console opened' );

			//on stream/shell data, send to browser
			stream.on( 'data', function( data, extended ) {
				req.client.emit( 'console_data', data.toString() );
			});

			//recieve data from browser, send to stream/shell
			req.client.on( 'console_data', function( data ) {
				if( stream.writable ) stream.write( data );
			});

			stream.on( 'end', function() {
				console.log( 'stream end' );
			});
			stream.on( 'close', function() {
				console.log( 'stream close' );
			});
			stream.on( 'exit', function( code, signal ) {
				//notify command end
				req.callbacks.cmdEnd( 'console', 0 );
				console.log( '[Request: ' + key + '] console closed' );
				//next step in 100ms to avoid overlap
				setTimeout( function() { request.step( key ); }, 100 );
			});
		});
	},

	// Execute & parse shell command
	exec: function( key, data ) {
		//get request
		var req = this.requests[key],
			self = this;

		//execute command
		req.connection.exec( data.command, function( err, stream ) {
			if( err ) request.end( key, err );

			//callback: notify command start
			req.callbacks.cmdStart( data.out );
			console.log( '[Request: ' + key + '] command start: ' + data.command );

			//data callback
			stream.on( 'data', function( data ) {
				req.callbacks.data( String( data ) );
			});

			stream.on( 'exit', function( code, signal ) {
				req.exit_code = code;
				req.exit_signal = signal;
			});

			//end
			stream.on( 'close', function() {
				//expect?
				if( data.expect ) {
					//signal failure?
					if( data.expect.signal != req.exit_code ) {
						//set of commands to run?
						if( data.expect.fail ) {
							for( var i = data.expect.fail.length - 1; i >= 0; i-- ) {
								req.actions.unshift( data.expect.fail[i] );
							}
						//no fail commands, game over
						} else {
							req.callbacks.error( data.expect.error );
							console.log( '[Request: ' + key + '] command error: ' + data.expect.error );
							return request.end( key );
						}
					}
				}

				//callback: notify command end
				req.callbacks.cmdEnd( data.out, req.exit_code, data.parse );
				console.log( '[Request: ' + key + '] command complete: ' + data.command );
				//next step in 100ms to avoid overlap
				setTimeout( function() { request.step( key ); }, 100 );
			});
		});
	},
	// --------------------------------------- End actions


	// New request
	new: function( key, client, server, actions, options ) {
		//make our connection
		ssh.connect( server,
			//success
			function( connection ) {
				//add request
				request.requests[key] = {
					connection: connection,
					client: client,
					actions: actions,
					buffer: '',
					callbacks: {
						data: options.data,
						cmdStart: options.cmdStart,
						cmdEnd: options.cmdEnd,
						end: options.end,
						error: options.error
					}
				}
				//start it
				request.step( key );
			},
			//err
			function( err ) {
				options.error( err );
				console.log( '[Request: ' + key + '] error: ' + err );
			}
		);
	},

	//step a request
	step: function( key ) {
		//get request
		var request = this.requests[key];

		//get next action
		var action = request.actions.shift();
		//action undefined? end of request
		if( action == undefined || !action.action ) return this.end( key );

		//do next action
		this[action.action]( key, action );
	},

	//end a request
	end: function( key ) {
		//get request
		var request = this.requests[key];

		//end callback
		request.callbacks.end();

		//'close' connection
		ssh.disconnect( request.connection );

		//delete it
		delete this.requests[key];

		console.log( '[Request: ' + key + '] Completed' );
	}
}

//export module
module.exports = request;