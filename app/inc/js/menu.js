document.querySelectorAll( 'ul#subnav li ul.dropdown' ).each( function( key, submenu ) {
	var menu = submenu,
		width = 0;

	//show menu (for widths)
	menu.style.setProperty( 'display', 'block' );
	//loop sub menus, get width
	submenu.querySelectorAll( 'li ul' ).each( function( c, d ) {
		width += d.clientWidth;
	});
	//apply width
	menu.style.setProperty( 'width', ( width + 30 ) + 'px' );

	//remove display style
	menu.style.setProperty( 'display', '' );
});