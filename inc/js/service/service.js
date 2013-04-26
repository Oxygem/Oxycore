//define service
var service = {
    commands: {},

    //set our type
    addCommands: function( type ) {
        if( !window[type] )
            return false;

        $.each( window[type], function( key, value ) {
            service.commands[key] = value;
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
        $( '#tabs .feedback' ).html( '<div class="message error">' + message + '</div>' );
    },

    //show a command
    showCommand: function( message ) {
        $( '#tabs .feedback' ).html( '<div class="message info"><img src="/inc/img/loader.gif" alt="loading..." /> <span>' + message + '</span> <a class="right button" onclick="service.toggleConsole( this ); return false;">console</a></div><div class="terminal hidden"><pre></pre></div>' );

        if( sessionStorage.getItem( 'service_console' ) == 'true' )
            this.showConsole();
    },

    //show a command
    showSimpleCommand: function( message ) {
        $( '#tabs .feedback' ).html( '<div class="message info"><img src="/inc/img/loader.gif" alt="loading..." /> <span>' + message + '</span></div>' );
    },

    //complete a command
    completeCommand: function( status, message ) {
        //remove image
        $( '#tabs .feedback div.message img' ).remove();
        //make info => status
        $( '#tabs .feedback div.message' ).removeClass( 'info' ).addClass( status );
        //redo message
        $( '#tabs .feedback div.message span' ).html( message );
    },

    //show console
    showConsole: function() {
        $( '#tabs .feedback .message' ).addClass( 'command' );
        $( '#tabs .feedback .commands' ).removeClass( 'hidden' );
        $( '#tabs .feedback .terminal' ).removeClass( 'hidden' );
        sessionStorage.setItem( 'service_console', 'true' );
    },
    hideConsole: function() {
        $( '#tabs .feedback .message' ).removeClass( 'command' );
        $( '#tabs .feedback .commands' ).addClass( 'hidden' );
        $( '#tabs .feedback .terminal' ).addClass( 'hidden' );
        sessionStorage.setItem( 'service_console', 'false' );
    },
    toggleConsole: function() {
        if( $( '#tabs .feedback .message' ).hasClass( 'command' ) ) {
            this.hideConsole();
        } else {
            this.showConsole();
        }
    },

    //show data input needed
    showDataInput: function( el ) {
        if( this.disabled )
            return;

        $( '#tabs .feedback' ).html( '<div class="message info"><form class="inline">' + el.attr( 'data-name' ) + ': <input value="" type="text" name="data_' + el.attr( 'data-needed' ) + '" /> <input type="submit" value="Go &#187;" /></form></div>');
        $( '#tabs .feedback form' ).bind( 'submit', function( ev ) {
            ev.preventDefault();
            var data = {}
            data[el.attr( 'data-needed' )] = $( '#tabs .feedback form input[name=data_' + el.attr( 'data-needed' ) + ']' ).val();
            service.commandRequest( el.attr( 'data-command' ), data );
        });
    },

    //show data input needed
    showConfirm: function( el ) {
        if( this.disabled )
            return;

        $( '#tabs .feedback' ).html( '<div class="message warning">' + el.attr( 'data-confirm' ) + ' <button class="">Continue</button></div>');
        $( '#tabs .feedback button' ).bind( 'click', function( ev ) {
            ev.preventDefault();
            service.commandRequest( el.attr( 'data-command' ) );
        });
    },

    //switch between tabs
    switchTab: function( tab ) {
        if( this.disabled )
            return;

        $( '#tabs .feedback' ).html( '' );
        //switch tab
        $( '#tabs div.tab' ).addClass( 'hidden' );
        $( '#tabs div.' + tab ).removeClass( 'hidden' );
        //switch button
        $( 'li.service_tab' ).removeClass( 'active' );
        $( 'li.service_tab[data-tab=' + tab + ']' ).addClass( 'active' );
    },

    //disable service functionality
    disable: function() {
        this.disabled = true;
        $( 'li.service_tab' ).addClass( 'disabled' );
        $( 'button.service_button' ).addClass( 'disabled' );
    },

    //enable service functionality
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
        $.ajax( window.location.origin + window.location.pathname + '/command?_api', {
            type: 'POST',
            data: data,
            error: function( req, status, error ) {
                service.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                if( !data.request_key )
                    return service.showError( data.error );

                oxypanel.luawa_token = data.token;

                //disable service
                service.disable();

                //valid callback command?
                if( service.commands[command] ) {
                    service.commands[command]( data.request_key );
                //default
                } else {
                    service.disable();
                    service.showCommand( 'Running command...' );

                    ssh.new( data.request_key, function( data ) {
                        console.log( data );
                    }, function( err ) {
                        service.showError( err );
                        service.enable();
                    }, function() {
                        service.completeCommand( 'success', 'Complete' );
                        service.enable();
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
        $.ajax( window.location.origin + window.location.pathname + '/setdata?_api', {
            type: 'POST',
            data: data,
            error: function( req, status, error ) {
                service.showError( status + ': ' + error );
            },
            success: function( data, status ) {
                oxypanel.luawa_token = data.token;
                service.completeCommand( 'success', 'Complete' );
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
        service.switchTab( $( ev.target ).parent().attr( 'data-tab' ) );
    });

    //bind data set
    $( 'form.service_set_data' ).bind( 'submit', function( ev ) {
        ev.preventDefault();
        service.setData( $( ev.target ) );
    })

    //bind command links
    $( 'button.service_button' ).bind( 'click', function( ev ) {
        ev.preventDefault();
        if( $( ev.target ).attr( 'data-needed' ) && $( ev.target ).attr( 'data-name' ) )
            service.showDataInput( $( ev.target ) );
        else if( $( ev.target ).attr( 'data-confirm' ) )
            service.showConfirm( $( ev.target ) );
        else
            service.commandRequest( $( ev.target ).attr( 'data-command' ) );
    });
});
