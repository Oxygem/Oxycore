#!/usr/bin/env lua

--[[
    file: build.lua
    desc: Oxypanel build
        + creates oxyngx.lua for Nginx
        + creates oxynode.js for Node
]]

--localize
local type, pairs, tostring, io, oxy, table = type, pairs, tostring, io, oxy, table

--get app/luawa config
local luawaconf = require( 'config' )

--[[
    bits
]]
local nginx_config = function( config ) return [[# config.nginx :: autogenerated by oxypanel
#shared bits
lua_shared_dict ]] .. luawaconf.shm_prefix .. [[cache_app 1m;
lua_shared_dict ]] .. luawaconf.shm_prefix .. [[cache_template 1m;
lua_shared_dict ]] .. luawaconf.shm_prefix .. [[session 10m;
lua_shared_dict ]] .. luawaconf.shm_prefix .. [[user 10m;

server {
    #port & domains
    listen ]] .. luawaconf.oxyngx.port .. [[;
    server_name ]] .. config.urls .. [[;

    #dev mode
    lua_code_cache ]] .. ( luawaconf.cache and 'on' or 'off' ) .. [[;

    #logging
    error_log ]] .. config.root .. [[logs/error.log;
    access_log ]] .. config.root .. [[logs/access.log;

    #error pages
    error_page 404 /inc/error/404.html;
    error_page 500 /inc/error/500.html;

    #rewrite url                        #request                                        #method

    #inc is ok
    rewrite ^/inc/core/(.+)$            /app/inc/$1 last;
    rewrite ^/inc/([aA-zZ]+)/(.+)$      /modules/$1/inc/$2 last;
    rewrite ^/inc/?(.*)$                /inc/$1 last;

    #core
    rewrite ^/$                         /?request=dashboard last;                       #get
    rewrite ^/login$                    /?request=login last;                           #get+post
    rewrite ^/logout$                   /?request=logout last;                          #get
    rewrite ^/register$                 /?request=register last;                        #get+post
    rewrite ^/resetpw$                  /?request=resetpw last;                         #get+post
    rewrite ^/profile$                  /?request=profile last;                         #get+post
    rewrite ^/help$                     /?request=help last;                            #get

    #catch objects
    rewrite ^/([aA-zZ]+)/([0-9]+)$    /?request=object&type=$1&id=$2 last;      #get
    rewrite ^/([aA-zZ]+)/([0-9]+)/([aA-zZ\.]+)$    /?request=object&type=$1&id=$2&action=$3 last;      #get+post

    #catch modules
    rewrite ^/([aA-zZ]+)$               /?request=module&module=$1 last;         #get+post
    rewrite ^/([aA-zZ]+)/([aA-zZ]+)$               /?request=module&module=$1&module_request=$2 last;         #get+post
    rewrite ^/([aA-zZ]+)/([aA-zZ]+)/([aA-zZ]+)$               /?request=module&module=$1&module_request=$2&action=$3 last;         #get+post

    #else 404
    return 404;

    #default server dir
    location / {
        default_type 'text/html';
        content_by_lua_file ]] .. config.root .. [[oxyngx.lua;
    }

    #static content
    location /app/inc {
        root ]] .. config.root .. [[;
    }
    location ~ ^/modules/[aA-zZ]+/.+$ {
        root ]] .. config.root .. [[;
    }
    location /inc {
        root ]] .. config.root .. [[;
    }
}]] end



--do node config
local ngxnode_config = function( files )
    --start output
    local out = '// oxyngx.js :: autogenerated by oxypanel\n'
    --server port a port or socket?
    local server_port = luawaconf.oxynode.server_port
    if type( server_port ) == 'string' then
        server_port = "'" .. server_port .. "'"
    end
    --add code
    out = out .. [[module._autoconf = {
    client_port: ]] .. luawaconf.oxynode.client_port .. [[,
    server_port: ]] .. server_port .. [[,
    share_key: ']] .. luawaconf.oxynode.share_key .. [[',
    user_keys: ]] .. luawaconf.user.keys .. [[

};]] .. '\n'

    for k, file in pairs( files ) do
        out = out .. '\nrequire( \'./' .. file .. '\' );'
    end
    return out
