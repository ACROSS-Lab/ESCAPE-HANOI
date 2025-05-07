/**
* Name: Mainxp
* Author: Patrick Taillandier
*/

model Mainxp

global schedules: people_ordered{
	
	shape_file buildings_shape_file <- shape_file("../includes/generated/buildings.shp");
	shape_file evacuation_shape_file <- shape_file("../includes/generated/evacuation_points.shp");
	shape_file roads_shape_file <- shape_file("../includes/generated/roads.shp");
	shape_file intersections_shape_file <- shape_file("../includes/generated/intersections.shp");

	
	string qualitativePalette <- "Set1" among:["Accents","Paired","Set3","Set2","Set1","Dark2","Pastel2","Pastel1"];

	list<rgb> palette_evac <- brewer_colors(qualitativePalette, length(evacuation_shape_file));

	string shortest_paths_file <- "../includes/shortest_paths.csv";
	file file_ssp;
	float lane_width <- 0.7;
	geometry shape <- envelope(buildings_shape_file)  ;
	graph road_network;
	
	float power_choose_target <- 1.0;
	string scenario <- "alpha_beta" among: ["alpha_beta", "urban_blocks"];
	float alpha <-1.0;
	float beta <- 1.0;
	float z1 <- 0.0; float z2 <- 0.1;float z3 <- 0.2;float z4 <- 0.3;float z5 <- 0.4;float z6 <- 0.5;float z7 <- 0.6;float z8 <- 0.7;float z9 <- 0.8;float z10 <- 0.9;
	int i1 <- 0;int i2 <- 0;int i3 <- 0;int i4 <- 0;int i5 <- 0;int i6 <- 0;int i7 <- 0;int i8 <- 0;int i9 <- 0;int i10 <- 0;
	
	list<float> zones_time;
	float TIME_MAX <- 60.0 #mn;
	float step <-0.5#s;
	float priority_min_road;
	
	bool save_results <- false;
	string folder_results <- "normal";
	float save_time <- 1#mn;
	float coeff_change_path <- 0.01 ;
	float tj_threshold <- 0.75;
	
	list<float> evacuation_time_car;
	list<float> evacuation_time_moto;
	list<float> evacuation_time_pedestrian;
	list<float> evacuation_time_bicycle;
	
	list<moving_agent> people_ordered;
				
	bool end <- false update: empty(people);
	bool already_save <- false;
	
	list<moving_agent> people -> {(pedestrian as list) + (car as list) + (motorbike as list) + (bicycle as list)};
	
	float evacuation_time_ <- #max_float;
	float average_time_spent  <- #max_float;
	
	float change_road_lane_perimeters <- 0 #m;
	
	init {
		create intersection from: intersections_shape_file;
		create building from: buildings_shape_file with: (num_car: int(get(("car"))),num_moto: int(get(("moto"))),num_bicycle: int(get(("bicycle"))),num_pedestrian: int(get(("pedest"))), urban_block_id:int(get("block")));
		create evacuation_point from: evacuation_shape_file {
			closest_intersection <- intersection[inters];
			closest_intersection.evacuation <- self;
			location <- closest_intersection.location;
			id <- -1;
		}
		evacuation_point current_ev <- evacuation_point closest_to {world.shape.width, world.shape.height};
		int i <- 0;
		loop while: not empty(evacuation_point where (each.id = -1)) {
			current_ev.id <- i;
			i <- i +1;
			list<evacuation_point> pts <- evacuation_point where (each.id = -1);
			if not empty(pts) {
				current_ev <- pts closest_to current_ev;
			}
		}
		create road from: roads_shape_file;
		ask building {
			closest_intersection <- intersection[inters];
			closest_evac <- evacuation_point[evacua];
		}
		ask road {	
			linked_road <- linked = -1 ? nil : road[linked];
			num_lanes <- lanes;
			geom_display <- shape + (num_lanes * lane_width);
			capacity <- round(num_lanes * shape.perimeter);
		}
		
		if (change_road_lane_perimeters > 0) {
			
			list<road> rds <- (road sort_by (-1 * each.use));
			float dist;
			loop while: dist < change_road_lane_perimeters {
				road r <- first(rds);
				rds >> r;
				r.num_lanes <- r.num_lanes + 1;
				dist <- dist + r.shape.perimeter;
			}
		}
		road_network <- (as_driving_graph(road,intersection) with_shortest_path_algorithm #NBAStar) use_cache false;
		priority_min_road <- road min_of each.priority;
			
		
		
		ask building {
			if num_bicycle > 0 {
				create bicycle number: num_bicycle with: (home:self);
			}
			if num_car > 0 {
				create car number: num_car with: (home:self);
			}
			if num_moto > 0 {
				create motorbike number: num_moto with: (home:self);
			}
			if num_pedestrian > 0 {
				create pedestrian number: num_pedestrian with: (home:self);
			}
		}
		
		
		float distance_max <- building max_of each.distance;
		zones_time <- [z1,z2,z3,z4,z5,z6,z7,z8,z9,z10];
		list<int> zones_target <- [round(i1),round(i2),round(i3),round(i4),round(i5),round(i6),round(i7),round(i8),round(i9),round(i10)];
		
		ask people {
			if scenario = "urban_blocks" {
				evacuation_time <- TIME_MAX * zones_time[home.urban_block_id];
				zone_target <- zones_target[home.urban_block_id];
			}else {
				evacuation_time <- TIME_MAX * beta *((alpha * rnd(1.0)) + (1 - alpha) * home.distance/distance_max);
			}
		}
		if scenario = "urban_blocks" {
			map<int,list<building>> bds <- building group_by each.urban_block_id;
			loop g over: bds.keys {
				rgb col <- rnd_color(255);
				ask bds[g] {
					color <- col;
				}
				create zone with: (color: col, id: g, shape: convex_hull(union(bds[g] collect envelope(each))).contour + 2.0);
			}
			
		}
		people_ordered <- shuffle(people);
	}
	
	reflex update_priority_graph when: not end{
		
		people_ordered <- [];
		ask shuffle(road) sort_by each.priority {
			list<moving_agent> people_on <- shuffle(list<moving_agent>(all_agents));
			people_ordered <- people_ordered + (people_on sort_by (each.distance_to_goal/ (100 * world.shape.width) - each.segment_index_on_road)) ;
		}
		people_ordered <- people_ordered + shuffle(people- people_ordered);
		
	}
	
	reflex end_sim when: not save_results and end {
		do pause;
	}
	
	reflex force_end when: time > 15000 {
		end <- true;
	}
	
	reflex save_result when:save_results and every(save_time){
		
		if (scenario = "urban_blocks") {
				save "" + seed + "," + int(world) + "," + cycle + ","+ 
				z1 + "," + z2 + "," + z3 + "," + z4 + "," + z5 + "," + z6 + "," + z7 + "," + z8 + "," + z9 + "," + z10 + ","+ 
				
					i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + "," + i6 + "," + i7 + "," + i8 + "," + i9 + "," + i10+ ","+  coeff_change_path +"," +tj_threshold +","+
				
				length(car) +"," + length(motorbike) + "," +length(bicycle) + "," + length(pedestrian) format: "text" to: 
		(folder_results+ "/result_zone.csv")  rewrite: false;
		} else {
				save "" + seed + "," + int(world) + "," + cycle + ","+ alpha+ ","+ beta+"," + coeff_change_path +"," +tj_threshold +","+ change_road_lane_perimeters + "," +length(car) +"," + length(motorbike) + "," +length(bicycle) + "," + length(pedestrian) format: "text" to: 
		(folder_results+ "/result_"  +alpha + "_" + beta + ".csv")  rewrite: false;
		}
		
		if end and not already_save{
			evacuation_time_ <- time;
			average_time_spent <- mean(evacuation_time_pedestrian + evacuation_time_moto + evacuation_time_car + evacuation_time_bicycle);
	
			string sp <- "";
			loop ep over: evacuation_time_pedestrian {
				sp <- sp + string(ep) + ",";
			}
			string sm <- "";
			loop em over: evacuation_time_moto {
				sm <- sm +  string(em) + ",";
			}
			string sc <- "";
			loop ec over: evacuation_time_car{
				sc <- sc + string(ec) + ",";
			}
			string sb <- "";
			loop eb over: evacuation_time_bicycle{
				sb <- sb + string(eb) + ",";
			}
			
			string res;
			string path_;
			if (scenario = "urban_blocks") {
				res <- "" + seed + "," + int(world) + "," + cycle + ","+ 
				z1 + "," + z2 + "," + z3 + "," + z4 + "," + z5 + "," + z6 + "," + z7 + "," + z8 + "," + z9 + "," + z10 + ","+ 
				
					i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + "," + i6 + "," + i7 + "," + i8 + "," + i9 + "," + i10+ ","+ 
				
				coeff_change_path +"," +tj_threshold +","+ sp + ";" + sb  + ";" + sm + ";" + sc ;
				path_ <-(folder_results+ "/result_evacuation_time_zone.csv") ;
			} else {
				res <- "" + seed + "," + int(world) + "," + cycle + ","+ alpha+ ","+ beta+"," + coeff_change_path +"," +tj_threshold +","+change_road_lane_perimeters + "," + sp + ";" + sb +";" + sm + ";" + sc ;
				
				path_ <-(folder_results+ "/result_evacuation_time_"  +alpha + "_" + beta + ".csv") ;
			}
			
			save res format: "text" to: path_ rewrite: false; 
		
			string evac <- "";
			loop e over: evacuation_point {
				evac <- evac + e.name + ";" + e.nb_arrived   + "|";
			}
			if (scenario = "urban_blocks") {
				res <- "" + seed + "," + int(world) + "," + cycle + ","+ 
				z1 + "," + z2 + "," + z3 + "," + z4 + "," + z5 + "," + z6 + "," + z7 + "," + z8 + "," + z9 + "," + z10+ ","+ 
				i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + "," + i6 + "," + i7 + "," + i8 + "," + i9 + "," + i10+ ","+ 
				
				
				coeff_change_path +"," +tj_threshold +","+evac ;
				path_ <-(folder_results+ "/result_evacuation_points.csv") ;
			} else {
				res <- "" + seed + "," + int(world) + "," + cycle + ","+ alpha+ ","+ beta+","+ coeff_change_path +"," +tj_threshold +","+ change_road_lane_perimeters + "," + evac ;
				
				path_ <-(folder_results+ "/result_evacuation_points_"  +alpha + "_" + beta + ".csv") ;
			}
			
			save res format: "text" to: path_ rewrite: false; 
			already_save <- true;
			ask experiment {do compact_memory;}
		}
	
	}
	
	
}

species evacuation_point schedules:[]{
	int id;
	int inters;
	map<string, int> nb_arrived;
	intersection closest_intersection;
	
	rgb color <- palette_evac[int(self)];
	aspect default {
		draw sphere(10.0) color: color;
		
	}
	
	aspect aspect_blocks {
		draw circle(10.0) color: color;
		draw string(id)  color: #black  font: font("Helvetica", 40 , #bold); 
	}
}

species zone {
	rgb color;
	int id;
	aspect default {
		draw shape + 1 color: color;
		draw "i"+ (id + 1)  color: color  font: font("Helvetica", 50 , #bold); 
				
	}
}
species building schedules:[]{
	rgb color <- #gray;
	int evacua;
	int inters;
	int num_car;
	int num_bicycle;
	int num_moto;
	int num_pedestrian;
	
	evacuation_point closest_evac;
	intersection closest_intersection;
	int urban_block_id;
	float distance;
	aspect default {
		draw shape color: color border: #black;
	}
}

species road skills: [road_skill] schedules: end ? [] : road{
	geometry geom_display;
	int linked;
	int use;
	int lanes;
	float vehicles <- 0.0 update: (all_agents sum_of (moving_agent(each).vehicle_length));
	bool traffic_jam <- false update: (vehicles/ capacity) > tj_threshold;
	int capacity;
	float priority;
	
	
	aspect default {
		draw shape color: traffic_jam ? #red : #gray end_arrow: 2.0;
	}
	
}

species intersection skills: [intersection_skill] schedules:[]{
	int index <- int(self);
	evacuation_point evacuation;
	aspect default {
		draw square(1.0) color: #magenta;
	}
}
species moving_agent skills: [driving] schedules:[] {
	rgb color <- rnd_color(255);
	bool leave <- false ;
	evacuation_point evac_pt;
	date leaving_date ;
	float proba_use_linked_road <- 1.0;
	float proba_respect_priorities <- 0.5;
	int linked_lane_limit <- 1;
	int lane_change_limit <- -1;
	
	bool parked <- false;

	list<road> roads_with_traffic_jam;
	
	float priority;
	float evacuation_time;
	building home;
	intersection target_node ;
	float time_before_parking <- 0.0;
	float time_stuck <- 0.0;
	
	float politeness_factor_init ;
	float vehicle_length_init;
	float proba_use_linked_road_init <- 1.0;
	float safety_distance_coeff_init;
	float max_acceleration_init;
	float time_headway_init;
	float acc_gain_threshold_init <- 0.2;
	float min_safety_distance_init <- 0.5;
	float proba_respect_priorities_init;
	
	int zone_target;
	init {
		do reset_properties;
	}
	
	action reset_properties {
		 politeness_factor <- politeness_factor_init ;
		 vehicle_length <- vehicle_length_init;
		 proba_use_linked_road <- proba_use_linked_road_init;
		  max_acceleration <- max_acceleration_init;	
		 time_headway <- time_headway_init;
		 safety_distance_coeff <- safety_distance_coeff_init;
		 acc_gain_threshold <- acc_gain_threshold_init;
		min_safety_distance <- min_safety_distance_init;
		proba_respect_priorities <- proba_respect_priorities_init;
	}
	
	action to_park {
		proba_use_linked_road <- 0.0;
	}
	
	
	action choose_evacuation_point(intersection source) {
		map<road,float> weights <- roads_with_traffic_jam as_map (each::(each.shape.perimeter * world.shape.width));
		road_network <- road_network with_weights weights;
		using topology (road_network) {
			evac_pt <-  evacuation_point with_min_of (source distance_to each.closest_intersection) ;
		}
		weights <- roads_with_traffic_jam as_map (each::(each.shape.perimeter));
		
		color <-evac_pt.color;
		target_node <- evac_pt.closest_intersection;
	}
	
	action compute_path_traffic_jam(intersection source) {
		map<road,float> weights <- roads_with_traffic_jam as_map (each::(each.shape.perimeter * world.shape.width));
		road_network <- road_network with_weights weights;
	
		do compute_path(graph: road_network, source: source, target: target_node);
		weights <- roads_with_traffic_jam as_map (each::(each.shape.perimeter));
		road_network <- road_network with_weights weights;
	
	}
	action initialize {
		location <- (home.location);
	
		intersection current_node <- home.closest_intersection;
		roads_with_traffic_jam <- (list<road>(current_node.roads_in + current_node.roads_out)) where each.traffic_jam; 
		if (scenario = "urban_blocks") {
			evac_pt <- evacuation_point first_with (each.id = zone_target);
		
		} else {
			evac_pt <- home.closest_evac;
		
		}
		color <-evac_pt.color;
		target_node <- evac_pt.closest_intersection;
		if current_node = target_node {
			do die;
		}
		do compute_path_traffic_jam(current_node);
	 		
	}
	
	float external_factor_impact(road new_road, float remaining_time) { 
		intersection current_node <- intersection(new_road.source_node);
		if (current_node.evacuation != nil) {
			evac_pt <-intersection(new_road.source_node).evacuation;
			final_target <- nil;
			return -1.0;
		}
		list<road> rds <- (list<road>(current_node.roads_in + current_node.roads_out));
		loop rd over: rds {
			if (rd.traffic_jam)  {
				if  not (rd in roads_with_traffic_jam) {
					roads_with_traffic_jam  << rd;
				}
				
			} else {
				roads_with_traffic_jam >> rd;
			}
		}
		
	if (species(self) != car) and (new_road.traffic_jam) and flip(coeff_change_path *  (self distance_to evac_pt)) and length(intersection(new_road.source_node).roads_out ) > 1 and (new_road.target_node != evac_pt.closest_intersection) {
			if (current_road != nil) {
				do unregister;
				
			}
			do choose_evacuation_point(current_node);
			
			if new_road.source_node = target_node {
				final_target <- nil;
				return -1.0;
			}
			 do compute_path_traffic_jam(current_node);
			return -1.0;	
			
		}
		return remaining_time;
	}
	
	action add_evacuation_time;
	action arrived(evacuation_point evac) {
		evac.nb_arrived[string(species(self))] <- evac.nb_arrived[string(species(self))] + 1;
		if current_road != nil {
			do unregister;
			
		}
		do add_evacuation_time;
		do die;
	}
	
	reflex time_to_leave when: not leave and  time > evacuation_time {
		leave <- true;
		leaving_date <- copy(current_date);
		do initialize;
	}
	reflex move_to_target when:leave and (final_target != nil ) {
		do drive;
		if parked {
			if real_speed > 0.0 {
				parked <- false;
				time_stuck <- 0.0;
				do reset_properties;
			}
		} else if time_before_parking > 0.0 {
			if (real_speed = 0.0) and using_linked_road  and (moving_agent(leading_vehicle) != nil ) and not dead(leading_vehicle) and not moving_agent(leading_vehicle).using_linked_road and (moving_agent(leading_vehicle).vehicle_length_init >= vehicle_length_init){
				time_stuck <- time_stuck + step;
			}else {
				time_stuck <- 0.0;
			}
			if (time_stuck > time_before_parking ) {
				parked <- true;
				do to_park;
				do force_move(road(current_road).num_lanes - 1,max_acceleration,step);
			}
		}
		if final_target = nil {
			do arrived(evac_pt);
		}
	}
	aspect default {
		if (current_road != nil) {
			point pos <- compute_position();
			draw rectangle(vehicle_length , lane_width * num_lanes_occupied) 
				at: pos color: color rotate: heading;// border: #black depth: 1.0;
			draw triangle(lane_width * num_lanes_occupied ) 
				at: pos color: parked ? #red : color rotate: heading + 90 border: #black;
		}
	}
	aspect demo {
		if (current_road != nil) {
			point pos <- compute_position();
			draw circle(vehicle_length_init  /1.5 ) at: pos color: rgb(color.red, color.green, color.blue, 0.5);
			
			draw rectangle(vehicle_length_init , lane_width * num_lanes_occupied) 
				at: pos color: color rotate: heading;// border: #black depth: 1.0;
			draw triangle(lane_width * num_lanes_occupied ) 
				at: pos color: color rotate: heading + 90 ;//border: #black;depth: 1.5;
		}
	}
	
	point compute_position {
		// Shifts the position of the vehicle perpendicularly to the road,
		// in order to visualize different lanes
		if (current_road != nil) {
			float dist <- (road(current_road).num_lanes - lowest_lane -
				mean(range(num_lanes_occupied - 1)) - 0.5) * lane_width;
			if violating_oneway {
				dist <- -dist;
			}
		 	point shift_pt <- {cos(heading + 90) * dist, sin(heading + 90) * dist};	
		
			return location + shift_pt;
		} else {
			return {0, 0};
		}
	}
	
	
	
}


species car parent: moving_agent schedules:[]{
	float vehicle_length_init <- 3.8#m;
	int num_lanes_occupied <- 2;
	float max_speed <- 160 #km/#h;
	float max_acceleration_init <- rnd(3.0,5.0);	
	float time_headway_init <- gauss(1.25,0.25) min: 0.5;
	float politeness_factor_init <- 0.25 ;
	float acc_bias <- 0.0;
	int linked_lane_limit <- 0;
	float proba_use_linked_road_init <- 0.0;
	
	float proba_respect_priorities_init <- 0.0;
	float acc_gain_threshold_init <- 0.2;
	float min_safety_distance_init <- 0.5;
	
	float max_safe_deceleration <- 4.0;
	float time_before_parking <- #max_float;
	action add_evacuation_time {
		evacuation_time_car << (current_date - leaving_date);	
	}
	
}

species pedestrian parent: moving_agent schedules:[]{
	float vehicle_length_init <- 0.28#m;
	int num_lanes_occupied <- 1;
	float max_speed <- gauss(1.34,0.26) min: 0.5;
	float max_acceleration_init <- rnd(1.1,1.6);
	float safety_distance_coeff_init <- 0.2;
	float time_headway_init <- gauss(0.5,0.1) min: 0.25;
	float politeness_factor_init <- 0.0;
	float max_safe_deceleration <- 2.0;
	float acc_bias <- 0.0;
	float lane_change_cooldown <- 0.0;
	
	
	float proba_respect_priorities_init <- 0.0;
	float acc_gain_threshold_init <- 0.01;
	float min_safety_distance_init <- 0.2;
	
	float time_before_parking <- rnd(5.0, 10.0);
	
	action add_evacuation_time {
		evacuation_time_pedestrian << (current_date - leaving_date);	
	}
	aspect default {
		if (current_road != nil) {
			point pos <- compute_position();
			draw triangle(vehicle_length ) rotate: heading + 90 at: pos color: color  border:  parked ? #red :#black ;//depth: 1.0;
		}
	}
	
	aspect demo {
		if (current_road != nil) {
			point pos <- compute_position();
			draw circle(vehicle_length_init ) at: pos  color: rgb(color.red, color.green, color.blue, 0.5);
			
			draw circle(vehicle_length_init ) 
				at: pos color: color ;// border: #black depth: 1.0;
		}
	}
}


species bicycle parent: moving_agent schedules:[]{
	float vehicle_length_init <- 1.71#m;
	int num_lanes_occupied <- 1;
	float max_speed <- gauss(13.48,4.0) #km/#h min: 5 #km/#h;
	float max_acceleration_init <- rnd(0.8,1.2);
	float safety_distance_coeff_init <- 0.2;
	float time_headway_init <- gauss(1.0,0.25) min: 0.25;
	float politeness_factor_init <- 0.05;
	float max_safe_deceleration <- 2.0;
	float acc_bias <- 0.0;
	float lane_change_cooldown <- 0.0;
	
	
	float proba_respect_priorities_init <- 0.0;
	float acc_gain_threshold_init <- 0.05;
	float min_safety_distance_init <- 0.2;
	
	
	float time_before_parking <- rnd(10.0, 20.0);
	action add_evacuation_time {
		evacuation_time_bicycle << (current_date - leaving_date);	
	}
}


species motorbike parent: moving_agent schedules:[]{

	float vehicle_length_init <- 1.9#m;
	int num_lanes_occupied <- 1;
	float max_speed <-70 #km/#h ;
	float max_acceleration_init <- rnd(2.8,5.0);
	float safety_distance_coeff_init <- 0.2;
	float time_headway_init <- gauss(1.09,0.5) min: 0.25;
	float politeness_factor_init <- 0.1;
	float max_safe_deceleration <- 3.0;
	float acc_bias <- 0.0;
	float lane_change_cooldown <- 0.0;
	
	
	float proba_respect_priorities_init <- 0.0;
	float acc_gain_threshold_init <- 0.1;
	float min_safety_distance_init <- 0.2;
	
	
	float time_before_parking <-  rnd(10.0, 30.0);
	action add_evacuation_time {
		evacuation_time_moto << (current_date - leaving_date);	
	}
}

experiment debug type: gui {
	
	action _init_ {
		create simulation with: (alpha:1.0, beta:1.0, coeff_change_path:0.01, tj_threshold:0.75, save_results:false);
	}
	output {
		display map type: opengl{
			species road;
			species intersection;
			species evacuation_point transparency: 0.3  refresh: false;
			species car ;
			species motorbike ;	
			species bicycle ;	
			species pedestrian ;
		}
	}
}



experiment xp_headless_stochasticity type: gui  {
	parameter alpha var: alpha;
	parameter beta var: beta;
	parameter coeff_change_path var: coeff_change_path;
	parameter tj_threshold var: tj_threshold;
	parameter save_results var: save_results;
	parameter folder_results var: folder_results;
	
}

experiment xp_headless_road_network type: gui  {
	parameter alpha var: alpha;
	parameter beta var: beta;
	parameter coeff_change_path var: coeff_change_path;
	parameter tj_threshold var: tj_threshold;
	parameter save_results var: save_results;
	parameter folder_results var: folder_results;
	parameter change_road_lane_perimeters var:change_road_lane_perimeters;
	
}

experiment xp_headless_alpha_beta type: gui  {
	parameter alpha var: alpha;
	parameter beta var: beta;
	parameter coeff_change_path var: coeff_change_path;
	parameter tj_threshold var: tj_threshold;
	parameter save_results var: save_results;
	parameter folder_results var: folder_results;
	
}


experiment xp_headless_change_path type: gui  {
	parameter coeff_change_path var: coeff_change_path;
	parameter tj_threshold var: tj_threshold;
	parameter alpha var: alpha;
	parameter beta var: beta;
	parameter save_results var: save_results;
	parameter folder_results var: folder_results;
	
}



experiment demo_image type: gui {
	output {
		display map type: opengl{
			image image_file("../includes/satellite.png") refresh: false ;
			
			image image_file("../includes/background_1.png") refresh: false  ;
			image image_file("../includes/background_2.png") refresh: false  ;
			image image_file("../includes/background_3.png") refresh: false ;
			image image_file("../includes/background_4.png") refresh: false ;
			image image_file("../includes/background_5.png") refresh: false ;
			image image_file("../includes/background_6.png") refresh: false;
			species evacuation_point transparency: 0.3  refresh: false;
			species car ;
			species bicycle ;	
			
			species motorbike ;	
			species pedestrian ;
		}
	}
}



experiment xp_optimise_zone  type: batch until: already_save repeat: 25  {
	parameter z1 var: z1 min:0.0 max:1.0 step: 0.1 <- 0.0;
	parameter z2 var: z2 min:0.0 max:1.0 step: 0.1 <- 0.1;
	parameter z3 var: z3 min:0.0 max:1.0 step: 0.1 <- 0.2;
	parameter z4 var: z4 min:0.0 max:1.0 step: 0.1 <- 0.3;
	parameter z5 var: z5 min:0.0 max:1.0 step: 0.1 <- 0.4;
	parameter z6 var: z6 min:0.0 max:1.0 step: 0.1 <- 0.5;
	parameter z7 var: z7 min:0.0 max:1.0 step: 0.1 <- 0.6;
	parameter z8 var: z8 min:0.0 max:1.0 step: 0.1 <- 0.7;
	parameter z9 var: z9 min:0.0 max:1.0 step: 0.1 <- 0.8;
	parameter z10 var: z10 min:0.0 max:1.0 step: 0.1 <- 0.9;
	
	parameter i1 var: i1 min:0 max:5 step:1 <- 0;
	parameter i2 var: i2 min:0 max:5 step: 1 <- 1;
	parameter i3 var: i3 min:0 max:5 step: 1 <- 2;
	parameter i4 var: i4 min:0 max:5 step: 1 <- 3;
	parameter i5 var: i5 min:0 max:5 step: 1 <- 4;
	parameter i6 var: i6 min:0 max:5 step: 1 <- 5;
	parameter i7 var: i7 min:0 max:5 step: 1 <- 1;
	parameter i8 var: i8 min:0 max:5 step: 1 <- 2;
	parameter i9 var: i9 min:0 max:5 step: 1 <- 3;
	parameter i10 var: i10 min:0 max:5 step: 1 <- 4;
	 
	parameter save_results var:save_results <- true among: [true];
	parameter scenario var:scenario <- "urban_blocks" among: ["urban_blocks"];
	parameter  folder_results var:  folder_results <- "urban_blocks" among: ["urban_blocks"]; 
	
	method genetic pop_dim: 10 crossover_prob: 0.7 mutation_prob: 0.1 improve_sol: true stochastic_sel: false
	nb_prelim_gen: 1 max_gen: 100  minimize: time  ;
	
	init {
		gama.pref_parallel_simulations_all <- true;
		gama.pref_parallel_simulations <- true;
		gama.pref_parallel_threads <- 24;
		
	}
}
