/**
* Name: roadnetworkresults
* Author: Patrick Taillandier
*/

model roadnetworkresults

global {
	float min_evac_time;
	float max_evac_time;
	
	float min_time_on_road;
	float max_time_on_road;
	
	
	init {
		
		csv_file f2 <- csv_file("../results/road_network/result_evacuation_time_0.0_0.0.csv",",");
		map<float,list<float>> time_on_roads;
		map<float,list<float>> evac_time;
		if (f2 != nil and not empty(f2)) {
			matrix data <- matrix(f2);	
			loop l from: 0 to: data.rows -1 {
				
				bool people <- true;
				int nb <- 0;
				float val;
				float tt <- float(data[2,l]) / 2.0;
				
				float road_length <- float(data[7,l]);
				loop c from:8  to: data.columns - 1 {
					nb <- nb +1;
					val <- val + float(string(data[c,l]) replace (";",""));
				}
				list<float> val_evac <- (road_length in evac_time.keys) ?evac_time[road_length] : list<float>([])  ;
				list<float> val_spent <- (road_length in time_on_roads.keys) ?time_on_roads[road_length] : list<float>([])  ;
				
				val_spent << val/nb;
				val_evac << tt;
				time_on_roads[road_length] <- val_spent;
				evac_time[road_length] <- val_evac;
			} 
			
		}
	
		string table1 <- "\\begin{table}[H]\n\\begin{center}\n";
		table1 <-table1 + "\\begin{tabular}[b]{|l|c|c|}\n\\hline";
		table1 <- table1 + "\nroad distance& evacuation time &Time spent on te roads\\\\ \n \\hline \n"; 
 		loop i over: evac_time.keys sort_by each {
 			table1 <- table1  + round(i) + "&" + round(mean(evac_time[i])) + "(" +  round(standard_deviation(evac_time[i]))+") & " +  round(mean(time_on_roads[i])) + "(" +  round(standard_deviation(time_on_roads[i]))+")"   ; 
 		
 				
 			table1 <- table1 +"\\\\\n \\hline \n";
 		}
 	 table1 <- table1 + "\\ end{tabular}\n\\end{center}\n\\caption{Mean evacuation time (in s) and standard deviation for different values of  $tj_a$ and $k_a$ }
\n\\label{resultChPathEvac}
\n\\end{table}";
 	 
 	 
		write table1;
		
		
		
	}
}


experiment main type: gui ;