end

--do node config
local autonode_config = function( files )
    --start output
    local out = '// oxyauto.js :: autogenerated by oxypanel\n'

    for k, file in pairs( files ) do
        out = out .. '\nrequire( \'./' .. file .. '\' );'
    end
    return out
end



--do clientside javascript
local client_js = function( auto_js ) return [[
// oxypanel.js :: autogenerated by oxypanel
'use strict';
oxypanel.user_keys = ]] .. luawaconf.user.keys .. [[,
oxypanel.node_port = ]] .. luawaconf.oxynode.client_port .. [[,
oxypanel.debug = ]] .. ( luawaconf.debug.enabled and 'true' or 'false' ) .. [[;
]] .. minifyJS( auto_js ) end

--do clientside css
local client_css = function( auto_css ) return [[
/* oxypanel.css :: autogenerated by oxypanel */
]] .. minifyCSS( auto_css ) end



--[[
    util functions
]]
--minify css (not complete)
function minifyCSS( css )
    --remove comments
    css = css:gsub( '/%*.-*/', '' )
    --remove whitespace
    css = css:gsub( '%s+', ' ' )
    return css
end

--minify js
function minifyJS( js )
    --remove string
    js = js:gsub( '\'use strict\';', '' )
    --remove /**/ comments
    js = js:gsub( '/%*.-*/', '' )
    --remove // comments
    js = js:gsub( '^//[^\n]+', '' )
    js = js:gsub( '%s+//[^\n]+', '' )
    --remove whitespace
    js = js:gsub( '[ \t]+', ' ' )
    --remove blank lines
    js = js:gsub( '\n+', '\n' )
    return js
end



--turn a lua table into lua code
local function tableToLua( table, indent )
    indent = indent or 0
    local out = ''

    for k, v in pairs( table ) do
        out = out .. '\n'
        for i = 0, indent do
            out = out .. '\t'
        end
        if type( v ) == 'table' then
            if type( k ) == 'string' and k:find( '%.' ) then
                out = out .. '[\'' .. k .. '\'] = {' .. tableToLua( v, indent + 1 ) .. '\n'
            else
                out = out .. k .. ' = {' .. tableToLua( v, indent + 1 ) .. '\n'
            end
            for i = 0, indent do
                out = out .. '\t'
            end
            out = out .. '},'
        else
            if type( v ) == 'function' then v = tostring( v() ) end
            if type( v ) == 'string' then v = "'" .. v .. "'" end
            if type( v ) == 'boolean' then v = tostring( v ) end
            if type( k ) == 'number' then k = '' else k = k .. ' = ' end
            out = out .. k .. v .. ','
        end
    end
    out = out:sub( 0, out:len() - 1 )

    return out
end

--table count
local function tableCount( table )
    local i = 0
    for k,v in pairs( table ) do
        i = i + 1
    end
    return i
end

--list a directory
function ls( dir )
    local out = {}
    local f, err = io.popen( 'ls ' .. dir )
    if not f then error( err ) end
    local module = f:read( '*l' )
    while module ~= nil do
        table.insert( out, module )
        module = f:read( '*l' )
    end
    f:close()
    return out
end

--make a directory
function mkdir( dir )
    local status, _ = os.execute( 'mkdir ' .. dir )
    return status == 0
end

