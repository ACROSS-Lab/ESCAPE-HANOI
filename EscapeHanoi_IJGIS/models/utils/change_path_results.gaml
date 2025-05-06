/**
* Name: changepathresult
* Author: Patrick Taillandier
*/
model changepathresult

global {
	float min_evac_time;
	float max_evac_time;
	
	float min_time_on_road;
	float max_time_on_road;
	
	init {
		map<string,list<int>> correspondance; 
		loop i from: 1 to: 4 {
			float tj_threshold <- i /4.0;
			loop j from: 1 to: 4 {
				float coeff_change_path <- j = 0 ? 0.0 : ((10^j)/ (10^5));
				correspondance[""+coeff_change_path+"-" +tj_threshold ] <- [i-1, j- 1];
			}
		}
	
		
		csv_file f2 <- csv_file("../results/change_path/result_evacuation_time_1.0_0.0.csv",",");
		if (f2 != nil and not empty(f2)) {
			matrix data <- matrix(f2);	
			loop l from: 0 to: data.rows -1 {
				bool people <- true;
				int nb <- 0;
				float val;
				float tt <- float(data[2,l]) / 2.0;
				
				float threshold <- float(data[6,l]);
				float coeff <- float(data[5,l]);
				list<int> vs <- correspondance[""+coeff+"-" +threshold ];
				loop c from: 7 to: data.columns - 1 {
					nb <- nb +1;
					val <- val + float(string(data[c,l]) replace (";",""));
				}
				cell2[vs[0],3 - vs[1]].time_on_road <- cell2[vs[0],3 - vs[1]].time_on_road  + val/nb;
				cell2[vs[0],3 - vs[1]].vals << val/nb;
				cell[vs[0],3 - vs[1]].evacuation_time <- cell[vs[0],3 - vs[1]].evacuation_time  + tt;
				cell[vs[0],3 - vs[1]].vals << tt;
				cell2[vs[0],3 - vs[1]].nb <- cell2[vs[0],3 - vs[1]].nb + 1; 
				cell[vs[0],3 - vs[1]].nb <- cell[vs[0],3 - vs[1]].nb + 1; 
			} 
			ask cell2{
				time_on_road <- time_on_road / nb;
				std_time_on_road <- standard_deviation(vals);
			}
			
			ask cell{
				evacuation_time <- evacuation_time / nb;
				std_evacuation_time <- standard_deviation(vals);
			}
		}
	
		min_evac_time <- cell min_of (each.evacuation_time) ;
		max_evac_time <- cell max_of (each.evacuation_time) ;
		
		

		string table1 <- "\\begin{table}[H]\n\\begin{center}\n";
		table1 <-table1 + "\\begin{tabular}[b]{|l|c|c|c|c|}\n\\hline";
		table1 <- table1 + "\n\\diagbox[width=5em]{$tj_a$}{$k_a$}& 0.1&0.01& 0.001&0.0001\\\\ \n \\hline \n"; 
 		loop i from:0 to:3 {
 			table1 <- table1 + ((i+1) /4.0) ;
 			loop j from:0 to:3 {
 				table1 <- table1 + "&" + round(cell[i,j].evacuation_time) + "(" +  (cell[i,j].std_evacuation_time) with_precision 2 +")"; 
 		
 			}	
 			table1 <- table1 +"\\\\\n \\hline \n";
 		}
 	 table1 <- table1 + "\\ end{tabular}\n\\end{center}\n\\caption{Mean evacuation time (in s) and standard deviation for different values of  $tj_a$ and $k_a$ }
\n\\label{resultChPathEvac}
\n\\end{table}";
 	 
 	 
		write table1;
		
		string table2 <- "\\begin{table}[H]\n\\begin{center}\n";
		
		 table2 <- table2 + "\\begin{tabular}[b]{|l|c|c|c|c|}\n\\hline";
		table2 <- table2 + "\n\\diagbox[width=5em]{$tj_a$}{$k_a$}& 0.1&0.01& 0.001&0.0001\\\\ \n \\hline \n"; 
 		loop i from:0 to:3 {
 			table2 <- table2 + ((i+1) /4.0) ;
 			loop j from:0 to:3 {
 				table2 <- table2 + "&" + round(cell2[i,j].time_on_road) + "(" +  (cell2[i,j].std_time_on_road) with_precision 2 +")"; 
 		
 			}	
 			table2 <- table2 +"\\\\\n \\hline \n";
 		}
  		 table2 <- table2 + "\\ end{tabular}\n\\end{center}\n\\caption{Mean time spent on road (in s) and standard deviation for different values of  $tj_a$ and $k_a$ }
\n\\label{resultChPathTimeSpent}
\n\\end{table}";
		write table2;
	
		
	}
}

grid cell width: 4 height: 4 {
	float evacuation_time;
	list<float> vals;
	float std_evacuation_time;
	int nb;

}

grid cell2 width: 4 height: 4 {
	float time_on_road;	
	list<float> vals;
	float std_time_on_road;
	int nb;
}



experiment main type: gui;
