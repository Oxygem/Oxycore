# Oxypanel

This repo is for [_Oxypanel Core_](http://oxypanel.org) which is a modular, object based Lua web framework based on [Luawa](http://luawa.com). The functionality described on [Oxypanel.com](http://oxypanel.com) is based on a number of open source & commercial modules for this framework:

+ [Oxypanel Network](http://github.com/Oxygem/Oxypanel-Network)
+ Oxypanel Clouds & Services
+ Oxypanel Support
+ Oxypanel Billing


# Documentation

Documentation for Oxypanel Core and the various modules is found at [doc.oxypanel.com](http://doc.oxypanel.com). This readme & the readme's of the various modules contain development information.

+ [Requirements](http://doc.oxypanel.com/Requirements)
+ [Install](http://doc.oxypanel.com/Install)
+ [Configuration](http://doc.oxypanel.com/Configuration)


# Internals

*note: links coming soon.
*
+ Oxypanel is extended by [`modules`](#)
+ `modules` can define [`requests`](#) and [`objects`](#)
+ `objects` are created using [`object factories`](#)
+ `objects` need view, edit and list [`templates`](#)


# Notes

+ No database/ORM, only [Luawa's simple database class](http://doc.luawa.com/database). It's better to hand write lovely SQL tables :)