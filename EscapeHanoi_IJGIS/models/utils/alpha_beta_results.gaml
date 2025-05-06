/**
* Name: alphabetaresult
* Author: Patrick Taillandier
*/

model alphabetaresult

global {
	float min_evac_time;
	float max_evac_time;
	
	float min_time_on_road;
	float max_time_on_road;
	init {
		loop i from: 0 to: 5 {
			float alpha <- i/5.0;
			loop j from: 0 to: 5 {
				float beta <- j/ 5.0;

				csv_file f2 <- csv_file("../results/alpha_beta/result_evacuation_time_" + alpha+"_" + beta+".csv", ",");
				if (f2 != nil and not empty(f2)) {
					matrix data <- matrix(f2);	
						
					list<float> val_t;
					loop l from: 0 to: data.rows -1 {
						val_t << float(data[2,l]);
						bool people <- true;
						int nb <- 0;
						float val;
						
						
						loop c from: 8 to: data.columns - 1 {
							nb <- nb +1;
									val <- val + float(string(data[c,l]) replace (";",""));
					
						}
						cell2[i,5 - j].vals <<val/nb;
						cell2[i,5 - j].time_on_road <- cell2[i,5 - j].time_on_road  + val/nb;
						
					} 
					cell2[i,5 - j].time_on_road <- cell2[i,5 - j].time_on_road / data.rows;
					cell2[i,5 - j].std_time_on_road <- standard_deviation(cell2[i,5 - j].vals);
					cell[i,5 - j].evacuation_time <- mean(val_t) / 2.0;
					cell[i,5 - j].std_evacuation_time <- standard_deviation(val_t) /2.0;
				}
			}
		}
		
		string table1 <- "\\begin{table}[H]\n\\begin{center}\n";
		table1 <-table1 + "\\begin{tabular}[b]{|l|c|c|c|c|c|c|}\n\\hline";
		table1 <- table1 +  "\n\\diagbox[width=5em]{$\\alpha$}{\\beta$}& 0.0&0.2& 0.4&0.6& 0.8&1.0\\\\ \n \\hline \n"; 
 		loop i from:0 to:5 {
 			table1 <- table1 + ((i) /5.0) ;
 			loop j from:0 to:5 {
 				table1 <- table1 + "&" + round(cell[i,5-j].evacuation_time) + "(" +  round(cell[i,5-j].std_evacuation_time)  +")"; 
 		
 			}	
 			table1 <- table1 +"\\\\\n \\hline \n";
 		}
 	 table1 <- table1 + "\\ end{tabular}\n\\end{center}\n\\caption{Mean evacuation time (in s) and standard deviation for different values of $\\alpha$ and $\\beta$ }
\n\\label{resultChPathEvac}
\n\\end{table}";
		
		write table1;
		
		
			string table2 <- "\\begin{table}[H]\n\\begin{center}\n";
		
		 table2 <- table2 + "\\begin{tabular}[b]{|l|c|c|c|c|c|c|}\n\\hline";
		table2 <- table2 + "\n\\diagbox[width=5em]{$\\alpha$}{\\beta$}& 0.0&0.2& 0.4&0.6& 0.8&1.0\\\\ \n \\hline \n"; 
 		loop i from:0 to:5 {
 			table2 <- table2 + ((i) /5.0) ;
 			loop j from:0 to:5 {
 				table2 <- table2 + "&" + round(cell2[i,5-j].time_on_road) + "(" +  round(cell2[i,5-j].std_time_on_road)+")"; 
 		
 			}	
 			table2 <- table2 +"\\\\\n \\hline \n";
 		}
  		 table2 <- table2 + "\\ end{tabular}\n\\end{center}\n\\caption{Mean time spent on road (in s) and standard deviation for different values of  $\\alpha$ and $\\beta$ }
\n\\label{resultChPathTimeSpent}
\n\\end{table}";
		write table2;
		
		
	}
}

grid cell width: 6 height: 6 {
	float evacuation_time;
	
	list<float> vals;
	float std_evacuation_time;
}

grid cell2 width: 6 height: 6 {
	float time_on_road;	
	
	list<float> vals;
	float std_time_on_road;
}



experiment amin type: gui;