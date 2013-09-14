//define device
var device = {
    commands: {
        //console open (every device)
        console: function() {
            var left = screen.width / 2 - 495;
            var top = screen.height / 2 - 330;
            window.open( window.location.href + '/console', '_blank', 'height=660,width=990,toolbar=no,status=no,resizable=no,menubar=no,left=' + left + ',top=' + top );
        }
    },

    //set our type
    addCommands: function( type ) {
        if( !type )
            return false;

        $.each( type, function( key, value ) {
            device.commands[key] = value;
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
        $( '.feedback' ).html( '<div class="message info"><img src="/inc/core/img/loader.gif" alt="loading..." /> <span>' + message + '</span> <a class="right button" onclick="device.toggleConsole( this ); return false;">console</a></div>' );

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
        $( '#device_console.terminal' ).slideDown( 200 ).removeClass( 'hidden' );
        sessionStorage.setItem( 'service_console', 'true' );
    },
    hideConsole: function() {
        $( '#device_console.terminal' ).slideUp( 200 ).addClass( 'hidden' );
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

        $( '#device_data_input' ).html( '<div class="message info"><form class="inline">' + el.attr( 'data-name' ) + ': <input value="" type="text" name="data_' + el.attr( 'data-needed' ) + '" /> <input type="submit" value="Go &#187;" /></form></div>').slideDown( 150 );
        $( '#device_data_input form' ).bind( 'submit', function( ev ) {
            ev.preventDefault();
            var data = {}
            data[el.attr( 'data-needed' )] = $( '#device_data_input form input[name=data_' + el.attr( 'data-needed' ) + ']' ).val();
            device.commandRequest( el.attr( 'data-command' ), data );
            $( '#device_data_input' ).slideUp( 150 );
        });
    },

    //show data input needed
    showConfirm: function( el ) {
        if( this.disabled )
            return;

        $( '#device_data_input' ).html( '<div class="message warning">' + el.attr( 'data-confirm' ) + ' <button class="">Continue</button></div>').slideDown( 150 );
        $( '#device_data_input button' ).bind( 'click', function( ev ) {
            ev.preventDefault();
            device.commandRequest( el.attr( 'data-command' ) );
            $( '#device_data_input' ).slideUp( 150 );
        });
    },

    //switch between tabs
    switchTab: function( tab ) {
        if( this.disabled )
            return;

        //switch tab
        $( 'div.tab' ).addClass( 'hidden' );
        $( 'div.' + tab ).removeClass( 'hidden' );
        //switch button
        $( 'li.service_tab' ).removeClass( 'active' );
        $( 'li.service_tab[data-tab=' + tab + ']' ).addClass( 'active' );
    },

    //disable device functionality
    disable: function() {
        this.disabled = true;
        $( 'li.service_tab' ).addClass( 'disabled' );
        $( 'button.service_button' ).addClass( 'disabled' );
    },

    //enable device functionality
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
                device.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                if( data.token )
                    oxypanel.luawa_token = data.token;

                if( !data.request_key )
                    return device.showError( data.error );

                //disable device
                device.disable();

                //valid callback command?
                if( device.commands[command] ) {
                    device.commands[command]( data.request_key );
                //default
                } else {
                    device.showConsole();
                    device.disable();
                    device.showCommand( 'Running command...' );

                    ssh.new( data.request_key, function( data ) {
                        console.log( data );
                    }, function( err ) {
                        device.showError( 'Error: ' + err );
                        device.enable();
                    }, function() {
                        device.completeCommand( 'success', 'Complete' );
                        device.enable();
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
                device.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                oxypanel.luawa_token = data.token;
                if( data.error ) return device.showError( 'Error : ' + data.error );
                device.completeCommand( 'success', 'Complete' );
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
        device.switchTab( $( ev.target ).parent().attr( 'data-tab' ) );
    });

    //bind command links
    $( 'button.service_button' ).bind( 'click', function( ev ) {
        ev.preventDefault();

        //direct command
        if( $( ev.target ).attr( 'data-command' ) ) {
            if( $( ev.target ).attr( 'data-needed' ) && $( ev.target ).attr( 'data-name' ) )
                device.showDataInput( $( ev.target ) );
            else if( $( ev.target ).attr( 'data-confirm' ) )
                device.showConfirm( $( ev.target ) );
            else
                device.commandRequest( $( ev.target ).attr( 'data-command' ) );

        //js function (popup etc)
        } else if( $( ev.target ).attr( 'data-js' ) ) {
            device.commands[$( ev.target ).attr( 'data-js' )]();
        }
    });
});
