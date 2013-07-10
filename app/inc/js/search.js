var search = {
    toggle: function() {
        $( '#search' ).slideToggle( 100 );
    }
}


//bind
$( '#header form.search' ).bind( 'submit', function( ev ) {
    ev.preventDefault();
    search.toggle();
});