--copy a directory s(ource)_dir -> d(irectory)_dir
function cpdir( s_dir, d_dir, exclude )
    exclude = exclude or '^$'

    --recursive list
    local function list( dir )
        local out = {}
        for k, v in pairs( ls( dir ) ) do
            if not v:match( exclude ) then
                if isdir( dir .. '/' .. v ) then
                    out[v] = list( dir .. '/' .. v )
                else
                    out[k] = v
                end
            end
        end
        return out
    end
    local list = list( s_dir )

    local count = 0
    for k, v in pairs( list ) do
        count = count + 1
    end
    if count == 0 then return end
    if not isdir( d_dir ) then mkdir( d_dir ) end

    --copy a file
    local function copyfile( s, d )
        --read
        local f, err = io.open( s, 'r' )
        if not f then error( err ) end
        local data, err = f:read( '*a' )
        if not data then error( err ) end
        f:close()

        if luawaconf.template.minimize then
            --minify css
            if s:sub( -4 ) == '.css' then
                data = '/* ' .. s:match( '/([%w]+%.%a+)') .. ' auto generated by oxypanel */\n' .. minifyCSS( data )
            end
            --minify js
            if s:sub( -3 ) == '.js' and not s:match( 'min' ) then
                data = '/* ' .. s:match( '/([%w]+%.%a+)') .. ' auto generated by oxypanel */\n' .. minifyJS( data )
            end
        end

        --write
        f, err = io.open( d, 'w' )
        if not f then error( err ) end
        local status, err = f:write( data )
        if not status then error( err ) end
        f:close()
    end

    --recursive copy using list
    local function copylist( list, prefix )
        prefix = prefix or ''
        for k, v in pairs( list ) do
            --directory
            if type( v ) == 'table' then
                mkdir( d_dir .. prefix .. '/' .. k )
                copylist( v, prefix .. '/' .. k )
            else
                --copy
                local s, d = s_dir .. prefix .. '/' .. v, d_dir .. prefix .. '/' .. v
                copyfile( s, d )
            end
        end
    end

    return copylist( list )
end

--check if is a directory
function isdir( dir )
    local f, err = io.popen( 'find ' .. dir .. ' -type d 2>/dev/null' )
    if not f then error( err ) end
    local out = dir == f:read( '*l' )
    f:close()
    return out
end

--check if is a file
function isFile( file )
    local f, err = io.popen( 'find ' .. file .. ' -type f 2>/dev/null' )
    if not f then error( err ) end
    local out = file == f:read( '*l' )
    f:close()
    return out
end


