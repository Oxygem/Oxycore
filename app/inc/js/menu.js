util.each( document.querySelectorAll( 'ul#subnav li ul.dropdown' ), function( key, submenu ) {
	var menu = submenu,
		width = 0;

	//show menu (for widths)
	menu.style.setProperty( 'display', 'inline' );
	//loop sub menus, get width
	util.each( submenu.querySelectorAll( 'li ul' ), function( c, d ) {
		width += d.clientWidth + 12;
	});
	//apply width
	menu.style.setProperty( 'width', ( width + 10 ) + 'px' );
	
	//remove display style
	menu.style.setProperty( 'display', '' );
});