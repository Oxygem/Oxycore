// Oxypanel Core
// File: app/inc/js/lib/graph.js
// Desc: graphing based on rickshaw (which is based on d3)
//       loaded in oxypanel.js but won't work until d3 & rickshaw are loaded (not by default)

'use strict';

var graph = {
    palette: new Rickshaw.Color.Palette({ scheme: 'colorwheel' }),

    create: function( $element, data, options ) {
        var self = this,
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

        //build list of x values & find max x
        var x_values = [],
            x_max = 0;
        util.each( data, function( key, value ) {
            util.each( value.data, function( x, y ) {
                if( x > x_max )
                    x_max = x;

                if( x_values.indexOf( x ) == -1 )
                    x_values.push( x );
            });
        });

        //build object data -> rickshaw data
        util.each( data, function( key, value ) {
            //ensure x values
            util.each( x_values, function( _, x ) {
                if( !value.data[x] )
                    value.data[x] = 0;
            });

            //turn x=>y into []{x, y}
            var array_data = [];
            util.each( value.data, function( x, y ) {
                array_data.push({ x: parseInt( x ), y: y });
            });

            graph.data.push({
                color: self.palette.color(),
                data: array_data,
                name: value.name
            });
        });

        //force scale if dealing with percentages
        var padding = {},
            min, max;
        if( options.percentify ) {
            min = 0,
            max = 100;
        //pad if not
        } else {
            padding = {
                top: 0.3
            }
        }

        //create rickshaw graph
        graph.rickshaw = new Rickshaw.Graph({
            element: $element,
            height: options.height || 150,
            renderer: options.renderer || 'area',
            series: graph.data,
            min: min,
            max: max,
            padding: padding
        });

        //create rickshaw hover detail
        graph.rickshaw_hover = new Rickshaw.Graph.HoverDetail({
            graph: graph.rickshaw
        });

        graph.x_axis = new Rickshaw.Graph.Axis.Time( {
            graph: graph.rickshaw,
            orientation: 'bottom'
        });
        graph.x_axis.render();

        graph.y_axis = new Rickshaw.Graph.Axis.Y( {
            graph: graph.rickshaw,
            pixelsPerTick: 20
        });
        graph.y_axis.render();

        if( options.$legend ) {
            graph.legend = new Rickshaw.Graph.Legend( {
                graph: graph.rickshaw,
                element: options.$legend
            });
            new Rickshaw.Graph.Behavior.Series.Toggle({
                graph: graph.rickshaw,
                legend: graph.legend
            });
        }

        //render & return
        graph.rickshaw.render();
        return graph;
    }
};