--[[
    request functions
]]
--build oxypanel.lua * config.nginx
local function build()
    print( 'BUILD START' )

    --auto css + js files storage
    local _auto = {
        js = '',
        css = ''
    }

    --conf to build
    local _autoconf = {
        modules = {},
        objects = {},
        brands = {},
        oxyngx = luawaconf.oxyngx,
        oxynode = luawaconf.oxynode
    }
    --node files to include
    local ngxnode_files, autonode_files = {}, {}

    --root directory
    print( 'Getting current directory' )
    local f, err = io.popen( 'pwd' )
    if not f then error( err ) end
    local root, err = f:read( '*l' )
    if not root then error( err ) end
    root = root .. '/'
    _autoconf.root = root
    print( '\tRoot directory set to: ' .. root )

    --scan for brands
    print( 'Scanning for brands...' )
    for k, brand in pairs( ls( 'app/brands/' ) ) do
        brand = brand:sub( 0, -5 )
        brand = require( 'app/brands/' .. brand )
        local url = brand.url
        brand.url = nil
        _autoconf.brands[url] = brand
        print( '\tAdded brand: ' .. url )
    end

    --build core js
    if luawaconf.cache then
        print( 'Building core js files...' )
        --libs
        for k, js in pairs( ls( 'app/inc/js/' ) ) do
            if js:find( '\.js' ) then
                local f, err = io.open( 'app/inc/js/' .. js )
                if not f then error( err ) end
                local data, err = f:read( '*a' )
                if not data then error( err ) end
                _auto.js = _auto.js .. '\n' .. data
            end
        end
    end

    --for each module, load their objects from their config
    print( 'Configuring modules...' )
    for k, module in pairs( ls( 'modules/' ) ) do
        local config = require( 'modules/' .. module .. '/config' )

        --add module
        print( '\tFound module: ' .. module )
        _autoconf.modules[config.order] = module
        _autoconf[module] = {}

        --start config
        print( '\tBuilding ' .. module .. ' config...' )
        --name
        _autoconf[module].name = config.name
        --do requests
        _autoconf[module].requests = config.requests
        print( '\t\t' .. ( tableCount( config.requests.get ) + tableCount( config.requests.post ) ) .. ' requests added' )
        --permissions
        _autoconf[module].permissions = config.permissions
        --custom actions
        _autoconf[module].actions = config.actions

        --do objects
        for object, d in pairs( config.objects ) do
            print( '\t\tObject added: ' .. object )
            d.module = module
            _autoconf.objects[object] = d
            if not d.hidden then
                _autoconf[module].requests.get[object .. 's'] = { file = '../../app/get/objects', args = { type = object } }
            end
        end

        --do autoconfs
        if config.autoconf then
            for key, conf in pairs( config.autoconf ) do
                _autoconf[module][key] = conf()
                print( '\t\tData configured: ' .. key )
            end
        end

        --ngxnode files?
        if config.ngxnode then
            for _, file in pairs( config.ngxnode ) do
                table.insert( ngxnode_files, 'modules/' .. module .. '/node/' .. file )
            end
        end

        --autonode files?
        if config.autonode then
            for _, file in pairs( config.autonode ) do
                table.insert( autonode_files, 'modules/' .. module .. '/node/' .. file )
            end
        end

        --inc dir?
        if isdir( 'modules/' .. module .. '/inc' ) then
            --loop directory
            for k, v in pairs( ls( 'modules/' .. module .. '/inc' ) ) do
                --auto.css?
                if v == 'auto.css' or v == 'auto.js' then
                    local f, err = io.open( 'modules/' .. module .. '/inc/' .. v )
                    if not f then error( err ) end
                    local data, err = f:read( '*a' )
                    if not data then error( err ) end
                    if v == 'auto.css' then
                        _auto.css = _auto.css .. data
                    else
                        _auto.js = _auto.js .. data
                    end
                end
            end
        end
    end

    --start output
    local output = '--autogenerated by Oxypanel\n_autoconf = {' .. tableToLua( _autoconf )
    --add ngx stuff
    output = output .. [[

}
--get luawa & set config
luawa = require( _autoconf.root .. 'luawa/core' )
luawa:setConfig( _autoconf.root, 'config' )


--set oxypanel & set config
oxy = require( _autoconf.root .. 'app/core' )
oxy:setConfig( _autoconf )

--luawa:run w/ oxy 'injected'
if not luawa:prepareRequest() then
    return luawa:error( 500, 'Invalid Request' )
end
--oxy
oxy:setup()
--go!
luawa:processRequest()]]

    --open oxypanel.lua + write
    print( 'Writing oxypanel.lua...' )
    local f, err = io.open( 'oxyngx.lua', 'w' )
    if not f then error( err ) end
    local status, err = f:write( output )
    if not status then error( err ) end
    print( '\toxypanel.lua written' )

    --oxyngx.js
    print( 'Writing oxyngx.js...' )
    local f, err = io.open( 'oxyngx.js', 'w' )
    if not f then error( err ) end
    local status, err = f:write( ngxnode_config( ngxnode_files ) )
    if not status then error( err ) end
    print( '\toxynode.js written' )

    --oxyauto.js
    print( 'Writing oxyauto.js...' )
    local f, err = io.open( 'oxyauto.js', 'w' )
    if not f then error( err ) end
    local status, err = f:write( autonode_config( autonode_files ) )
    if not status then error( err ) end
    print( '\toxynode.js written' )

    --oxypanel.js clientside
    print( 'Writing oxypanel.js...' )
    local f, err = io.open( 'inc/oxypanel.js', 'w' )
    if not f then error( err ) end
    local status, err = f:write( client_js( _auto.js ) )
    if not status then error( err ) end
    print( '\toxypanel.js written' )

    --oxypanel.css clientside
    print( 'Writing oxypanel.css...' )
    local f, err = io.open( 'inc/oxypanel.css', 'w' )
    if not f then error( err ) end
    local status, err = f:write( client_css( _auto.css ) )
    if not status then error( err ) end
    print( '\toxypanel.css written' )

    --config.nginx
    print( 'Writing config.nginx...' )
    local f, err = io.open( 'config.nginx', 'w' )
    if not f then error( err ) end
    local urls = ''
    for k, v in pairs( _autoconf.brands ) do if k ~= 'default' then urls = urls .. ' ' .. k end end
    local status, err = f:write( nginx_config( { root = _autoconf.root, urls = urls } ) )
    if not status then error( err ) end
    print( '\tconfig.nginx written' )

    print( 'BUILD COMPLETE' )
end



--run the build
return build()