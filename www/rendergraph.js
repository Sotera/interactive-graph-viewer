$(document).ready(function() {
  
	var searchelm = "";
	var current_s;

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
        function(s) {
          
          current_s = s;
          
          var defaultEntTypes = $("input[name='entTypes']:checked").map(function(){
            return $(this).val();
          });

          s.graph.nodes().forEach(
            function(node, i, a) {
		          if(searchelm !== "") {
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
          

          var filter = new sigma.plugins.filter(s);
          filter
                .undo('node-filter')
                .nodesBy(function(n) {
                  return n.type=='Community' || (($.inArray(n.type, defaultEntTypes) > -1));
                },
                'node-filter')
                .apply();

          $(document).on('shiny:inputchanged', function(event) {
            if (event.name === 'entTypes') {
              filter
                .undo('node-filter')
                .nodesBy(function(n) {
                  return n.type=='Community' || (($.inArray(n.type, event.value) > -1));
                },
                'node-filter')
                .apply();
            }
          });


          //Call refresh to render the new graph
          s.refresh();

          // Finally, turn on force atlas 2
          s.startForceAtlas2({
            startingIterations: 150,
            iterationsPerRender: 50,
            barnesHutOptimize: false,
            adjustSizes: true,
            worker: true,
            strongGravityMode: true,
            lingLogMode: true
          });

          function stop() {
            s.killForceAtlas2();
          }

          window.setTimeout(stop, 2000);
          s.refresh();

          // action if we click on a node
          s.bind('clickNode', function(e) {
              window.console.log(e.type, e.data.node.label, e.data.captor);
              Shiny.onInputChange("comm_id", e.data.node.comm_id);
          });
        }
      );
    }
  );
  
  try {
    Shiny.addCustomMessageHandler("commmemmsg",
      function(message) {
        console.log("commmemmsg");
        console.log(current_s.graph.nodes().length);
        JSON.parse(JSON.stringify(message), function(k, v) {
          if (k == "id") {
            var elems = String(v).split(",");
            current_s.graph.nodes().forEach(
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
            current_s.refresh();
          }
        });
      }
    );
  }
  catch (err) {
  }
  
  
});
