'use strict';

var $content = util.element( '#device #tabs #tab_content' ),
    $buttons = util.elements( 'button.service_button' );
var device = {
    active: false,
    buffer: '',
    $consoleContainer: util.element( '#device_console' ),
    $console: util.element( '#device_console pre' ),
    $feedback: util.element( '#device div.feedback' ).build( 'div' ),
    $consoleButton: util.build( 'button' ).addClass( 'right' ).append( 'Console: off' ),

    writeConsole: function( data ) {
        this.$console.append( data );
        this.$console.scrollTop = this.$console.scrollHeight;
    },

    hideConsole: function() {
        this.$consoleContainer.addClass( 'hidden' );
        this.$consoleButton.innerHTML = 'Console: off';
    },

    showConsole: function() {
        this.$consoleContainer.removeClass( 'hidden' );
        this.$consoleButton.innerHTML = 'Console: on';
    },

    showError: function( error ) {
        this.$feedback
            .set( 'className', 'message' )
            .addClass( 'error' )
            .set( 'innerHTML', error );
    },

    showSuccess: function( message ) {
        this.$feedback
            .set( 'className', 'message' )
            .addClass( 'success' )
            .set( 'innerHTML', message )
            .appendChild( this.$consoleButton );
    },

    showLoading: function() {
        this.$feedback
            .set( 'className', 'message' )
            .set( 'innerHTML', '<img src="/inc/core/img/loader.gif" /> Loading...' )
            .appendChild( this.$consoleButton );
    },

    //parse a request
    parse: function( data, parse_data ) {
        parse_data.skip = parse_data.skip || 0;
        parse_data.titles = parse_data.titles ? new RegExp( parse_data.titles ) : false;
        parse_data.title_skip = parse_data.title_skip || 0;

        //go through data line by line
        var lines = data.split( '\n' ),
            out = { rows: [] },
            blank = /^\s*$/,
            title = parse_data.title_skip * -1;
        for( var i = 0; i < lines.length - 1; i++ ) {
            //blank line?
            if( blank.exec( lines[i].trim() ) ) continue;
            //skip this line?
            if( i < parse_data.skip || i < title + parse_data.title_skip ) continue;

            //is this line a title?
            if( parse_data.titles && parse_data.titles.exec( lines[i] ) ) {
                title = i + 1;
                out.rows.push( lines[i] );
                continue;
            }

            var bits = lines[i].split( /\s+/ );
            var d = [];

            for( var j = 0; j < parse_data.columns.length; j++ ) {
                if( j + 1 != parse_data.columns.length )
                    d[j] = bits[j];
                else
                    d[j] = bits.slice( j ).join( ' ' );
            }

            out.rows.push( d );
        }
        out.structure = parse_data.columns;

        return out;
    },

    //js based device commands
    commands: {
        console: function() {
            var left = screen.width / 2 - 495,
                top = screen.height / 2 - 330;

            window.open( window.location.href + '/console', '_blank', 'height=660,width=990,toolbar=no,status=no,resizable=no,menubar=no,left=' + left + ',top=' + top );
        }
    },

    disable: function() {
        device.active = true;
        $buttons.addClass( 'disabled' );
    },

    enable: function() {
        device.active = false;
        $buttons.removeClass( 'disabled' );
    }
}

// Bind buttons
util.each( $buttons, function( key, $button ) {
    $button.addEventListener( 'click', function( ev ) {
        ev.preventDefault();

        if( device.active ) return;

        var js = $button.getData( 'js' );
        if( js && device.commands[js] )
            return device.commands[js]();

        var data = {
            command: this.getData( 'command' ),
            token: oxypanel.luawa_token
        };

        util.ajax( 'POST', window.location.origin + window.location.pathname + '/runCommand?_api', {
            data: data,
            error: function( status, error, raw_response ) {
                debug.log( 'error', status, error, raw_response );
            },
            success: function( status, data ) {
                if( !data.token )
                    return device.showError( data.messages[0].text );
                oxypanel.luawa_token = data.token;

                if( data.error )
                    return device.showError( data.error );

                var active_tab = util.element( '#control_tabs div.tab.active .content' );
                ssh.new( data.request_key, {
                    error: function( error ) {
                        debug.log( 'request_error', error );
                        device.showError( error.code );
                        device.enable();
                    },
                    data: function( data ) {
                        debug.log( 'command_data', data );
                        device.writeConsole( data );
                        device.buffer += data;
                    },
                    cmdEnd: function( data ) {
                        debug.log( 'command_end', data );

                        if( data.parse_data ) {
                            var parsed_data = device.parse( device.buffer, data.parse_data );

                            //build/render table
                            var table = util.build( 'table' ); // table
                                table.build( 'thead' ) // table +thead
                                .build( 'tr' ) // table -> thead +tr
                                .each( parsed_data.structure, function( key, value ) {
                                    this.build( 'th' ).append( value ); // table > thead > tr +td
                                })
                                .parentNode // table -> thead -tr
                                .parentNode // table -thead
                                .build( 'tbody' ) // table +body
                                .each( parsed_data.rows, function( key, values ) {
                                    if( typeof values == 'string' ) {
                                        this.build( 'tr' )
                                        .build( 'th' ).append( values ).colSpan = parsed_data.structure.length;
                                    } else {
                                        this.build( 'tr' )
                                        .each( values, function( k, v ) {
                                            this.build( 'td' ).append( v );
                                        });
                                    }
                                });

                            $content.innerHTML = '';
                            $content.appendChild( table );
                        }
                    },
                    cmdStart: function( data ) {
                        debug.log( 'command_start', data );
                        device.buffer = '';
                    },
                    end: function( data ) {
                        debug.log( 'request_end', data );
                        device.enable();
                        device.showSuccess( 'Complete' );
                    },
                    start: function( data ) {
                        debug.log( 'request_start', data );
                        device.disable();
                        device.showLoading();
                    }
                });
            }
        });
    });
});

device.$consoleButton.addEventListener( 'click', function() {
    device.$consoleContainer.hasClass( 'hidden' ) ? device.showConsole() : device.hideConsole();
});