$(document).ready(function() {
  
	var searchelm = "";
	var filter;
  
  sigma.parsers.json("data/current_graph.json",
  
    {
      container: 'graph2'
    },


    function(s) { //This function is passed an instance of Sigma s
      //filter = new sigma.plugins.filter(s);
      var g = document.querySelector('#graph2');

      try {
        Shiny.addCustomMessageHandler("commmemmsg",
          function(message) {
            console.log("commmemmsg");
            JSON.parse(JSON.stringify(message), function(k, v) {
              if (k == "id") {
		            elems = String(v).split(",");
                s.graph.nodes().forEach(
                  function(node, i, a) {
                    node.color = node.originalcolor;
                    for (var ix = 0; ix < elems.length; ix++) {
                      elem = elems[ix];
                      if (node.id == elem) {
                        node.color = "#FFD700";
                      }
                    }
		                searchelm=elems;
                  }
                );
                s.refresh();
              }
            });
          }
        );
      }
      catch (err) {
      }

      Shiny.addCustomMessageHandler("updategraph",
        function(message) {
          console.log("updategraph");
          // to delete & refresh the graph
          var g = document.querySelector('#graph2');
          var p = g.parentNode;
          p.removeChild(g);
          var c = document.createElement('div');
          c.setAttribute('id', 'graph2');
          p.appendChild(c);
    
          //create_graph(); 
    
          sigma.parsers.json("data/current_graph.json",
            {
              container: 'graph2'
            },
            function(new_s) {
              
              
              
              new_s.graph.nodes().forEach(
                function(node, i, a) {
				          if(searchelm!="") {
  				          for (var ix = 0; ix < searchelm.length; ix++) {
  					          elem = searchelm[ix];
            					if (node.id == elem) { 
                        node.color = "#FFD700";
            					}
            					else {
            						node.color = node.originalcolor;
            					} 
                    }
                  }
                }
              );
              
              filter = new sigma.plugins.filter(new_s);
              $(document).on('shiny:inputchanged', function(event) {
                if (event.name === 'entTypes') {
                  filter
                    .undo('test-filter')
                    .nodesBy(function(n) {
//                      console.log(n.name);
//                      console.log(n.type);
//                      console.log(event.value);
//                      console.log($.inArray(n.type, event.value));
                      //return true;
                      return ($.inArray(n.type, event.value) > -1)
                    },
                    'test-filter')
                    .apply();
                }
              });

              //Call refresh to render the new graph
              new_s.refresh();

              // Finally, turn on force atlas 2
              new_s.startForceAtlas2({
                startingIterations: 150,
                iterationsPerRender: 50,
                barnesHutOptimize: false,
                adjustSizes: true,
                worker: true,
                strongGravityMode: true,
                lingLogMode: true
              });

              function stop() {
                new_s.killForceAtlas2();
              }

              window.setTimeout(stop, 2000);
              new_s.refresh();

              // action if we click on a node
              new_s.bind('clickNode', function(e) {
                  window.console.log(e.type, e.data.node.label, e.data.captor);
                  Shiny.onInputChange("comm_id", e.data.node.comm_id);
              });
              s = new_s;
              
              
              
              
            }
          );
        }
      );

      // var g = document.querySelector('#graph2');
      var p = g.parentNode;
      p.removeChild(g);
      var c = document.createElement('div');
      c.setAttribute('id', 'graph2');
      p.appendChild(c);
      
      
      
      
      
//      $(document).on('shiny:inputchanged', function(event) {
//        if (event.name === 'entTypes') {
//          console.log(event.value);
//        }
//      });

    }
  );
});
