/**
* Name: finalprojectv1
* Author: Max Schneeberger (2025)
*/

model finalModel

// GLOBAL SECTION
// --------------

global torus: false {
	// loading geospatial files (data source: self generated in ArcGIS Pro)
	file file_gate_middlepoint <- file("../includes/final_project/gate_middlepoint_gama/gate_middlepoint_gama.shp");
	file file_gate_area <- file("../includes/final_project/gatearea_gama/gatearea_gama.shp");
	file file_meadow <- file("../includes/final_project/erased_meadow_gama/erased_meadow_gama.shp");
	file file_sheep_start_area <- file("../includes/final_project/sheep_startingpoint_gama/sheep_startingpoint_gama.shp");
	file file_dog_start_area <- file("../includes/final_project/dog_startingpoint_gama/dog_startingpoint_gama.shp");
	
	// top down defined geometries
	geometry geom_meadow <- geometry(file_meadow);
	geometry geom_sheep_start_area <- geometry(file_sheep_start_area);
	geometry geom_gate_area <- geometry(file_gate_area);
	geometry geom_dog_start_area <- geometry(file_dog_start_area);
	point geom_gate_middlepoint <- geometry(file_gate_middlepoint);
	geometry shape <- envelope(file_meadow);
	
	// calculated geometries
	geometry big_helping_circle <- circle(global_patrol_radius, geom_gate_middlepoint);
	geometry small_helping_circle <- circle(global_patrol_radius - 5, geom_gate_middlepoint);
	geometry calc_geom_dog_start_area <- (big_helping_circle - small_helping_circle) intersection(geom_meadow);

	//  sheep parameters
	int number_of_sheep <- 30 min: 3 max: 60; 	
	float min_separation <- 3.0  min: 0.1  max: 10.0 ;
	int max_separate_turn <- 5 min: 0 max: 20;
	int max_cohere_turn <- 5 min: 0 max: 20;
	int max_align_turn <- 8 min: 0 max: 20;
	float vision <- 30.0  min: 0.0  max: 70.0;
	
	// dog parameters
	int number_of_dogs <- 1 min: 1 max: 2;
	float global_patrol_radius <- 125.0;
	
	// sensing parameters
	list<sheep> sheep_in_meadow;
	point meadow_sheep_centroid;
	point global_sheep_centroid;
	
	// stopping boolean
	bool all_sheep_inside_gate;
			
	// initialise model
	init {
		// create and distribute sheep
		create sheep number:number_of_sheep {location <- any_location_in(geom_sheep_start_area);}
		// create and distribute dogs
		create dog number: number_of_dogs {location <- any_location_in(calc_geom_dog_start_area);}
	}
	
	// evaluating stopping condition
	reflex stop_condition {
		all_sheep_inside_gate <- cycle > 10 and length(sheep_in_meadow) = 1;
	}
	
	// evaluationg sheep centroid
	reflex update_sheep_centroid {
		sheep_in_meadow <- sheep where (not (each intersects geom_gate_area));
		meadow_sheep_centroid <- geometry(sheep_in_meadow).centroid;
		global_sheep_centroid <- geometry(sheep).centroid;
	}	
} 
	

// SPECIES SECTION
// ---------------

