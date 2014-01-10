local template = oxy.template

--page title
template:set( 'page_title', 'Register' )

--load templates
template:load( 'header' )
template:load( 'register' )
template:load( 'footer' )