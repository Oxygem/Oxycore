$.each( $( 'ul#subnav li ul.dropdown' ), function( key, submenu ) {
	var menu = $( submenu ),
		width = 0;

	//show menu (for widths)
	menu.show();
	//loop sub menus, get width
	$.each( $( 'li ul', submenu ), function( c, d ) {
		width += $( d ).outerWidth() + 12;
	});
	//apply width
	menu.css( { width: width + 20 } );
	
	//remove inline display style
	menu.css( { display: '' } );
});