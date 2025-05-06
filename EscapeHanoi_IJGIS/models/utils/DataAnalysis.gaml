/**
* Name: data analysis
* Author: Patrick Taillandier
*/

model graphAnalysis

global {
	
	shape_file buildings_shape_file <- shape_file("../../includes/generated/buildings.shp");
	shape_file evacuation_shape_file <- shape_file("../../includes/generated/evacuation_points.shp");
	shape_file roads_shape_file <- shape_file("../../includes/generated/roads.shp");
	shape_file intersections_shape_file <- shape_file("../../includes/generated/intersections.shp");

	geometry shape <- envelope(roads_shape_file)  ;
	float distance_max;
	int max_use;
	float max_priority;
	string qualitativePalette <- "Paired" among:["Accents","Paired","Set3","Set2","Set1","Dark2","Pastel2","Pastel1"];
	list<float> val_evacuation_block <- [0.3,0.0,0.4,0.0,0.1,0.2,0.3,0.0,0.5,0.0,3.0,4.0,5.0,2.0,4.0,2.0,0.0,2.0,0.0,0.0];
	float size_change <- 5000 #m;
	list<rgb> palette_evac <- brewer_colors(qualitativePalette, length(evacuation_shape_file));
	
	float TIME_MAX <- 1#h;
	
	init {
		create intersection from: intersections_shape_file;
		create building from: buildings_shape_file with: ( urban_block_id:int(get("block")));
		create evacuation_point from: evacuation_shape_file {
			closest_intersection <- intersection[inters];
			color <- palette_evac[int(self)];
		}
		
		evacuation_point current_ev <- evacuation_point closest_to {world.shape.width, world.shape.height};
		int ii <- 0;
		loop while: not empty(evacuation_point where (each.id = -1)) {
			current_ev.id <- ii;
			ii <- ii +1;
			list<evacuation_point> pts <- evacuation_point where (each.id = -1);
			if not empty(pts) {
				current_ev <- pts closest_to current_ev;
			}
		}
		
		create road from: roads_shape_file ;
		ask building {
			closest_intersection <- intersection[inters];
			closest_evac <- evacuation_point[evacua];
		}
		ask road {	
			linked_road <- linked = -1 ? nil : road[linked];
			num_lanes <- lanes;
		}
		
		list<road> rds <- (road sort_by (-1 * each.use));
		float dist;
		loop while: dist < size_change {
			road r <- first(rds);
			rds >> r;
			r.highest <- true;
			dist <- dist + r.shape.perimeter;
		}
		distance_max <- building max_of each.distance;
		
		
		max_use <- road max_of (each.use);// / each.num_lanes);
		max_priority <- (road where (each.priority < #max_float)) max_of (each.priority);
		
		
		map<int,list<building>> bds <- building group_by each.urban_block_id;
		list<rgb> palette_evac_2 <- brewer_colors(qualitativePalette, length(bds) + 2);
		int i <- 0;
		loop g over: bds.keys {
			rgb col <- palette_evac_2[i];
			ask bds[g] {
				color <- col;
			}
			i <- i +1;
			point pt <- mean(bds[g] collect each.location);
			//pt <- {pt.x,pt.y,10};
			create zone with: (color: col, id: g, location: pt);
		}
		
		list<int> zones_target <- val_evacuation_block copy_between (10, 20) collect round(each);
		
	
		ask zone {
			evacuation_time <- TIME_MAX * val_evacuation_block[id];
			zone_target <-evacuation_point first_with (each.id = zones_target[id]);
			
		}		
		
		
	}

}

species intersection skills: [intersection_skill] schedules:[]{
	aspect default {
		draw square(1.0) color: #magenta;
	}
}



species evacuation_point schedules:[]{
	int id <- -1;
	int inters;
	intersection closest_intersection;
	
	rgb color ;
	aspect default {
		draw sphere(10.0) color: color;
		
	}
	
	aspect id_aspect {
		draw circle(10.0) color: #white;
	}
	
	aspect dist {
		draw sphere(10.0) color: #white;
	}
	aspect centrality {
		draw sphere(10.0) color: #gold;
	}
}

species building schedules:[]{
	int evacua;
	int inters;
	int urban_block_id;
	rgb color;
	
	evacuation_point closest_evac;
	intersection closest_intersection;
	float distance;
	aspect default {
		draw shape color: closest_evac.color border: #black;
	}
	aspect dist {
		float val <- 255 * (1 - distance/distance_max);
		draw shape color: rgb(255 - val, val, 0.0);
	}
	aspect group {
		draw shape color:color border: #black;
	}
}

species road skills: [road_skill] schedules:[]{
	geometry geom_display;
	float priority;
	int use;
	int linked;
	int lanes;
	bool highest <- false;
	aspect default {
		draw shape color: #gray;
	}
	aspect improve_road {
			int v <- use;///num_lanes;
		float val <- 255 * ( 1 - (v / max_use)^(0.1)); 
		
		draw highest ? (shape +(5.0, true)) : shape color: highest ? #magenta : #white;
	}
	
	aspect centrality {
		int v <- use;///num_lanes;
		float val <- 255 * ( 1 - (v / max_use)^(0.2)); 
		draw shape + (num_lanes * 2.0, true) color: rgb(255, val,val);
	}
	
	aspect priority {
		float val <- 255 * ( 1 - (priority/ max_priority)); 
		draw shape + (num_lanes , true) color: rgb(255 - val, val,0);
	}
}


experiment road_priority type: gui {
	

	output {
		display map type: opengl axes: false background: #black {
			species road aspect: priority refresh: false;
			species evacuation_point refresh: false;
			
		}
	}
}



species zone {
	rgb color;
	int id;
	evacuation_point zone_target;
	float evacuation_time;
	
	aspect default {
		geometry g <-  curve(location,zone_target.location, rnd(0.1,0.8), 50,flip(0.5) ? 0.0 : 180.0) ; 
		
		draw g width: 7 end_arrow: 20 color: color;
		draw circle(30.0) color: color border: #black depth: 0.1;
		draw "" + 	round(evacuation_time / #mn) color: #black  font: font("Helvetica", 40 , #bold) anchor: #center at: {location.x, location.y, 10.0}  ; 
	}
}

experiment centrality_betweeness type: gui {
	

	output {
		display map type: opengl axes: false background: #black {
			species road aspect: centrality refresh: false;
			species evacuation_point refresh: false;
			
		}
	}
}


experiment road_enhance type: gui { 
	

	output {
		display map type: opengl axes: false background: #black {
			species road aspect: improve_road refresh: false;
			species evacuation_point refresh: false;
			
		}
	}
}


