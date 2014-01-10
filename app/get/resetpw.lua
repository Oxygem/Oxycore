local template = oxy.template

--page title
template:set( 'page_title', 'Reset Password' )

--load templates
template:load( 'header' )
template:load( 'resetpw' )
template:load( 'footer' )