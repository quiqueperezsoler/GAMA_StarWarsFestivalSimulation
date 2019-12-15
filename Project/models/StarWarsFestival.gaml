/***
* Name: Project
* Author: Daniel Conde Ortiz and Enrique Perez Soler
* Description: Star Wars fair
***/

model StarWarsFestival

global {
	
	//Global parameters
	bool logCantine<-true;
	bool logStages<-true;
	
	bool logOTFans<-true;
	bool logPrequelFans<-true;
	bool logDisneySWFans<-true;
	
	bool darthOnOff<-true;
	bool yodaOnOff<-true;
	
	
	//Creation of agents
	init{

		create DarthVader number: 1{
			
		}
		
		create Yoda number: 1{
			
		}
		
		create Cantine number: 1{
			
		}
		
		create Stage number: 3{
			
		}
		
		create OTFan number: 20{
			
		}
		
		create PrequelsFan number: 20{
			
		}
		
		create DisneySWFan number: 20{
			
		}
	}
}

species OTFan skills: [fipa,moving]{

	//Variables
	//Preferences for types
	float OTPref<- rnd(8,10)/10;
	float PreqPref<- rnd(0,5)/10;
	float DisneyPref<- rnd(0,3)/10;
	
	//Current show
	float scoreCurrentShow<-0.0;
	Stage currentShow<-nil;
	
	float happiness<-0.0;
	
	//Variables to interact with others
	float generous<- rnd(10)/10;
	int justBought<-0;
	bool previouslyChecked<-false;
	bool smokes<- flip(0.5);
	
	//Vader and Yoda
	DarthVader vader;
	bool goingWithVader<-false;
	bool movedVader<-false;
	
	Yoda yoda;
	bool goingWithYoda<-false;
	
	//Son
	DisneySWFan child<-nil;
	
	//Related to eating
	int hunger<- rnd(200,250);
	bool needToEat<- false;
	point cantineLocation;
	
	//Related to moving and surrounding
	point targetPoint<- nil;
	float maxDistancePoint<-7.0;
	float maxDistanceRadius<-10.0;
	bool stopped<-false;

	//Initialization
	init{
		ask Cantine{
			myself.cantineLocation <- self.location;
		}
		
		ask DarthVader{
			myself.vader<-self;
		}
		
		ask Yoda{
			myself.yoda<-self;
		}
	}
	
	
	//Drops 1 hunger point (0.8 probable)
	reflex get_hungry when: hunger > 0{
		if flip(0.8){
			hunger<- hunger - 1;
		}
		
		if hunger = 0{
			targetPoint<-cantineLocation;
			needToEat <- true;
			goingWithVader<-false;
			goingWithYoda<-false;
			
			scoreCurrentShow<-0.0;
			currentShow<-nil;
		}
	}
	
	
	//When in cantine, fills hunger by 10 and leaves when full or too many Disney Fans
	//Also decreases the buying parameter
	reflex eating when: needToEat and location distance_to(cantineLocation) <= maxDistancePoint{
		hunger <- hunger + 10;
		
		if hunger > 200 and flip(0.8){
			needToEat<- false;
			targetPoint<-nil;
			goingWithVader<-false;
			goingWithYoda<-false;
			
			previouslyChecked<-false;	
		}
		 
		//Leaves if too many DisneyFans eating in the same place
		if length(agents_at_distance(maxDistanceRadius) of_species (DisneySWFan) ) > 10 and !previouslyChecked{
			
			if agents_at_distance(maxDistanceRadius) of_species (DisneySWFan) one_matches (each.parent = self){
				
				if logCantine and logOTFans{
					write self.name + ' too much Disney eating here! But my kid is here';
				}
				
				
				previouslyChecked<-true;
			} else{
				if logCantine and logOTFans {
					write self.name + ' too much Disney eating here! I\'m leaving';
				}
				
				needToEat<- false;
				targetPoint<-nil;
				goingWithVader<-false;
				goingWithYoda<-false;			
				
				if hunger < 100{
					hunger<-100;
				}
				
				previouslyChecked<-false;
				justBought<-0;
			}

		}
		
		if justBought > 0{
			justBought<-justBought -1;
		}
		
	}
	
	//Replies to people asking to buy drinks
	reflex replyBuy when: (!empty(cfps)){
		loop c over: cfps{
			message requestFromInitiator <- c;
						
			string tmp<-string(c.contents);
			
			if flip(generous) and justBought < generous*10{
				
				justBought<- justBought+1;
				
				do propose message: requestFromInitiator contents: ['Okay!',true];
			
			}else{
				
				do propose message: requestFromInitiator contents: ['No, sorry',false];
			}
		}
	}
	
	//Reads messages from stages when a new show begins
	reflex read_informs when: !(empty(informs)){
		loop i over: informs{		
			string tmp<- string(i.contents);
			
			//New show
			if species(i.sender) = Stage{		
				float score;
			
				if i.contents[1] = 1{
					score<-OTPref;
				}else if i.contents[1] = 2{
					score<-PreqPref;
				}else{
					score<-DisneyPref;
				}
				
				if score > scoreCurrentShow and !needToEat{
					currentShow<-i.sender;
					targetPoint<-currentShow.location;
					scoreCurrentShow<-score;
					goingWithVader<-false;
					goingWithYoda<-false;
				}
			}
			
			//Darth Vader
			else{
				//Darth Vader appeared
				if length(i.contents) > 1{
					float score<-rnd(7,9)/10;
					
					if score > scoreCurrentShow and !needToEat{
						currentShow<-nil;
						targetPoint<-agent(i.sender).location;
						scoreCurrentShow<-score;	
						goingWithVader<-true;
						goingWithYoda<-false;
					}	
				}
				//Dart Vader scares people
				else if flip(0.5) and !needToEat{
					targetPoint<-{rnd(100),rnd(100)};
					scoreCurrentShow<-0.0;	
					goingWithVader<-false;
				}
			}
		}
	}
	
	//Reads proposals from stages
	reflex read_proposes when: !(empty(proposes)){
		loop p over: proposes{
		
			string tmp<- string(p.contents);

			float score;
			
			if p.contents[1] = 1{
				score<-OTPref;
			}else if p.contents[1] = 2{
				score<-PreqPref;
			}else{
				score<-DisneyPref;
			}
			
			if score > scoreCurrentShow and !needToEat{
				currentShow<-p.sender;
				targetPoint<-currentShow.location;
				scoreCurrentShow<-score;
				stopped<-false;
				goingWithVader<-false;
				goingWithYoda<-false;
			}
		
		}
	}

	//Checks if anyone in the surroundings is smoking and, if so and the child is close, sends them to another place
	reflex check_smoking when: currentShow != nil and stopped and self.child != nil and agents_at_distance(maxDistanceRadius) of_species (OTFan) contains child{
		
		loop otFan over: agents_at_distance(maxDistanceRadius) of_species (OTFan){
			if otFan.smokes {
				if logStages and logOTFans{
					write self.name + ' telling my kid to go to another stage';
				}
				
				do start_conversation (to:: [child], protocol:: 'fipa-request', performative:: 'request', contents:: ['Go to another stage please']);
				break;
			}
		}
	}	
	
	reflex find_child when: currentShow != nil and self.child != nil and stopped and child.stopped and flip(0.001){
				if logStages and logOTFans {
					write self.name + ' I\'m going to look for my kid';
				}
				
				targetPoint<-child.location;
				goingWithVader<-false;
				goingWithYoda<-false;
	}
	
	//Reads agrees from child when they move
	reflex read_agrees when: !(empty(agrees)){
		loop a over: agrees{
			string tmp<- string(a.contents);
		}
	}
	
	reflex followVader when: goingWithVader and vader.moved and !movedVader{
		movedVader<-true;
		targetPoint<-vader.location;
	}
	
	reflex notFollowVader when: goingWithVader and !vader.appeared{
		movedVader<-false;
		goingWithVader<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	reflex chooseYodaRandom when: yodaOnOff and !needToEat and flip(0.005) and !goingWithYoda and !goingWithVader{
		goingWithYoda<-true;
		scoreCurrentShow<-rnd(5,7)/10;
		currentShow<-nil;
		targetPoint<-yoda.location;
	}
	
	reflex followYoda when: goingWithYoda and mod(time,20)=0{
		targetPoint<-yoda.location;
	}
	
	reflex notFollowYoda when: goingWithYoda and flip(0.01){
		goingWithYoda<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	//Chooses where to go next
	reflex choosePlace when: targetPoint = nil{
		
		//0.1 probability to go to a random place
		if flip(0.05){
			targetPoint <- {rnd(100),rnd(100)};
			
		}else if vader.appeared and darthOnOff and flip(0.2){
			goingWithVader<-true;
			targetPoint<-vader.location;
			scoreCurrentShow<-rnd(7,9)/10;
			currentShow<-nil;
		}else if yodaOnOff and flip(0.2){
			goingWithYoda<-true;
			scoreCurrentShow<-rnd(5,7)/10;
			currentShow<-nil;
			targetPoint<-yoda.location;
			
		}else{
			do start_conversation (to:: list(Stage), protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the show?']);
		}
	}
	
	//Goes to selected point and stops if close
	reflex goToDest when: targetPoint != nil{

		if location distance_to(targetPoint) > maxDistancePoint{
			do goto target: targetPoint;
			stopped<-false;
		}else{
			do wander speed: 0.1;
			stopped<-true;
		}
		
	}
	
	aspect default{
		draw sphere(2) at: location color: #blue;
		//draw circle(maxDistanceRadius) at: location color: #black;
		
	}
}


species PrequelsFan skills: [fipa,moving]{
	
	//Variables
	//Preferences for types
	float OTPref<- rnd(7,9)/10;
	float PreqPref<- rnd(7,10)/10;
	float DisneyPref<- rnd(0,5)/10;
	
	//Current show
	float scoreCurrentShow<-0.0;
	Stage currentShow<-nil;
	
	float happiness<-0.0;
	
	//Variables to interact with others
	float noiseResistance<- rnd(5,10)/10;
	bool alreadyAsked<-false;
	int agreesNum<-0;
	
	//Vader and Yoda
	DarthVader vader;
	bool goingWithVader<-false;
	bool movedVader<-false;
	
	Yoda yoda;
	bool goingWithYoda<-false;

	//Related to eating
	int hunger<- rnd(200,250);
	bool needToEat<- false;
	point cantineLocation;

	//Related to moving and surrounding
	point targetPoint<- nil;
	float maxDistancePoint<-6.0;
	float maxDistanceRadius<-10.0;
	bool stopped<-false;

	//Initialization
	init{
		ask Cantine{
			myself.cantineLocation <- self.location;
		}
		
		ask DarthVader{
			myself.vader<-self;
		}
		
		ask Yoda{
			myself.yoda<-self;
		}
	}
	
	//Drops 1 hunger point (0.8 probable)
	reflex get_hungry when: hunger > 0{
		if flip(0.8){
			hunger<- hunger - 1;
		}
		
		if hunger = 0{
			targetPoint<-cantineLocation;
			needToEat <- true;
			goingWithVader<-false;
			goingWithYoda<-false;
			
			scoreCurrentShow<-0.0;
			currentShow<-nil;
		}
	}
	
	
	//When in cantine, fills hunger by 10 and leaves when full
	//Also, asks OTFans for buying drinks
	reflex eating when: needToEat and location distance_to(cantineLocation) <= maxDistancePoint {
		hunger <- hunger + 10;
		
		if hunger > 200 and flip(0.8){
			needToEat<- false;
			targetPoint<-nil;		
			alreadyAsked<-false;	
			goingWithVader<-false;	
			goingWithYoda<-false;
		}
		
		
		if !alreadyAsked and length( agents_at_distance(maxDistanceRadius) of_species (OTFan)) >0{
			//request to buy
			//write self.name + ' asking OTFans if buying a drink';
			do start_conversation (to:: list(agents_at_distance(maxDistanceRadius) of_species (OTFan)), protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['Buy drink?']);
		
			alreadyAsked<-true;
			agreesNum<-0;
		}
	}
	
	//Reads replies proposing to buy or not from OTFans or
	//proposals from stages
	reflex read_proposes when: !(empty(proposes)){
		loop p over: proposes{
			string tmp<- string(p.contents);
			
			if species(p.sender) = Stage{
				float score;
				
				if p.contents[1] = 1{
					score<-OTPref;
				}else if p.contents[1] = 2{
					score<-PreqPref;
				}else{
					score<-DisneyPref;
				}
				
				if score > scoreCurrentShow and !needToEat{
					currentShow<-p.sender;
					targetPoint<-currentShow.location;
					scoreCurrentShow<-score;
					stopped<-false;
					goingWithVader<-false;
					goingWithYoda<-false;
				}
			}else{
				//Agrees
				if bool(p.contents[1]){
					do accept_proposal (message: p, contents: ['Great!']);
					agreesNum<- agreesNum + 1;
					
					//Calls for more
					if agreesNum > length(agents_at_distance(maxDistanceRadius) of_species (PrequelsFan) ){
						if logCantine and logPrequelFans{
							write self.name + ': '+ p.sender +' buys drinks! Calling for more people';						
						}

						do start_conversation (to:: [one_of(list(PrequelsFan) - agents_at_distance(maxDistanceRadius) of_species (PrequelsFan))], protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Someone is buying drinks']);
					}	
				}
				
				//Rejects
				else{
					do reject_proposal (message: p, contents: ['No problem!']);
				}
			
			}
		}
	}
	
	//Reads messages from other PrequelsFans saying that someone is buying drinks
	//or from stages when a new show begins
	reflex read_informs when: !(empty(informs)){
		loop i over: informs{
			string tmp<- string(i.contents);
			
			//Someone is buying drinks
			if species(i.sender) = PrequelsFan{
				
				string tmp <- string(i.contents);
	
				if logCantine and logPrequelFans {
					write self.name + ' going for drinks!';
				}
				
				targetPoint <-cantineLocation;
				goingWithVader<-false;
				goingWithYoda<-false;
			}
			
			//New show
			else if species(i.sender) = Stage{
				float score;
				
				if i.contents[1] = 1{
					score<-OTPref;
				}else if i.contents[1] = 2{
					score<-PreqPref;
				}else{
					score<-DisneyPref;
				}
				
				if score > scoreCurrentShow and !needToEat{
					currentShow<-i.sender;
					targetPoint<-currentShow.location;
					scoreCurrentShow<-score;
					goingWithVader<-false;
					goingWithYoda<-false;
				}
			}
			
			//Darth Vader 
			else{
				//Darth Vader appeared
				if length(i.contents) > 1{
					float score<-rnd(7,9)/10;
					
					if score > scoreCurrentShow and !needToEat{
						currentShow<-nil;
						targetPoint<-agent(i.sender).location;
						scoreCurrentShow<-score;	
						goingWithVader<-true;
						goingWithYoda<-false;
					}	
				}
				//Dart Vader scares people
				else if flip(0.5) and !needToEat{
					targetPoint<-{rnd(100),rnd(100)};
					scoreCurrentShow<-0.0;	
					goingWithVader<-false;
				}
			}
			
		}
	}

	//Checks if surrounding noise is bigger than own resistance and if so, leaves
	reflex check_noise when: currentShow != nil and stopped and length(agents_at_distance(maxDistanceRadius) of_species (DisneySWFan)) > 5{
		list<float> noises<-[];
		loop disneyFan over: agents_at_distance(maxDistanceRadius) of_species (DisneySWFan){
			add disneyFan.noisy to: noises;
		}
		
		//Leaves
		if mean(noises)>noiseResistance{
			if logStages and logPrequelFans {
				write self.name + ': too much noise in this stage, leaving!';
			}
			
			do start_conversation (to:: list(Stage) - currentShow, protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the show?']);
			scoreCurrentShow<-0.0;
		}
	}
	
	reflex followVader when: goingWithVader and vader.moved and !movedVader{
		movedVader<-true;
		targetPoint<-vader.location;

	}
	
	reflex notFollowVader when: goingWithVader and !vader.appeared{
		movedVader<-false;
		goingWithVader<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	
	reflex chooseYodaRandom when: yodaOnOff and !needToEat and flip(0.005) and !goingWithYoda and !goingWithVader{
		goingWithYoda<-true;
		scoreCurrentShow<-rnd(5,7)/10;
		currentShow<-nil;
		targetPoint<-yoda.location;
	}
	
	reflex followYoda when: goingWithYoda and mod(time,20)=0{
		targetPoint<-yoda.location;
	}
	
	reflex notFollowYoda when: goingWithYoda and flip(0.01){
		goingWithYoda<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	//Chooses where to go next
	reflex choosePlace when: targetPoint = nil{
		
		//0.1 probability to go to a random place
		if flip(0.05){
			targetPoint <- {rnd(100),rnd(100)};
			
		}else if vader.appeared and darthOnOff and flip(0.2){
			goingWithVader<-true;
			targetPoint<-vader.location;
			scoreCurrentShow<-rnd(7,9)/10;
			currentShow<-nil;
		}else if yodaOnOff and flip(0.2){
			goingWithYoda<-true;
			scoreCurrentShow<-rnd(5,7)/10;
			currentShow<-nil;
			targetPoint<-yoda.location;
			
		}else{
			do start_conversation (to:: list(Stage), protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the show?']);
		}
	}
	
	//Goes to selected point and stops if close
	reflex goToDest when: targetPoint != nil{
		
		if location distance_to(targetPoint) > maxDistancePoint{
			do goto target: targetPoint;
			stopped<-false;
		}else{
			do wander speed: 0.1;
			stopped<-true;
		}
		
	}

	aspect default{
		draw sphere(2) at: location color: #red;
	}
}

species DisneySWFan skills: [fipa,moving]{

	//Variables
	//Preferences for types
	float OTPref<- rnd(5,8)/10;
	float PreqPref<- rnd(5,10)/10;
	float DisneyPref<- rnd(7,10)/10;
	
	//Current show
	float scoreCurrentShow<-0.0;
	Stage currentShow<-nil;
	
	float happiness<-0.0;
	
	//Variables to interact with others
	float noisy<- rnd(10)/10;
	OTFan parent<- nil;
	bool previouslyChecked<-false;
	
	//Vader and Yoda
	DarthVader vader;
	bool goingWithVader<-false;
	bool movedVader<-false;
	
	Yoda yoda;
	bool goingWithYoda<-false;
	
	//Related to eating
	int hunger<- rnd(200,250);
	bool needToEat<- false;
	point cantineLocation;

	//Related to moving and surrounding
	point targetPoint<- nil;
	float maxDistancePoint<-5.0;
	float maxDistanceRadius<-10.0;
	bool stopped<-false;
	

	//Initialization
	init{		
		//Half of them get parents
		if flip(0.5){
			loop while: parent = nil{
				
				OTFan tmp <- one_of(OTFan);
				
				if tmp.child = nil{
					parent<-tmp;
					parent.child <- self;
					
				}
			}	
		}
		
		ask Cantine{
			myself.cantineLocation <- self.location;
		}
		
		ask DarthVader{
			myself.vader<-self;
		}
		
		ask Yoda{
			myself.yoda<-self;
		}
	}
	
	//Drops 1 hunger point (0.8 probable)
	reflex get_hungry when: hunger > 0{
		if flip(0.8){
			hunger<- hunger - 1;
		}
		
		if hunger = 0{
			targetPoint<-cantineLocation;
			needToEat <- true;
			goingWithVader<-false;
			goingWithYoda<-false;
			
			scoreCurrentShow<-0.0;
			currentShow<-nil;
		}
	}
	
	//When in cantine, fills hunger by 10 and leaves when full or too many PrequelsFan in the cantine
	reflex eating when: needToEat and location distance_to(cantineLocation) <= maxDistancePoint + 0.1{
		hunger <- hunger + 10;
		
		if hunger > 200 and flip(0.8){
			needToEat<- false;
			targetPoint<-nil;
			
			previouslyChecked<-false;	
		}
		 
		//Leaves if too many PrequelsFan eating in the same place
		if length(agents_at_distance(maxDistanceRadius) of_species (PrequelsFan) ) > 10 and !previouslyChecked{
			
			if agents_at_distance(maxDistanceRadius) of_species (OTFan) one_matches (each.child = self){
				if logCantine and logDisneySWFans {
					write self.name + ' too much PrequelFan eating here! But my parent is here';
				}
				
				previouslyChecked<-true;
			} else{
				if logCantine and logDisneySWFans {
					write self.name + ' too much PrequelFan eating here! I\'m leaving';
				}
			
				needToEat<- false;
				targetPoint<-nil;
				goingWithVader<-false;	
				goingWithYoda<-false;			
				
				if hunger < 100{
					hunger<-100;
				}
				
				previouslyChecked<-false;
			}

		}
	}
	
	//Reads messages from stages when a new show begins
	reflex read_informs when: !(empty(informs)){
		loop i over: informs{
			string tmp<- string(i.contents);
			
			//New show
			if species(i.sender) = Stage{		
				float score;
			
				if i.contents[1] = 1{
					score<-OTPref;
				}else if i.contents[1] = 2{
					score<-PreqPref;
				}else{
					score<-DisneyPref;
				}
				
				if score > scoreCurrentShow and !needToEat{
					currentShow<-i.sender;
					targetPoint<-currentShow.location;
					scoreCurrentShow<-score;
					goingWithVader<-false;
					goingWithYoda<-false;
				}
			}
			
			//Darth Vader
			else{
				//Darth Vader appeared
				if length(i.contents) > 1{
					float score<-rnd(7,9)/10;
					
					if score > scoreCurrentShow and !needToEat{
						currentShow<-nil;
						targetPoint<-agent(i.sender).location;
						scoreCurrentShow<-score;	
						goingWithVader<-true;
						goingWithYoda<-false;
					}	
				}
				//Dart Vader scares people
				else if flip(0.5) and !needToEat{
					targetPoint<-{rnd(100),rnd(100)};
					scoreCurrentShow<-0.0;	
					goingWithVader<-false;
				}
				
			}
		}
	}
	
	//Reads proposals from stages
	reflex read_proposes when: !(empty(proposes)){
		loop p over: proposes{
			string tmp<- string(p.contents);

			float score;
			
			if p.contents[1] = 1{
				score<-OTPref;
			}else if p.contents[1] = 2{
				score<-PreqPref;
			}else{
				score<-DisneyPref;
			}
			
			if score > scoreCurrentShow and !needToEat{
				currentShow<-p.sender;
				targetPoint<-currentShow.location;
				scoreCurrentShow<-score;
				goingWithVader<-false;
				goingWithYoda<-false;
			}
		
		}
	}
	
	//Reads requests to move from parent
	reflex read_requests when: !(empty(requests)){
		loop r over: requests{
			
			string tmp<- string(r.contents);
			
			if logStages and logDisneySWFans {
				write self.name + ' moving to another stage because my parent told me so';
			}
			
			do start_conversation (to:: list(Stage) - currentShow, protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the show?']);
			scoreCurrentShow<-0.0;
		}
	}
	
	reflex find_parent when: currentShow != nil and self.parent != nil and stopped and parent.stopped and flip(0.001){
				if logStages and logOTFans {
					write self.name + ' I\'m going to look for my parent';
				}
				
				targetPoint<-parent.location;
				goingWithVader<-false;	
				goingWithYoda<-false;
	}
	
	reflex followVader when: goingWithVader and vader.moved and !movedVader{
		movedVader<-true;
		targetPoint<-vader.location;

	}
	
	reflex notFollowVader when: goingWithVader and !vader.appeared{
		movedVader<-false;
		goingWithVader<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	reflex chooseYodaRandom when: yodaOnOff and !needToEat and flip(0.005) and !goingWithYoda and !goingWithVader{
		goingWithYoda<-true;
		scoreCurrentShow<-rnd(5,7)/10;
		currentShow<-nil;
		targetPoint<-yoda.location;
	}
	
	reflex followYoda when: goingWithYoda and mod(time,20)=0{
		targetPoint<-yoda.location;
	}
	
	reflex notFollowYoda when: goingWithYoda and flip(0.01){
		goingWithYoda<-false;
		targetPoint<-nil;
		scoreCurrentShow<-0.0;
	}
	
	//Chooses where to go next
	reflex choosePlace when: targetPoint = nil{
		
		//0.1 probability to go to a random place
		if flip(0.05){
			targetPoint <- {rnd(100),rnd(100)};
			
		}else if vader.appeared and darthOnOff and flip(0.2){
			goingWithVader<-true;
			targetPoint<-vader.location;
			scoreCurrentShow<-rnd(7,9)/10;
			currentShow<-nil;
		}else if yodaOnOff and flip(0.2){
			goingWithYoda<-true;
			scoreCurrentShow<-rnd(5,7)/10;
			currentShow<-nil;
			targetPoint<-yoda.location;
			
		}else{
			do start_conversation (to:: list(Stage), protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the show?']);
		}
	}
	

		
	//Goes to selected point and stops if close
	reflex goToDest when: targetPoint != nil{
		
		if location distance_to(targetPoint) > maxDistancePoint{
			do goto target: targetPoint;
			stopped<-false;
		}else{
			do wander speed: 0.1;
			stopped<-true;
		}
		
	}
	

	aspect default{
		draw sphere(2) at: location color: #orange;
		//draw 'D' at: location + {-0.8,0.8,5} color: #black font: font('Default', 20, #bold) ;
		
	}
}

species DarthVader skills: [fipa,moving]{
	
	geometry shape <- obj_file("vader.obj") as geometry;

	//Related to others
	//Preferences for types of fans
	float OTFanPref<- rnd(3,10)/10;
	float PreqFanPref<- rnd(3,10)/10;
	float DisneyFanPref<- rnd(3,10)/10;

	float patience<-rnd(80,90)/10;
	float stressed <-0.0;
	float stressLevel<-0.0;

	//Related to moving and surrounding
	point targetPoint<- nil;
	bool stopped<-false;
	float maxDistancePoint<-20.0;
	float maxDistanceRadius<-14.0;
	
	//Related to appearing and moving
	bool appeared<-false;
	bool moved<-false;
	int ownTime<-0;

	//Initialization
	init{
		location<-{-100,-100};
	}
	
	reflex add_time when: darthOnOff{
		if flip(0.9){
			ownTime <- ownTime+1;
		}
		
		if stressed > 0{
			stressed <- stressed-0.35;
		}
	}
	
	//Chooses where to appear
	reflex appear when: !appeared and location < {-50,-50} and ownTime > 400 and flip(0.9) and darthOnOff{
		ownTime<-0;
		appeared<-true;
		
		write 'DARTH VADER HAS APPEARED!';
		
		loop while: location < {-50,-50}{
			point tmp <- {rnd(100),rnd(100)};
			
			bool conflicts<-false;
			
			ask Stage{
				if tmp distance_to(self.location) < myself.maxDistancePoint{
					conflicts<-true;
				}
			}
			
			ask Cantine {
				if tmp distance_to(self.location) < myself.maxDistancePoint{
					conflicts<-true;
				}	
			}
			
			if !conflicts{
				location<-tmp;
			}
		}
		
		do start_conversation (to:: list(OTFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Darth Vader appeared!',location]);
		do start_conversation (to:: list(PrequelsFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Darth Vader appeared!',location]);	
		do start_conversation (to:: list(DisneySWFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Darth Vader appeared!',location]);
		
	}
	
	//Chooses where to move if it has appeared
	reflex move_when_appeared when: appeared and !moved and ownTime > 100 and flip(0.9) and darthOnOff{
		
		ownTime<-0;
		
		loop while: targetPoint = nil{
			point tmp <- {rnd(100),rnd(100)};
			
			bool conflicts<-false;
			
			ask Stage{
				if tmp distance_to(self.location) < myself.maxDistancePoint{
					conflicts<-true;
				}
			}
			
			ask Cantine {
				if tmp distance_to(self.location) < myself.maxDistancePoint{
					conflicts<-true;
				}	
			}
			
			if !conflicts{
				targetPoint<-tmp;
			}
		}
		
	}
	
	//Chooses where to move if it has appeared
	reflex dissappear when: appeared and moved and ownTime > 200 and flip(0.9) and darthOnOff{
		ownTime<-0;
		appeared<-false;
		moved<-false;
		location<-{-100,-100};
		targetPoint<-nil;
		
		write 'DARTH VADER HAS DISAPPEARED!';		
	}
	
	reflex get_stressed when: darthOnOff and stressed <= 0.0{
		
		stressLevel<- OTFanPref *length(agents_at_distance(maxDistanceRadius) of_species (OTFan)) +
		PreqFanPref *length(agents_at_distance(maxDistanceRadius) of_species (PrequelsFan)) +
		DisneyFanPref *length(agents_at_distance(maxDistanceRadius) of_species (DisneySWFan));
		
		if stressLevel > patience {
			write "DARTH VADER IS STRESSED AND SCARES SOME PEOPLE!";
			stressed<-maxDistanceRadius;	
			do start_conversation (to:: list(agents_at_distance(maxDistanceRadius)), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['GO AWAY!']);
		}
	}
	
	
	//Goes to selected point and stops if close
	reflex goToDest when: targetPoint != nil and darthOnOff{
		if location distance_to(targetPoint) > maxDistancePoint{
			do goto target: targetPoint;
		}else{
			do wander speed: 0.1;
			moved<-true;
		}
	}
	
	aspect default{
		if darthOnOff{
			/**For importing .OBJ file: Uncomment the following commented line and comment the one about the cube**/
			//draw shape size: 8 at: location color: rgb(40, 40, 40) rotate: 90.0::{-1,0,0};
			draw cube(5.5) at: location color: #black;
			//draw circle(stressed) at: location color: #darkgrey;
		}
	}
}

species Yoda skills: [fipa,moving]{

	geometry shape <- obj_file("yoda.obj") as geometry;
	
	//Related to others
	//Preferences for types of fans
	float OTFanPref<- rnd(3,10)/10;
	float PreqFanPref<- rnd(3,10)/10;
	float DisneyFanPref<- rnd(3,10)/10;
	
	float patience<-rnd(100,130)/10;
	bool needToMove<-false;
	bool stressed <-false;
	float stressLevel<-0.0;
	
	DarthVader vader;
	
	//Related to moving and surrounding
	point targetPoint<- nil;
	bool stopped<-false;
	float maxDistancePoint<-15.0;
	float maxDistanceRadius<-13.0;
	
	init{
		location<-{50,50};
		targetPoint<- {50,50};
		
		ask DarthVader{
			myself.vader<-self;
		}
	}
	
	reflex avoid_vader when: stopped and yodaOnOff and location distance_to(vader.location) < maxDistancePoint and !needToMove{
		write "----Yoda: Avoiding DarthVader";
		needToMove<-true;
	}
	
	reflex get_stressed when: stopped and yodaOnOff and !needToMove and !stressed{
		
		stressLevel<- OTFanPref *length(agents_at_distance(maxDistanceRadius) of_species (OTFan)) +
		PreqFanPref *length(agents_at_distance(maxDistanceRadius) of_species (PrequelsFan)) +
		DisneyFanPref *length(agents_at_distance(maxDistanceRadius) of_species (DisneySWFan));
		
		if stressLevel > patience{
			write "----Yoda: I'm stressed, moving to another place";
			needToMove<-true;
			stressed<-true;	
		}
	}
	
	reflex choosePlace when: yodaOnOff and stopped and (mod(time,250)=0 or needToMove){
		needToMove<-false;
		
		if float(location.x) <= 50 and float(location.y) <= 50{
			targetPoint<-{rnd(60,90),rnd(10,40)};
		}else if float(location.x) > 50 and float(location.y) <= 50{
			targetPoint<-{rnd(60,90),rnd(60,90)};
		}else if float(location.x) > 50 and float(location.y) > 50{
			targetPoint<-{rnd(10,40),rnd(60,90)};
		}else {
			targetPoint<-{rnd(10,40),rnd(10,40)};
		}
	}
	
	//Goes to selected point and stops if close
	reflex goToDest when: targetPoint != nil and yodaOnOff{
		if location distance_to(targetPoint) > maxDistancePoint{
			do goto target: targetPoint;
			stopped<-false;
		}else{
			do wander speed: 0.1;
			stopped<-true;
			stressed<-false;
		}
	}
	
	aspect default{
		if yodaOnOff{
			/**For importing .OBJ file: Uncomment the following commented line and comment the if-else bellow it**/
			//draw shape at: location color: #green size: 10 rotate: 90.0::{-1,0,0};
			
			if stressed{
				draw box({8, 4 , 8}) at: location color: #lime;
			}else{
				draw box({8, 4 , 8}) at: location color: #green;
			}
		}
	}
}


species Stage skills: [fipa]{

	//Variables
	int order;

	// 1 = OT
	// 2 = Preq
	// 3 = Disney
	int currentShow;

	int showTime<-0;

	//Initialization
	init{
		order <- int(self);

		//Position		
		if order = 0{
			location <- {50,0,0};
		}
		else if order = 1{
			location <- {50,100,0};
		}
		else if order = 2{
			location <- {100,50,0};
		}
		
		// 1 = OT
		// 2 = Preq
		// 3 = Disney
		currentShow <- order;

	}
	
	//Generates a new concert and sends an inform message to all the people
	reflex new_show when: showTime = 0{
		showTime<-rnd(100,300);
		
		// 1 = OT
		// 2 = Preq
		// 3 = Disney
		currentShow <- rnd (1,3);
		
		if logStages{
			write self.name + ' new show! Type: ' + currentShow;
		}
		
		do start_conversation (to:: list(OTFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['New show!',currentShow,showTime]);
		do start_conversation (to:: list(PrequelsFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['New show!',currentShow,showTime]);	
		do start_conversation (to:: list(DisneySWFan), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['New show!',currentShow,showTime]);
	}
	
	//Decreases the show time by one at a time
	reflex decrease_time when: showTime > 0{
		showTime<- showTime-1;
	}
	
	//Replies to people asking about the shows
	reflex replyShows when: (!empty(cfps)){
		loop c over: cfps{
			message requestFromInitiator <- c;
						
			string tmp<-string(c.contents);
				
			do propose message: requestFromInitiator contents: ['Current show: ',currentShow,showTime];
		}
	}
	
	
	aspect default{
		image_file f;
		
		point position;
		
		if order = 1{
			position<-location+{0,3};
		}else if order = 2{
			position<-location+{5,0};
		}else{
			position<-location-{0,3};
		}
		
		if currentShow = 1{
			f<-image_file("Orig.jpeg");
			draw f size: {18,18} at: position;
		} else if currentShow = 2{
			f<-image_file("Prequel.jpeg");
			draw f size: {18,18} at: position;
		} else{
			f<-image_file("disney.jpg");
			draw f size: {22,13} at: position;
		}
		
		
		//draw cube(7) at: location color: #blue;
		
	}
}

species Cantine {
	
	gif_file f <-gif_file("cantine.gif");

	//Initialization
	init{
		location <- {0,50,0};
	}
	
	
	aspect default{
		draw f size: {30,15} at: location -{12,0};
		//draw cube(7) at: location color: #green;
	}
}


experiment Project type: gui {
	
	parameter "Darth Vader" var: darthOnOff category: "Agents";
	parameter "Yoda" var: yodaOnOff category: "Agents";	
	
	
	parameter "Logs for cantine" var: logCantine category: "Logs";
	parameter "Logs for stages" var: logStages category: "Logs";
	
	parameter "Logs for OTFans" var: logOTFans category: "Logs";
	parameter "Logs for PrequelFans" var: logPrequelFans category: "Logs";
	parameter "Logs for DisneySWFans " var: logDisneySWFans category: "Logs";
	
	
	output {
		display map type: opengl{
			species Stage;
			species Cantine;
			species OTFan;
			species DarthVader;
			species Yoda;
			species PrequelsFan;
			species DisneySWFan;
		}
		
		display Charts refresh:every(1#cycles) {
		    chart "Hunger Means" type: series size: {1,0.5} position: {0, 0}  x_range: 400 y_range: {0,250}{
			    data "OTFan" value:  mean (OTFan collect each.hunger) color:#blue;
			    data "PrequelsFan" value: mean (PrequelsFan collect each.hunger) color:#red;
			    data "DisneySWFan" value: mean (DisneySWFan collect each.hunger) color:#orange;
		    }	
		    
		    chart "Stress Levels" type: series size: {1,0.5} position: {0, 0.5}  x_range: 400 y_range: {0,15}{
			    data "Yoda" value:  Yoda collect each.stressLevel color:#green;
			    data "Yoda limit" value:  Yoda collect each.patience color:#lime;
			    data "Darth Vader" value:  DarthVader collect each.stressLevel color:#black;
			    data "Darth Vader limit" value:  DarthVader collect each.patience color:#grey;
		    }	
		}
	
	}
}