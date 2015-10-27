import json
from bs4 import BeautifulSoup


def convert_xml_to_json():
	with open("./www/data/tmp.xml", "r") as xml:
		soup = BeautifulSoup(xml, "lxml")
		nodes = soup.find_all('node')
		edges = soup.find_all('edge')

		# Read the nodes
		node_data = {}
		count = 1
		for node in nodes:
			igraph_id =  node['id']
			idx = count
			count += 1
			datas = node.find_all('data')
			t = None
			n = None
			for data in datas:
				if data['key'] == 'v_name':
					n = data.get_text()
				else:
					t = data.get_text()
			node_data[igraph_id] = {'name':n, 'type':t, 'idx':idx}

		# Read the edges
		edge_data = []
		for edge in edges:
			source = edge['source']
			target = edge['target']
			edge_data.append((source, target))


		# Node JSON
		node_json = []
		for node in node_data:
			node_json.append({'id': str(node_data[node]['idx']),
				'label': str(node_data[node]['name']),
				'color': "rgb(90,90,90)",
				'size': 100,
				'type': str(node_data[node]['type']),
				'x': 0,
				'y': 0})

        # Edge JSON
        count = 1
        edge_json = []
        for a,b in edge_data:
            a_idx = node_data[a]['idx']
            b_idx = node_data[b]['idx']
            edge_json.append({'id':str(count),'source': str(a_idx),'target': str(b_idx) })
            count +=1

        # Write the file
        with open("./www/data/current_graph.json", "w") as g:
            json.dump({'nodes':node_json, 'edges':edge_json}, g)



			


if __name__ == "__main__":
    convert_xml_to_json()