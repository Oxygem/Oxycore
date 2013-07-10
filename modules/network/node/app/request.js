//define actions in this file
// all: exec, moveTo, copyFrom
// client only: interactiveShell, fileBrowser

//get randomstring
var randomstring = require( 'randomstring' ),
	ssh = require( './ssh.js' );

//request module
var request = {
	//store requests
	requests: [],
	//exec action
	exec: function( key, data ) {
		//get request
		var req = this.requests[key];

		//execute command
		req.connection.exec( data.command, function( err, stream ) {
			if( err ) request.end( key, err );

			//callback: notify command start
			req.callbacks.cmdStart( { out: data.out, in: data.command } );
			console.log( '[Request: ' + key + '] command start: ' + data.command );

			//data callback
			stream.on( 'data', function( data ) {
				req.callbacks.data( data );
			});

			//end
			stream.on( 'exit', function( code, signal ) {
				//callback: notify command end
				req.callbacks.cmdEnd( data.out );
				console.log( '[Request: ' + key + '] command complete: ' + data.command );
				//next step in 100ms to avoid overlap
				setTimeout( function() { request.step( key ); }, 100 );
			});
		});
	},

	//create new request, returns key
	new: function( key, server, actions, onData, onCmdStart, onCmdEnd, onEnd ) {
		//make our connection
		ssh.connect( server,
			//success
			function( connection ) {
				//add request
				request.requests[key] = {
					connection: connection,
					actions: actions,
					callbacks: {
						data: onData,
						cmdStart: onCmdStart,
						cmdEnd: onCmdEnd,
						end: onEnd
					}
				}
				//start it
				request.step( key );
			},
			//error
			function( error ) {
				console.log( 'Error making new request: ' + error );
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
		if( action == undefined || !action.action || !action.out ) return this.end( key );

		//do next action
		this[action.action]( key, action );
	},

	//end a request
	end: function( key, err ) {
		//get request
		var request = this.requests[key];

		//end callback
		request.callbacks.end();

		//'close' connection
		ssh.disconnect( request.connection );

		//delete it
		delete this.requests[key];

		//log
		if( err ) console.log( '[Request: ' + key + '] error: ' + err );
		console.log( '[Request: ' + key + '] Completed' );
	}
}

//export module
module.exports = request;