// DOG SPECIES
species dog skills: [moving] {
	// general dog attributes
	float size <- 2.0#m;
	rgb color <- #black;
	float speed <- 3.5#m;
	
	// herding attributes
	float local_patrol_radius <- global_patrol_radius;
	geometry patrol_arc;
	geometry bigger_circle;
	geometry smaller_circle;
	point target_point;
	
	// evaluating patrol arc
	reflex update_patrol_arc {
		bigger_circle <- circle(local_patrol_radius, geom_gate_middlepoint);
		smaller_circle <- circle(local_patrol_radius - 5.0, geom_gate_middlepoint);
		patrol_arc <- bigger_circle - smaller_circle;

		if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 2.5 {
			local_patrol_radius <- 20.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 5.0 {
			local_patrol_radius <- 30.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 10.0 {
			local_patrol_radius <- 40.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 15.0 {
			local_patrol_radius <- 50.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 30.0 {
			local_patrol_radius <- 60.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 45.0 {
			local_patrol_radius <- 70.0;
		}
		else if distance_to(meadow_sheep_centroid, geom_gate_middlepoint) <= 60.0 {
			local_patrol_radius <- 80.0;
		}
		else if distance_to(global_sheep_centroid, geom_gate_middlepoint) <= 75.0 {
			local_patrol_radius <- 90.0;
		}
	}
	
	// herding behavior
	reflex herd {
		// 1 dog scenario
		if length(dog) = 1 {
			float tx <- local_patrol_radius * cos(geom_gate_middlepoint towards meadow_sheep_centroid);
			float ty <- local_patrol_radius * sin(geom_gate_middlepoint towards meadow_sheep_centroid);
			point txy <- {tx,ty};
			target_point <- geom_gate_middlepoint + txy;
			
			// movement to target point
			if target_point intersects(geom_meadow) {
				do goto target: target_point;
			}
		// 2 dogs scenario
		}
		else if length(dog) = 2 {
			if index = 0 {
				float tx <- local_patrol_radius * cos(geom_gate_middlepoint towards meadow_sheep_centroid - 10);
				float ty <- local_patrol_radius * sin(geom_gate_middlepoint towards meadow_sheep_centroid - 10);
				point txy <- {tx,ty};
				target_point <- geom_gate_middlepoint + txy;
				
				// movement to target point
				if target_point intersects(geom_meadow) {
					do goto target: target_point;
				}
			}
			else {
				float tx <- local_patrol_radius * cos(geom_gate_middlepoint towards meadow_sheep_centroid + 10);
				float ty <- local_patrol_radius * sin(geom_gate_middlepoint towards meadow_sheep_centroid + 10);
				point txy <- {tx,ty};
				target_point <- geom_gate_middlepoint + txy;
				
				// movement to target point
				if target_point intersects(geom_meadow) {
					do goto target: target_point;
				}
			}
		}
	}
	
	// main dog aspect
	aspect default {
		draw circle(size) color: color;
	}

	// patrol arc aspec
	aspect visible_patrol_arc {
		draw patrol_arc color: #violet;
	}

	// aspects for testing
	aspect asp_dog_test {
		draw target_point color: #green;
		draw meadow_sheep_centroid;
	}
}

//  SHEEP SPECIES
species sheep skills: [moving] {
	// SHEEP ATTRIBUTES
	float size <- 2.0#m;
	rgb colour <- #blue;
	float speed <- 0.5#m;
	float perception_distance <- 35#m;
	geometry perception_area <- circle(perception_distance) intersection cone(heading - 45, heading + 45);

	// FLOCKING ATTRIBUTES
    list<sheep> flockmates; 	    
    sheep nearest_neighbour;	
    float avg_head;
    float avg_twds_mates;
    
    // REFLEXES
    // updating perception_area
    reflex update_perception_area{
		perception_area <- circle(perception_distance) intersection cone(heading - 45, heading + 45);
	}
    
    // behavior when dog in perception area
    reflex escape when: one_of(dog) intersects(perception_area) and (not (self intersects(geom_gate_area))) {
		float escape_heading <- (dog intersecting(perception_area)) with_min_of(self) towards geom_gate_middlepoint;
		do move speed: 1.0#m heading: escape_heading; 
    }
	
	// flocking movement
	reflex flock when: length(dog intersecting(perception_area)) = 0 and (not (self intersects(geom_gate_area))) {
		// in case all flocking parameters are zero wander randomly  	
		if (max_separate_turn = 0 and max_cohere_turn = 0 and max_align_turn = 0) {
			do wander amplitude: 120.0;
		}
		// otherwise compute the heading for the next timestep in accordance to my flockmates
		else {
			// search for flockmates
			do find_flockmates;
			// turn my heading to flock, if there are other agents in vision 
			if (not empty (flockmates)) {
				do find_nearest_neighbour;
				if (distance_to (self, nearest_neighbour) < min_separation) {
					do separate;
				}
				else {
					do align;
					do cohere;
				}
				// move forward in the new direction
				do move;
			}
			// wander randomly, if there are no other agents in vision
			else {
				do wander amplitude: 30.0;
			}
		}			
    }
	
	// ACTIONS
	// flockmates are defined spatially, within a buffer of vision
	action find_flockmates {
        flockmates <- ((sheep overlapping (circle(vision))) - self);
	}
	
	// find nearest neighbour
	action find_nearest_neighbour {
        nearest_neighbour <- flockmates with_min_of(distance_to (self.location, each.location)); 
	}		
	
    // separate from the nearest neighbour of flockmates
    action separate {
    	do turn_away (nearest_neighbour towards self, max_separate_turn);
    }

    // reflex to align the boid with the other boids in the range
    action align  {
    	avg_head <- avg_mate_heading();
        do turn_towards (avg_head, max_align_turn);
    }

    // reflex to apply the cohesion of the boids group in the range of the agent
    action cohere {
		avg_twds_mates <- avg_heading_towards_mates();
		do turn_towards (avg_twds_mates, max_cohere_turn); 
    }
    
    // compute the mean vector of headings of my flockmates
    float avg_mate_heading {
		list<sheep> flockmates_insideShape <- flockmates where (each.destination != nil);
		float x_component <- sum (flockmates_insideShape collect (each.destination.x - each.location.x));
		float y_component <- sum (flockmates_insideShape collect (each.destination.y - each.location.y));
		// if the flockmates vector is null, return my own, current heading
		if (x_component = 0 and y_component = 0) {
			return heading;
		}
		// else compute average heading of vector  		
		else {
			// note: 0-heading direction in GAMA is east instead of north! -> thus +90
			return -1 * atan2 (x_component, y_component) + 90;
		}	
    }  

    // compute the mean direction from me towards flockmates	    
    float avg_heading_towards_mates {
    	float x_component <- mean (flockmates collect (cos (towards(self.location, each.location))));
    	float y_component <- mean (flockmates collect (sin (towards(self.location, each.location))));
    	// if the flockmates vector is null, return my own, current heading
    	if (x_component = 0 and y_component = 0) {
    		return heading;
    	}
		// else compute average direction towards flockmates
    	else {
    		// note: 0-heading direction in GAMA is east instead of north! -> thus +90
    		return -1 * atan2 (x_component, y_component) + 90;	
    	}
    } 	    
    
    // cohere
    action turn_towards (float new_heading, int max_turn) {
		float subtract_headings <- new_heading - heading;
		if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
		if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
    	do turn_at_most ((subtract_headings), max_turn);
    }

	// separate
    action turn_away (float new_heading, int max_turn) {
		float subtract_headings <- heading - new_heading;
		if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
		if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
    	do turn_at_most ((-1 * subtract_headings), max_turn);
    }
    
    // align
    action turn_at_most (float turn, int max_turn) {
    	if abs (turn) > max_turn {
    		if turn > 0 {
    			//right turn
    			heading <- heading + max_turn;
    		}
    		else {
    			//left turn
    			heading <- heading - max_turn;
    		}
    	}
    	else {
    		heading <- heading + turn;
    	} 
    }
    
    // ASPECTS
	// default arrow
	aspect arrow {
 		draw line([location, {location.x - size * cos(heading), location.y - size * sin(heading)}]) begin_arrow: 1 color: colour;
	}
	
	aspect perception_area {
		draw perception_area color: #pink;
	}
}

// GRIDS	
grid grass cell_width: 1#m cell_height: 1#m {
	// booleans to evaluate position
	bool is_sheep_start_area <- self intersects(geom_sheep_start_area);
	bool is_meadow <- self intersects(geom_meadow);
	bool is_gate_area <- self intersects(geom_gate_area);
	
	// reflexes to visualize different geometries
	reflex show_sheep_start_area when: is_sheep_start_area {
		color <- #green;
	}
	reflex show_meadow when: is_meadow {
		color <- #lightgreen;
	}
	reflex show_gate_area when: is_gate_area {
		color <- #red;
	}
}
  

// SIMULATION SETTINGS
// -------------------
experiment finalModel_batch type: batch repeat: 5 keep_seed: false until: all_sheep_inside_gate {
 	reflex end_of_runs {
	    ask simulations {
	        save [cycle] to: "../results/cycles.csv" format: "csv" rewrite: false header: true;
	    } 
	}
}

experiment finalModel_gui type: gui {
	// general parameters
	parameter 'Initial number of dogs' var: number_of_dogs;
	parameter 'Initial number of sheep' var: number_of_sheep;
	
	// flocking movement related parameters
	parameter 'Max cohesion turn' var: max_cohere_turn ;
	parameter 'Max alignment turn' var:  max_align_turn; 
	parameter 'Max separation turn' var: max_separate_turn;
	parameter 'Minimal Distance'  var: min_separation;
	parameter 'Vision' var: vision;
	
	output {	
		// map
		display map  {
			grid grass;
			species sheep aspect: arrow;
			species dog aspect: default;
		}
	}
}

