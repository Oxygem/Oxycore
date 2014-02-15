// Oxypanel Core
// File: app/inc/js/graph.js
// Desc: graphing based on rickshaw (which is based on d3)
//       loaded in oxypanel.js but won't work until d3 & rickshaw are loaded (not by default)

'use strict';

var graph = {
    create: function( $element, data, options ) {
        var palette = new Rickshaw.Color.Palette({ scheme: 'munin' }),
            options = options || {},
            graph = {
                data: []
            };

        //update function
        graph.update = function( data ) {
            var self = this;

            //messy
            util.each( data, function( _, points ) {
                util.each( self.data, function( key, series ) {
                    if( points.name == series.name ) {
                        util.each( points.data, function( _, point ) {
                            self.data[key].data.push( point );
                        });
                    }
                });
            });

            this.rickshaw.update();
        };

        //build series data
        util.each( data, function( key, value ) {
            graph.data.push({
                color: palette.color(),
                data: value.data,
                name: value.name
            });
        });

        //create rickshaw graph
        graph.rickshaw = new Rickshaw.Graph({
            element: $element,
            height: options.height || 150,
            renderer: options.renderer || 'line',
            series: graph.data
        });

        //create rickshaw hover detail
        graph.rickshaw_hover = new Rickshaw.Graph.HoverDetail({
            graph: graph.rickshaw
        });

        //render & return
        graph.rickshaw.render();
        return graph;
    }
};