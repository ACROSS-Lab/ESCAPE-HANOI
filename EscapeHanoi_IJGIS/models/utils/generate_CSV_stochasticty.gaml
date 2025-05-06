/**
* Name: generateCSVstochasticty
* Author: Patrick Taillandier
*/

model generateCSVstochasticty

global {
	
	

	init {
		save ("id, average time spent, average time spent cars, average time spent motorbikes, average time spent  bicycles, average time spent  pedestrians") to: "stochasticity_time_spent.csv" format:"text";
		save ("id, evacuation time, num cars, num motorbikes, num bicycles, num pedestrians") to: "stochasticity.csv" format:"text";
		do save_from("../results/stochasticity/headless/result_1.0_1.0.csv","../results/stochasticity/headless/result_evacuation_time_1.0_1.0.csv" );
		do save_from("../results/stochasticity/result_1.0_1.0.csv","../results/stochasticity/result_evacuation_time_1.0_1.0.csv" );
	}
	
	
	action save_from(string results_csv_file_path, string results_csv_file_time_spent_path) {
		csv_file results_csv_file <- csv_file(results_csv_file_path,",", string);
		csv_file results_csv_file_time_spent <- csv_file(results_csv_file_time_spent_path,",", string);
		
		map<string, int> vals;
		map<string, int> vals_cars;
		map<string, int> vals_motos;
		map<string, int> vals_bicycles;
		map<string, int> vals_pedestrians;
		
		list<string> ids;
		
		
		matrix data <- matrix(results_csv_file_time_spent);
		int v <- -1;
		loop l from: 0 to: data.rows -1 {
			string id <- string(data[0,l]);
			ids << id;
			int cy <- int(data[2,l]);
			int index_ <- 0;
			list<list<float>> vals_times <- [[],[],[],[]];
			loop i from: 7 to: data.columns - 1 {
				string vv <- string(data[i,l]);
				if (vv != nil and vv != "") {
					if (";" in vv) {
						index_ <- index_ + 1;
						vv <- vv replace (";","");
					}
					if (index_ < 4)  {
						vals_times[index_]<< float(vv) / 2.0;
					} else {
						write sample(vv);
					}
					
				}
				
			}
			save (id + "," + mean(vals_times accumulate(each)) + "," + mean(vals_times[3])+ "," + mean(vals_times[2])+ "," + mean(vals_times[1]) +","+ mean(vals_times[0])) to: "stochasticity_time_spent.csv" rewrite: false format:"text";		
		}
		
		data <- matrix(results_csv_file);
		v <- -1;
		loop l from: 0 to: data.rows -1 {
			string id <- string(data[0,l]);
			int cy <- int(data[2,l]);
			int car <- int(data[7,l]);
			int moto <- int(data[8,l]);
			int bicycle <- int(data[9,l]);
			int pedestrian <- int(data[10,l]);
			if id in ids {
				save id +"," + cy +"," + car +"," + moto+"," + bicycle+"," +pedestrian to:"stochasticity_clean.csv" format:"text" rewrite: false;
			}
			if (car + moto + bicycle + pedestrian) > 0 {
				if not (id in vals) or (vals[id] < cy){
					vals[id] <- cy;
				} 
				if  not (id in vals_cars.keys) {
					vals_cars[id] <- car;
				} else {
					vals_cars[id] <- vals_cars[id] + car ;
				}
				if  not (id in vals_motos.keys) {
					vals_motos[id] <- moto;
				} else {
					vals_motos[id] <- vals_motos[id] + moto ;
				}
				
				if  not (id in vals_bicycles.keys) {
					vals_bicycles[id] <- bicycle;
				}else {
					vals_bicycles[id] <- vals_bicycles[id] + bicycle ;
				}
				if  not (id in vals_pedestrians.keys) {
					vals_pedestrians[id] <- pedestrian;
				}else {
					vals_pedestrians[id] <- vals_pedestrians[id] + pedestrian ;
				}
			}
			
		}
		loop id over: ids {
			save (id + "," + (vals[id] / 2)+"," + vals_cars[id] +  "," + vals_motos[id] + "," +vals_pedestrians[id] +","+ vals_bicycles[id]) to: "stochasticity.csv" rewrite: false format:"text";
		}
		
		
		
	}
	/** Insert the global definitions, variables and actions here */
}

experiment generateCSVstochasticty type: gui;