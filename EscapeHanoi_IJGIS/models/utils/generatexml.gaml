/**
* Name: generatexml
* Author: Patrick Taillandier
*/


model generatexml

global {
	int nb_replication <- 25;
	int nb_replication_stochastivity <- 100;
	list<float> alpha;
	list<float> beta;
	
	list<float> coeff_change_path;
	list<float> tj_threshold;
	
	init {
		save network_impact_string() to: "escape_network_impact.xml" format:"text";
		write "road impact generated";
		save alpha_beta_string() to: "escape_alpha_beta.xml" format:"text";
		write "alpha beta generated";
		save change_path_string() to: "escape_change_path.xml" format:"text";
		write "change_path generated";
		save stochasticity_string() to: "escape_stochasticity.xml" format:"text";
		write "stochasticity generated";
		
	}
	
	
	string network_impact_string {
		string to_write <- "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" + "\n";
			to_write <- to_write + "<Experiment_plan>" + "\n";
			loop i from: 1  to:nb_replication {
				loop v over: [0.0,100.0,500.0,1000.0,5000.0] {
						
					
					to_write <- to_write + "<Simulation id=\"" + i + "\" sourcePath=\"EscapeHanoi_IJGIS/models/evacuation_phuc_xa.gaml\" finalStep=\"25000\" experiment=\"xp_headless_road_network\" seed=\"" + i +"\">";
					to_write <- to_write + "\n<Parameters>" + "\n";
					to_write <- to_write + "<Parameter name=\"alpha\" type=\"FLOAT\" value=\"0.0\" />\n";
					to_write <- to_write + "<Parameter name=\"beta\" type=\"FLOAT\" value=\"0.0\" />\n";
					to_write <- to_write + "<Parameter name=\"tj_threshold\" type=\"FLOAT\" value=\"0.75\" />\n";
					to_write <- to_write + "<Parameter name=\"coeff_change_path\" type=\"FLOAT\" value=\"0.01\" />\n";
					to_write <- to_write + "<Parameter name=\"save_results\" type=\"BOOLEAN\" value=\"true\" />\n";
					to_write <- to_write + "<Parameter name=\"folder_results\" type=\"STRING\" value=\"road_network\" />\n";
					to_write <- to_write + "<Parameter name=\"change_road_lane_perimeters\" type=\"FLOAT\" value=\""+ v+"\" />\n";
							
						
					to_write <- to_write + "</Parameters>" + "\n";
					to_write <- to_write + "<Outputs>" + "\n";
					to_write <- to_write + "</Outputs>" + "\n";
					to_write <- to_write + "</Simulation>" + "\n";
				}
					
			}
		to_write <- to_write + "</Experiment_plan>" + "\n";
		return to_write;
	}
	
	string stochasticity_string {
		string to_write <- "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" + "\n";
			to_write <- to_write + "<Experiment_plan>" + "\n";
			loop i from: 1  to:nb_replication_stochastivity {
				to_write <- to_write + "<Simulation id=\"" + i + "\" sourcePath=\"EscapeHanoi_IJGIS/models/evacuation_phuc_xa.gaml\" finalStep=\"25000\" experiment=\"xp_headless_stochasticity\" seed=\"" + i +"\">";
				to_write <- to_write + "\n<Parameters>" + "\n";
				to_write <- to_write + "<Parameter name=\"alpha\" type=\"FLOAT\" value=\"1.0\" />\n";
				to_write <- to_write + "<Parameter name=\"beta\" type=\"FLOAT\" value=\"1.0\" />\n";
				to_write <- to_write + "<Parameter name=\"tj_threshold\" type=\"FLOAT\" value=\"0.75\" />\n";
				to_write <- to_write + "<Parameter name=\"coeff_change_path\" type=\"FLOAT\" value=\"0.01\" />\n";
				to_write <- to_write + "<Parameter name=\"save_results\" type=\"BOOLEAN\" value=\"true\" />\n";
				to_write <- to_write + "<Parameter name=\"folder_results\" type=\"STRING\" value=\"stochasticity\" />\n";
					
				to_write <- to_write + "</Parameters>" + "\n";
				to_write <- to_write + "<Outputs>" + "\n";
				to_write <- to_write + "</Outputs>" + "\n";
				to_write <- to_write + "</Simulation>" + "\n";
			
					
			}
		to_write <- to_write + "</Experiment_plan>" + "\n";
		return to_write;
	}
	
	string alpha_beta_string {
		
			loop i from: 0 to: 5 {
				alpha << i/5.0;
				beta <<i/5.0;
			}
			string to_write <- "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" + "\n";
			to_write <- to_write + "<Experiment_plan>" + "\n";
			loop i from: 1  to:nb_replication {
				loop a over: alpha {
					loop b over: beta {
						to_write <- to_write + "<Simulation id=\"" + i + "\" sourcePath=\"EscapeHanoi_IJGIS/models/evacuation_phuc_xa.gaml\" finalStep=\"25000\" experiment=\"xp_headless_alpha_beta\" seed=\"" + i +"\">";
						to_write <- to_write + "\n<Parameters>" + "\n";
						to_write <- to_write + "<Parameter name=\"alpha\" type=\"FLOAT\" value=\""+ a+"\" />\n";
						to_write <- to_write + "<Parameter name=\"beta\" type=\"FLOAT\" value=\""+ b+"\" />\n";
						to_write <- to_write + "<Parameter name=\"tj_threshold\" type=\"FLOAT\" value=\"0.75\" />\n";
						to_write <- to_write + "<Parameter name=\"coeff_change_path\" type=\"FLOAT\" value=\"0.01\" />\n";
						to_write <- to_write + "<Parameter name=\"save_results\" type=\"BOOLEAN\" value=\"true\" />\n";
						to_write <- to_write + "<Parameter name=\"folder_results\" type=\"STRING\" value=\"alpha_beta\" />\n";
					
						to_write <- to_write + "</Parameters>" + "\n";
						to_write <- to_write + "<Outputs>" + "\n";
						to_write <- to_write + "</Outputs>" + "\n";
						
						to_write <- to_write + "</Simulation>" + "\n";
						
					}
				}
					
			}
		to_write <- to_write + "</Experiment_plan>" + "\n";
		return to_write;
	}
	
	
	string change_path_string {
		
			loop i from: 1 to: 4 {
				tj_threshold << i /4.0;
				coeff_change_path << i = 0 ? 0.0 : ((10^i)/ (10^5));
			}
			string to_write <- "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" + "\n";
			to_write <- to_write + "<Experiment_plan>" + "\n";
			loop i from: 1  to:nb_replication {
				loop a over: tj_threshold {
					loop b over: coeff_change_path {
			
						to_write <- to_write + "<Simulation id=\"" + i + "\" sourcePath=\"EscapeHanoi_IJGIS/models/evacuation_phuc_xa.gaml\" finalStep=\"25000\" experiment=\"xp_headless_change_path\" seed=\"" + i +"\">";
						to_write <- to_write + "\n<Parameters>" + "\n";
						to_write <- to_write + "<Parameter name=\"alpha\" type=\"FLOAT\" value=\"1.0\" />\n";
						to_write <- to_write + "<Parameter name=\"beta\" type=\"FLOAT\" value=\"0.0\" />\n";
						to_write <- to_write + "<Parameter name=\"tj_threshold\" type=\"FLOAT\" value=\""+ a+"\" />\n";
						to_write <- to_write + "<Parameter name=\"coeff_change_path\" type=\"FLOAT\" value=\""+ b+"\" />\n";
						to_write <- to_write + "<Parameter name=\"save_results\" type=\"BOOLEAN\" value=\"true\" />\n";
						to_write <- to_write + "<Parameter name=\"folder_results\" type=\"STRING\" value=\"change_path\" />\n";
					
						to_write <- to_write + "</Parameters>" + "\n";
						to_write <- to_write + "<Outputs>" + "\n";
						to_write <- to_write + "</Outputs>" + "\n";
						
						to_write <- to_write + "</Simulation>" + "\n";
						
					}
				}	
			}
		to_write <- to_write + "</Experiment_plan>" + "\n";
		return to_write;
	}
}


experiment generate_xml_files  {
	action _init_ {
		create simulation with: [nb_replication::25, nb_replication_stochastivity::100];
	}	
}
