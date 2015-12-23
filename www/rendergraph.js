(function(){ sigma.parsers.json("data/current_graph.json",

        {
            container: 'graph2'
        },


        function(s) { //This function is passed an instance of Sigma s
			 var g = document.querySelector('#graph2');

			try{
			Shiny.addCustomMessageHandler("commmemmsg",
			  function(message) {
				  
			    JSON.parse(JSON.stringify(message),function(k,v){if(k=="id"){
						s.graph.nodes().forEach(function(node, i, a) {
							if(node.id==v){
			                    node.color = "#b870db";
							}
						});
		s.refresh();
				}});
			  }
			);
			}
			catch(err){
				
			}


		Shiny.addCustomMessageHandler("updategraph",
		  function(message) {
			 
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
				  //s.graph.kill();
              new_s.graph.nodes().forEach(function(node, i, a) {

                  switch (node.type) {
                      case "Chemical":
                          node.color = "#FF8800";
                          break;

                      case "Disease":
                          node.color = "#CC0000";
                          break;

                      case "Protein":
                          node.color = "#77B300";
                          break;

                      case "Community":
                          node.color = "#2A9FD6";
                          break;

                      default:
                          break;
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
                  Shiny.onInputChange("comm_id", e.data.node.label);
              });
			  s = new_s;
		  });
			  
		  });



	      var g = document.querySelector('#graph2');
	      var p = g.parentNode;
	      p.removeChild(g);
	      var c = document.createElement('div');
	      c.setAttribute('id', 'graph2');
	      p.appendChild(c);


        });
		
	}).call(this)
