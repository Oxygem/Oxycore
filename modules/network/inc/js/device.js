//define server
var server = {
    commands: {},

    //set our type
    addCommands: function( type ) {
        if( !type )
            return false;

        $.each( type, function( key, value ) {
            server.commands[key] = value;
        });
    },

    //start
    start: function() {
        if( this.commands.start )
            this.commands.start();
    },

    //build a status bar
    buildBar: function( name, used, max, measure ) {
        if( measure == undefined ) measure = 'MB';
        //work out percentage
        var percent = Math.round( used / max * 100 );
        //work out color
        var color = 'green';
        if( percent > 90 )
            color = 'red';
        else if( percent > 70 )
            color = 'orange';

        return '<div class="bar ' + color + '"><span><strong>' + name + ':</strong> ' + used + measure + ' / ' + max + measure + '</span><div style="width:' + percent + '%;"></div></div>'
    },

    //show an error
    showError: function( message ) {
        $( '.feedback' ).html( '<div class="message error">' + message + '</div>' );
    },

    //show a command
    showCommand: function( message ) {
        $( '.feedback' ).html( '<div class="message info"><img src="/inc/core/img/loader.gif" alt="loading..." /> <span>' + message + '</span> <a class="right button" onclick="server.toggleConsole( this ); return false;">console</a></div>' );

        if( sessionStorage.getItem( 'service_console' ) == 'true' )
            this.showConsole();
    },

    //show a command
    showSimpleCommand: function( message ) {
        $( '.feedback' ).html( '<div class="message info"><img src="/inc/core/img/loader.gif" alt="loading..." /> <span>' + message + '</span></div>' );
    },

    //complete a command
    completeCommand: function( status, message ) {
        //remove image
        $( '.feedback div.message img' ).remove();
        //make info => status
        $( '.feedback div.message' ).removeClass( 'info' ).addClass( status );
        //redo message
        $( '.feedback div.message span' ).html( message );
    },

    //show console
    showConsole: function() {
        $( '#device_console.terminal' ).slideDown().removeClass( 'hidden' );
        sessionStorage.setItem( 'service_console', 'true' );
    },
    hideConsole: function() {
        $( '#device_console.terminal' ).slideUp().addClass( 'hidden' );
        sessionStorage.setItem( 'service_console', 'false' );
    },
    toggleConsole: function() {
        if( $( '#device_console.terminal' ).hasClass( 'hidden' ) ) {
            this.showConsole();
        } else {
            this.hideConsole();
        }
    },

    //show data input needed
    showDataInput: function( el ) {
        if( this.disabled )
            return;

        $( '.feedback' ).html( '<div class="message info"><form class="inline">' + el.attr( 'data-name' ) + ': <input value="" type="text" name="data_' + el.attr( 'data-needed' ) + '" /> <input type="submit" value="Go &#187;" /></form></div>');
        $( '.feedback form' ).bind( 'submit', function( ev ) {
            ev.preventDefault();
            var data = {}
            data[el.attr( 'data-needed' )] = $( '.feedback form input[name=data_' + el.attr( 'data-needed' ) + ']' ).val();
            server.commandRequest( el.attr( 'data-command' ), data );
        });
    },

    //show data input needed
    showConfirm: function( el ) {
        if( this.disabled )
            return;

        $( '.feedback' ).html( '<div class="message warning">' + el.attr( 'data-confirm' ) + ' <button class="">Continue</button></div>');
        $( '.feedback button' ).bind( 'click', function( ev ) {
            ev.preventDefault();
            service.commandRequest( el.attr( 'data-command' ) );
        });
    },

    //switch between tabs
    switchTab: function( tab ) {
        if( this.disabled )
            return;

        $( '.feedback' ).html( '' );
        //switch tab
        $( 'div.tab' ).addClass( 'hidden' );
        $( 'div.' + tab ).removeClass( 'hidden' );
        //switch button
        $( 'li.service_tab' ).removeClass( 'active' );
        $( 'li.service_tab[data-tab=' + tab + ']' ).addClass( 'active' );
    },

    //disable server functionality
    disable: function() {
        this.disabled = true;
        $( 'li.service_tab' ).addClass( 'disabled' );
        $( 'button.service_button' ).addClass( 'disabled' );
    },

    //enable server functionality
    enable: function() {
        this.disabled = false;
        $( 'li.service_tab.disabled' ).removeClass( 'disabled' );
        $( 'button.service_button.disabled' ).removeClass( 'disabled' );
    },

    //make a request
    commandRequest: function( command, data ) {
        if( this.disabled )
            return;
        if( !data )
            data = {};

        //add commnad to data
        data.command = command;
        data.token = oxypanel.luawa_token;
        //make our request
        $.ajax( window.location.origin + window.location.pathname + '/runCommand?_api', {
            type: 'POST',
            data: data,
            error: function( req, status, error ) {
                server.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                if( data.token )
                    oxypanel.luawa_token = data.token;

                if( !data.request_key )
                    return server.showError( data.error );

                //disable server
                server.disable();

                //valid callback command?
                if( server.commands[command] ) {
                    server.commands[command]( data.request_key );
                //default
                } else {
                    server.disable();
                    server.showCommand( 'Running command...' );

                    ssh.new( data.request_key, function( data ) {
                        console.log( data );
                    }, function( err ) {
                        server.showError( 'Error: ' + err );
                        server.enable();
                    }, function() {
                        server.completeCommand( 'success', 'Complete' );
                        server.enable();
                    });
                }
            }
        });
    },

    //make a request
    setData: function( form ) {
        if( this.disabled )
            return;

        this.showSimpleCommand( 'Setting data...' );
        var data = {};
        //add details to data
        data.key = $( 'input[name=key]', form ).val();
        data.value = $( 'input[name=value]', form ).val();
        data.token = oxypanel.luawa_token;
        //make our request
        $.ajax( window.location.origin + window.location.pathname + '/setData?_api', {
            type: 'POST',
            data: data,
            error: function( req, status, error ) {
                server.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                oxypanel.luawa_token = data.token;
                if( data.error ) return server.showError( 'Error : ' + data.error );
                server.completeCommand( 'success', 'Complete' );
            }
        });
    },

    //'tabed' ie output from iptables, apt, yum, df, etc
    tabsToArray: function( data ) {
        return $.grep( data.split( ' ' ), function( n ) {
            if( n.length > 0 && n != '' )
                return true;
            else
                return false;
        });
    }
}


//ev bindings
$( document ).ready( function() {
    //bind tab links
    $( 'li.service_tab a' ).bind( 'click', function( ev ) {
        ev.preventDefault();
        server.switchTab( $( ev.target ).parent().attr( 'data-tab' ) );
    });

    //bind command links
    $( 'button.service_button' ).bind( 'click', function( ev ) {
        ev.preventDefault();
        if( $( ev.target ).attr( 'data-needed' ) && $( ev.target ).attr( 'data-name' ) )
            server.showDataInput( $( ev.target ) );
        else if( $( ev.target ).attr( 'data-confirm' ) )
            server.showConfirm( $( ev.target ) );
        else
            server.commandRequest( $( ev.target ).attr( 'data-command' ) );
    });
});
