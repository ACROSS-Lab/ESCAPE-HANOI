/**
* Name: paretoFront
* Author: Patrick Taillandier
*/

model paretoFront

global {
	
	float max_time;
	float max_spent;
	float min_time;
	float min_spent;
	
	init {
		map<list<float>,list<float>> results_time;
	
		map<list<float>,list<float>> results_spent;
		do load_file(csv_file("../results/Optimisation/pc/zone_time_fitness/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/urban_blocks/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/pc/urban_blocks/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/PC2/urban_blocks/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/PC2/zone_time_fitness/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/PC3/result_evacuation_time_zone.csv",","), results_time,results_spent);
		do load_file( csv_file("../results/Optimisation/zone_time_improved_2/result_evacuation_time_zone.csv",","), results_time,results_spent);
	
		
		write sample(results_time);
		
		
		map<list<float>,float> results_t;
		
		map<list<float>,float> results_std_t;
		loop r over: results_time.keys {
			results_t[r] <- mean(results_time[r]);
			results_std_t[r]<- standard_deviation(results_time[r]);
			
		}
		map<list<float>,float> results_s;
		map<list<float>,float> results_std_s;
		
		loop r over: results_spent.keys {
			results_s[r] <- mean(results_spent[r]);
			results_std_s[r]<- standard_deviation(results_spent[r]);
		}
		max_time <- max(results_t.values);
		max_spent <- max(results_s.values);
		min_time <- min(results_t.values);
		min_spent <- min(results_s.values);
		list<list<float>> pareto_front;
	
		loop r over: results_t.keys {
			bool ok <- true;
			float tv <- results_t[r] ;
			float sv <- results_s[r] ;
			loop s over: results_t.keys {
				if (r != s) {
					if (results_t[s] <= tv) and (results_s[s] <= sv) {
						ok <- false;
						break;
					}
				}
 			}
 			if ok {
 				pareto_front << r;
 			}
 			
		}
		loop p over: results_t.keys {
			create solution with: (vals:p, time_evac:results_t[p], time_spent: results_s[p], pareto: p in pareto_front, std_time_evac: results_std_t[p],std_time_spent: results_std_s[p]);
		}
		
		solution best_sol <- solution with_min_of (each.time_evac);
		ask best_sol {
			string str <- "[";
			loop i from: 0 to: length(vals) - 1 {
				if (i < 10) {
					write "float z" + (i+1) +" <- " + vals[i] +";";
					str <-str + "z" +  (i+1) +"::" + vals[i] +",";
				} else {
					write "int i" + (i - 10 +1) +" <- " + round(vals[i]) +";";
					str <-str + "i" +  (i+1) +"::" + round(vals[i]) +",";
				}
				
			}
			 str <- str + "]";
			write str;
			write "best " + sample(time_evac) +" " + sample(std_time_evac) +" " +  sample(time_spent) +" " + sample(std_time_spent);
		}
		
				
	}
	
	action load_file(file f2, map<list<float>,list<float>> results_time, 	map<list<float>,list<float>> results_spent) {
		if (f2 != nil and not empty(f2)) {
			matrix data <- matrix(f2);	
			loop l from: 0 to: data.rows -1 {
				bool people <- true;
				int nb <- 0;
				float val;
				list<float> vals;
				float tt <- float(data[2,l]) / 2.0;
					
				
				vals <<  float(data[3,l]) ;
				vals <<  float(data[4,l]) ;
				vals <<  float(data[5,l]) ;
				vals <<  float(data[6,l]) ;
				vals <<  float(data[7,l]) ;
			    vals <<  float(data[8,l]) ;
				vals << float(data[9,l]) ;
				vals << float(data[10,l]) ;
				vals << float(data[11,l]) ;
				vals <<  float(data[12,l]) ;
				vals <<  float(data[13,l]) ;
				vals <<  float(data[14,l]) ;
				vals << float(data[15,l]) ;
				vals <<  float(data[16,l]) ;
				vals <<  float(data[17,l]) ;
				vals <<  float(data[18,l]) ;
				vals <<  float(data[19,l]) ;
				vals <<  float(data[20,l]) ;
				vals << float(data[21,l]) ;
				vals << float(data[22,l]) ;
				loop c from: 25 to: data.columns - 1 {
					if data[c,l] != nil {
						nb <- nb +1;
						val <- val + float(string(data[c,l]) replace (";",""));
					}
					
				}
				val <- val / nb;
				
				if empty(vals where (each > 5)) {
					if not (vals in results_time.keys) {
						results_time[vals] <- [];
						results_spent[vals] <- [];
					}
					results_time[vals] << tt;
					results_spent[vals] << val;
					
				}
				
			} 
			
		}
	}
}

species solution {
	bool pareto <- false;
	list<float> vals;
	float time_evac;
	float std_time_evac;
	float time_spent;
	float std_time_spent;
	
	init {
		location <- {(time_spent - min_spent)/(max_spent - min_spent) * 100, 100 - (time_evac - min_time)/(max_time - min_time)  * 100};
	}
	aspect default {
		draw circle(1.0) color: pareto ? #red :#gray border: #black;
	}
}
 
experiment paretoFront type: gui {
	output {
		display map type:opengl axes: false{
			graphics "axes" {
				draw line([{0, 100},{110, 100}]) color: #black end_arrow: 2;
				draw string("Mean evacuation time (in s)") at: {-20, 50} anchor: #center color: #black  font: font("Helvetica", 50 , #bold); 
				draw string("Mean time spent on the road (in s)") at: {55, 105} anchor: #center color: #black  font: font("Helvetica", 50 , #bold); 
				
				draw line([{0, 100},{0, -10}]) color: #black end_arrow: 2;
				draw string(round(min_time)) at: {-8, 100} color: #black  font: font("Helvetica", 50 , #bold); 
				draw string(round(min_spent)) at: {0, 105} color: #black  font: font("Helvetica", 50 , #bold); 
				draw string(round(max_time)) at: {-8, 0} color: #black  font: font("Helvetica", 50 , #bold); 
				draw string(round(max_spent)) at: {100,105 } color: #black  font: font("Helvetica", 50 , #bold); 
			}
			species solution;
		}
	}
}
