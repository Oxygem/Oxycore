// File: app/inc/js/showall.js
// Desc: toggle all/owned objects in select field where admin

'use strict';

var showall = {
	createSelect: function( $select, type, current, data ) {
		$select.innerHTML = '<option value="0">Select ' + type.charAt( 0 ).toUpperCase() + type.slice( 1 ) + '</option>';
		util.each( data[type + 's'], function( key, item ) {
			if( item.id == current )
				$select.innerHTML += '<option value="' + item.id + '" selected>' + item.name + '</option>';
			else
				$select.innerHTML += '<option value="' + item.id + '">' + item.name + '</option>';
		});
		$select.innerHTML += '<option value="0">None</option>';
	}
};

util.each( util.elements( 'a.show' ), function( key, show ) {
	//get bits
	var $select = document.querySelector( '#' + show.parentNode.getAttribute( 'for' ) ),
		type = show.getAttribute( 'data-object-type' ),
		module = show.getAttribute( 'data-object-module' ),
		current = show.getAttribute( 'data-current-id' ),
		current_in_owned = false;

	//show hide function
	show.showHide = function() {
		if( show.innerHTML == 'Show All' ) {
			util.ajax( 'GET', window.location.origin + '/' + module + '/' + type + 's/all?_api', {
				error: function( status, error, response ) {
					console.error( error, response );
				},
				success: function( status, data ) {
					if( !data[type + 's'] ) {
						console.log( 'This will only happen if you allow EditAny but not ViewAny on this object - which you should never want to do!' );
					} else {
						showall.createSelect( $select, type, current, data );
						show.classList.remove( 'red' );
						show.innerHTML = 'Show Owned';
					}
				}
			});
		} else {
			util.ajax( 'GET', window.location.origin + '/' + module + '/' + type + 's?_api', {
				error: function( status, error ) {
					console.error( error );
				},
				success: function( status, data ) {
					showall.createSelect( $select, type, current, data );
					show.classList.add( 'red' );
					show.innerHTML = 'Show All';
				}
			});
		}
	}

	//bind clicks
	show.addEventListener( 'click', function( ev ) {
		ev.preventDefault();
		this.showHide();
	});

	//work out if current is in existing list
	if( current > 0 ) {
		util.each( $select.querySelectorAll( 'option' ), function( key, opt ) {
			if( opt.getAttribute( 'value' ) == current )
				current_in_owned = true;
		});
		//not in owned list?
		if( !current_in_owned )
			show.showHide();
	}
});