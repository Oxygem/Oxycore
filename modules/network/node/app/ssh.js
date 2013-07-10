//ssh connection manager

//get ssh module
var ssh2 = require( 'ssh2' ),
	fs = require( 'fs' );

//ssh class
var ssh = {
	//store connections here
	connections: {},


	//connect to a server (ssh.js => ngx.js ev loop)
	connect: function( server, success, error ) {
		//make a string specific to this connection
		var connstring = server.host + server.port + server.user;

		//no connection group for this server?
		if( !this.connections[connstring] ) this.connections[connstring] = [];

		//maybe have a useful connection?
		if( this.connections[connstring].length > 0 ) {
			//console.log( this.connections[connstring] );
		}

		//no useful connections, lets add one!
		var connection = new ssh2();
		connection.server = server;
		connection.on( 'ready', function() {
			console.log( '[SSH] connection added: ' + server.user + '@' + server.host + ':' + server.port );
			connection.used = true;
			//success callback
			success( connection );
		});
        connection.on( 'error', function( err ) {
        	error( err );
        });

        //work out params
        var server_params = {
            host: server.host,
            port: server.port,
            username: server.user
        };
        if( server.key )
            server_params.privateKey = fs.readFileSync( server.key );
        else if( server.password )
            server_params.password = server.password;

        //connect & return
        connection.connect( server_params );

        //add connection to correct array
        this.connections[connstring].push( connection );
	},

	//disconnect (ngx.js ev loop => ssh.js) won't actually disconnect
	disconnect: function( connection ) {
		//set connection.used = false; (or delete it)
		connection.used = false;
		//timestamp last-used time
		connection.last_used = new Date().getTime();

		//tmp remove this
		connection.end();
		connection.ended = true;
		console.log( '[SSH] connection closed: ' + connection.server.user + '@' + connection.server.host + ':' + connection.server.port );
	},

	//loop (on interval)
	loop: function() {
		//check all connections, where not-in-use w/ timestamp > whatever, close connection
	}
};

//export module
module.exports = ssh;