experiment building_group type: gui {
	output {
		display map type: opengl axes: false background: #black {
			species building aspect: group refresh: false;
			species evacuation_point  aspect: dist refresh: false;
			
		}
	}
}

experiment zone_evacuation type: gui {
	output {
		display map type: opengl axes: false background: #black {
			species building aspect: group ;
			species zone;// position: {0,0,0.01};
			species evacuation_point  aspect: id_aspect ;
			
		}
	}
}


experiment building_closest_exit type: gui {
	output {
		display map type: opengl axes: false background: #black {
			species building  refresh: false;
			species evacuation_point  refresh: false;
			
		}
	}
}



experiment building_distance type: gui {
	output {
		display map type: opengl axes: false background: #black {
			species building aspect: dist refresh: false;
			species evacuation_point aspect: dist refresh: false;
			graphics "legend" refresh: false{
				draw ("Distance to the closest evacuation point") at: {world.shape.width - 450, 150} color: #white font: font("Helvetica", 30 , #bold); 
				
				draw rectangle(300,50) at: {world.shape.width - 250, 200} texture: "../../includes/degrade.png";
				draw ("0 m") at:   {world.shape.width - 450, 210} color: #white  font: font("Helvetica", 30 , #bold);
				draw ("" +round(building max_of each.distance) + " m") at: {world.shape.width - 90, 210} color: #white  font: font("Helvetica", 30 , #bold);
			}
		}
	}
}