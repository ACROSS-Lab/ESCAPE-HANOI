/**
* Name: GenerateCaseStudy
* Author: Patrick Taillandier
*/

model GenerateCaseStudy

global {
	
	shape_file buildings_shape_file <- shape_file("../../includes/buildings.shp");
	shape_file evacuation_shape_file <- shape_file("../../includes/evacuation.shp");
	shape_file roads_shape_file <- shape_file("../../includes/highway_line.shp");
	
	geometry shape <- envelope(buildings_shape_file)  ;
	graph road_network;
	
	geometry general_shape ;
	int nb_inhabitants <-  21559;
	map<string,float> proba_mode <- ["car"::0.01, "motorbike"::0.74,"bicycle"::0.19, "pedestrian"::0.06];
	int people_max_car <- 6;
	int people_max_motorbike <- 4;
	list<rgb> color_block;
	float road_limit <- 150 #m;
	init {
		create building from: buildings_shape_file;
		create evacuation_point from: evacuation_shape_file;
		create road from: roads_shape_file with: (num_lanes: int(get("lanes") != nil ? int(get("lanes")) : 1), one_way:get("oneway"));
	
		ask road where (each.shape.perimeter > road_limit) {
			list<geometry> sub_g <- shape to_sub_geometries([0.5,0.5]);
			shape <- sub_g[0];
			create road with: (shape: sub_g[1], maxspeed: maxspeed, num_lanes:num_lanes, one_way:one_way) ;
		}
	 	ask road {
			num_lanes <- num_lanes * 2;
			
			if maxspeed <= 0.0 {
				maxspeed <- 40 #km/#h;
			}
			if (one_way != "yes") {
				create road with: (shape: line(reverse(shape.points)), maxspeed: maxspeed, num_lanes:num_lanes) {
					linked_road <- myself;
					myself.linked_road <- self;
				}
			}
		}
		
		do init_intersection;
		
		general_shape <- convex_hull(union(building + evacuation_point collect (each.shape + 10.0))) + 10.0;
		ask road {
			if  index_use = 0 and not (self overlaps general_shape) {
				do die;
			}
		}
		
		graph gg <- main_connected_component(directed(as_edge_graph(road)));
		ask road {
			if not (self in gg.edges) {
				do die;
			}	
		}
		
		
		
		do init_intersection;
		write sample(nb_inhabitants);
	 	loop while: nb_inhabitants > 0 {
			building bd <- building[rnd_choice(building collect each.shape.area)];
			string chose_mode <- proba_mode.keys[rnd_choice(proba_mode.values)];
			switch chose_mode {
				match "car" {
					int nb_people <- rnd(1, min(people_max_car, nb_inhabitants));
					bd.car <- bd.car + 1;
					nb_inhabitants <- nb_inhabitants - nb_people;
				}
				match "motorbike" {
					int nb_people <- rnd(1, min(people_max_motorbike, nb_inhabitants));
					bd.motorbike <- bd.motorbike + 1;
					nb_inhabitants <- nb_inhabitants - nb_people;
				}
				match "bicycle" {
					bd.bicycle <- bd.bicycle + 1;
					nb_inhabitants <- nb_inhabitants - 1;
				}
				match "pedestrian" {
					bd.pedestrian <- bd.pedestrian + 1;
					nb_inhabitants <- nb_inhabitants - 1;
				}
			}
		}
		
		ask road {
			priority <- #max_float;
				
				intersection s <- road_network source_of  self; 
				intersection t <- road_network target_of  self; 
				loop e over: evacuation_point {
					if (e.closest_intersection in [s,t]) {
						priority <- 0.0;
						break;
					}
					path p1 <- road_network path_between (s,e.closest_intersection);
					path p2 <- road_network path_between (t,e.closest_intersection);
					if (p1 != nil and p1.shape != nil and p1.shape.perimeter < priority) {
						priority <-  p1.shape.perimeter ;
					}
					if (p2 != nil and p2.shape != nil and p2.shape.perimeter < priority) {
						priority <-  p2.shape.perimeter ;
					}
					if priority = 0.0 {
						break;
					}
			}
		}
		
		loop g over: intersection {
			list<building> bds <- building where (each.closest_intersection = g);
			if not empty(bds) {
				create urban_block with:(buildings::bds)  {
					id <- int(self);
					nb_people <- round(bds sum_of (each.car * (people_max_car/2.0) + each.motorbike * (people_max_motorbike / 2.0 ) + each.pedestrian ));
					intersections <- [g];
					list<road> egs <- road_network out_edges_of g;
					neighbors <- egs collect (road_network target_of each);
				}
			}
		}
		int min_people <- 1000; 
		loop while: urban_block min_of (each.nb_people) < min_people {
			int min_agreg <- #max_int;
			list<urban_block> to_agreg;
			
			loop i from: 0 to: length(urban_block) -1 {
				urban_block ui <- urban_block[i];
				if ui.nb_people < min_people {
					loop j from: 0 to: length(urban_block) -1 {
						if (i != j) {
							urban_block uj <- urban_block[j];
							bool to_agregate <- not empty ((ui.neighbors inter uj.intersections) + (uj.neighbors inter ui.intersections));
							
							if to_agregate and ((ui.nb_people + uj.nb_people  ) < min_agreg) {
								min_agreg <-ui.nb_people + uj.nb_people  ;
								to_agreg <- [ui,uj];
							}
						}
					}
				}
				
			} 
			if (empty((to_agreg))) {
				urban_block min_s <- urban_block with_min_of each.nb_people;
				list<intersection> inter <- min_s.neighbors;
				min_s.intersections <- min_s.intersections + min_s.neighbors;
				min_s.neighbors <- list<intersection>(inter accumulate (road_network neighbors_of each));
			} else {
				to_agreg[0].nb_people <- to_agreg[0].nb_people + to_agreg[1].nb_people;	
				to_agreg[0].buildings <- to_agreg[0].buildings + to_agreg[1].buildings;	
				to_agreg[0].intersections <- to_agreg[0].intersections + to_agreg[1].intersections;	
				to_agreg[0].neighbors <- to_agreg[0].neighbors + to_agreg[1].neighbors;	
				ask to_agreg[1] {
					do die;
				}
			}
		}
		int i <- 0;
		ask urban_block {
			id <- i;
			rgb col <- rnd_color(255);
			ask buildings {
				urban_block_id <-i;
				color <- col;
			}
			i <- i + 1;
		}
		
		ask road {
			 linked <- (linked_road = nil or dead(linked_road))? -1 : (linked_road.index);
		}
		save road format: "shp" to: "../includes/generated/roads.shp" attributes:["priority"::priority, "lanes"::num_lanes, "maxspeed"::maxspeed, "linked"::linked, "use"::index_use];
		save intersection format: "shp" to: "../includes/generated/intersections.shp";
		
		save building format: "shp" to: "../includes/generated/buildings.shp" attributes: ["evacua":: int(closest_evac),"inters":: (closest_intersection.index), "distance"::distance, "car"::car, "moto"::motorbike, "bicycle"::bicycle , "pedest"::pedestrian, "block"::urban_block_id];
		save evacuation_point format: "shp" to: "../includes/generated/evacuation_points.shp" attributes: ["inters":: (closest_intersection.index)];
		
	
		
	//	
	}
	
	action init_intersection {
		ask intersection {
			do die;
		}
		list<point> pts <- remove_duplicates(road accumulate [first(each.shape.points), last(each.shape.points)]);
		int i <- 0;
			loop pt over: pts {
			create intersection with: (location:pt) {
				index <- i;
				i <- i + 1;
			}
		}
		
		i <- 0;
		ask road {
			index <- i;
			i <- i + 1;
		}
		
		road_network <- as_driving_graph(road,intersection) with_shortest_path_algorithm #TransitNodeRouting;
		
		ask evacuation_point {
			road rd <- (road closest_to self);
			closest_intersection <- ([intersection(road_network source_of  rd),intersection(road_network target_of  rd)] with_min_of (each distance_to self)); 
		}
		
		ask building {
			road rd <- (road closest_to self);
			closest_intersection <- ([intersection(road_network source_of  rd),intersection(road_network target_of  rd)] with_min_of (each distance_to self)); 
			distance <- #max_float;
			closest_evac <- nil;
			path p_min; 
			loop e over: evacuation_point {
				if (e.closest_intersection) = closest_intersection {
					distance <- 0.0 ;
					closest_evac <- e;
					break;
				}else {
					path p1 <- road_network path_between (closest_intersection,e.closest_intersection);
					if (p1 != nil) {
						if(p1.shape != nil and p1.shape.perimeter < distance) {
							p_min <- p1;
							distance <-  p1.shape.perimeter ;
							closest_evac <- e;
						}	
					}
				}
			}
			if p_min != nil {
				ask p_min.edges collect road(each) {
					index_use <- index_use + 1;
				}
			}
		}
	
		
	}
}

species urban_block {
	int id;
	list<building> buildings;
	list<intersection> intersections;
	list<intersection> neighbors;
	int nb_people;
}
species evacuation_point schedules:[]{
	intersection closest_intersection;
	rgb color <- #red;
	aspect default {
		draw sphere(10.0) color: color;
		
	}
}

species building schedules:[]{
	int evacuat;
	int intersec;
	int car;
	int urban_block_id;
	int motorbike;
	int bicycle;
	int pedestrian;
	rgb color;
	evacuation_point closest_evac;
	intersection closest_intersection;
	float distance;
	aspect default {
		draw shape color: color border: #black;
	}
}

species road skills: [road_skill] schedules:[]{
	float priority;
	string one_way;
	int index_use;
	int linked;
	int index;
	aspect default {
		draw shape color: #gray;
	}
	
}

species intersection skills: [intersection_skill] schedules:[]{
	int index ;
	aspect default { 
		draw square(1.0) color: #magenta;
	}
}



experiment Generate type: gui {
	output {
		display map {
			graphics "geom" {
				draw general_shape color: #yellow border: #black;
			}
			species building;
			species evacuation_point;
			species road;
			species intersection;
		}
	}
}
