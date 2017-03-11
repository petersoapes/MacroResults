//16feb17 most current macro

run("Set Scale...", "distance=0 known=0 global");//remove previous scales
T = getTitle;
selectWindow(T);
run("Duplicate...", "title=duplicate duplicate");
selectWindow(T);
run("Stack to Images");
// cache image names
selectImage(2);
redImage = getTitle();
selectImage(3);
greenImage = getTitle();
selectImage(4);
blueImage = getTitle();

imageCalculator("and", greenImage, redImage);
setAutoThreshold("Shanbhag dark");
setOption("BlackBackground", true);
fociChannel = getTitle();

//work on centromeres
selectWindow(blueImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for centromere signal then press OK" );
run("Convert to Mask");
run("Despeckle");
run("Dilate");
run("Analyze Particles...", "  show=Outlines display exclude summarize add");
IJ.redirectErrorMessages()
wait(500);
centromereX = newArray();
centromereY = newArray();
for(i=0;i<roiManager("count");i++){
	roiManager("select",i);
	x = getResult("X", i);//from result page
	centromereX = Array.concat(centromereX, x);
	y = getResult("Y", i);//these are hte center points of roi
	centromereY = Array.concat(centromereX, y);
	cIndex = i+1; //cIndex = i+1;
	roiManager("Rename", roiManager("index") + "_centromere "+ cIndex);//cIndex
	Roi.setProperty("obj_class", "centromere");
	Roi.setProperty("cent_indx", i);
	roiManager("update");//roi must be selected again
	roiManager("select",i);
}
//setBatchMode("hide");
var centromereCount = roiManager("count");//centromere indices
//print("end blue channel processing. centCount: "+centromereCount);
//end blue channel processing

//start green channel processing
//print("processing green channel");
wait(500);
//selectImage(2);
selectWindow(greenImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for foci signal then press OK" );
//run("Convert to Mask");
wait(500);
run("Analyze Particles...", "size=4-Infinity display exclude summarize add");//size=6 also works well
//setBatchMode("hide");
//label foci
var fociCount = 0;
//don't think these variables below are important
allfociX = newArray();
allfociY = newArray();
for(f=centromereCount;f<roiManager("count");f++) {
	fociCount++;
	roiManager("select", f);
//	Roi.setProperty("paired", 10);//setting this property to for further blobject
	roiManager("Rename", roiManager("index")+ "foci "+ fociCount);//renaming to keep track of rois
//	roiManager("Set Color", "orange");
//	roiManager("Set Color", "blue");
//	roiManager("Set Line Width", 1);
	roiManager("update");
	
//	setColor(string)
//Sets the drawing color, where 'string' can be "black", "blue", "cyan", "darkGray", "gray", "green", 
//"lightGray", "magenta", "orange", "pink", "red", "white", "yellow", or a hex value like "#ff0000".
	setResult("FociIndex",f, fociCount);
	//add to foci coordinates
	Roi.getCoordinates(fx, fy);
	Array.concat(allfociX, fx);
	Array.concat(allfociY, fy);
}//end green channel processing

//process red channel (SC)
selectWindow(redImage);
run("Threshold...");
waitForUser("Step 1, Thresholding", "Adjust threshold for foci signal then press OK" );

run("Convert to Mask");
//run("Dilate");
run("Despeckle");
//run("Skeletonize"); // skeleton may not be best for the ridge detection 
run("Invert LUT");//activating the LUT allows ridge detection to be run
// Requires the Ridge Detection plugin from the Biomedgroup update site.

//run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 add_to_manager");
run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 extend_line show_junction_points show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE sigma=1.2 lower_threshold=16.83 upper_threshold=40");
//sigma 1.2, lower 16.83, upper 40
setBatchMode("hide"); // hide the UI for this computation to avoid unnecessary overhead

//rename all the SC
var scCount = 0;
JPcount = 0;
for(o=centromereCount;o<roiManager("count");o++){
	roiManager("select",o);
	if (startsWith(Roi.getName(), "C")) {
			roiManager("Rename", roiManager("index") + "SC ");
			scCount++;
			}
			//delete JPs, to clean up screen
		//print("start red channel. sc count: "+ scCount + ". blobcount: "+blobcount+". stuff in manager: "+roiManager("count"));
		//rename SC, delete JPs, set SC length property
		//for(i=centromereCount;i<roiManager("count");i++){
			
	if (startsWith(Roi.getName(), "JP-")) {
		roiManager("delete");
		o--;
		}
}
selectWindow(redImage);
run("Close"); 
selectWindow(greenImage);
run("Close"); 
selectWindow(blueImage);
run("Close"); 


//first poke around/edit of RD products
selectWindow("duplicate");
setTool("zoom");
run("In [+]");
run("In [+]");
waitForUser("Paused to poke around");		
y=100;
while(y>1){	
//add another option to pause an poke around
	Dialog.create("Fix pieces from Ridge Dection");//need crete before options can be added
	Dialog.addChoice("Choose edit method", newArray("poke", "Cleave", "Stitch", "finish", "delete Foci"));
//write deleteFoci1 that renames foci to non elegible name
	Dialog.show();	
	status1 = Dialog.getChoice();
	if(status1=="Cleave"){
		waitForUser("click on point to cleave");
		Dialog.create("Cleave step. Choose line to cleave. Click on point to cleave.");
		Dialog.show();		
		setTool("point");		
		getSelectionCoordinates(cleave_pointx, cleave_pointy); // these cleavage points fill in correctly
		print("cleave point x "+ cleave_pointx[0]);
		print("cleave point y "+ cleave_pointy[0]);
		Dialog.create("enter roi index");
		Dialog.addNumber("roi index", 0);//parameter
		Dialog.show();
		roi = Dialog.getNumber();
			//delete choosen roi here -- and run re-sorting and renaming outside of the functions
		print("cleaving");
		Cleave(roi, cleave_pointx[0], cleave_pointy[0]);
		roiManager("update"); //updateDisplay()?
		scCount++;		
	}
	if(status1=="Stitch"){
//	enter numbers for SC1 SC2, wait for user cent x, cent y
//this doesn't seem to be working
		Dialog.create("starting the Stitching process. click on centromere"); // asses if centromere rois are in yet
		Dialog.show();
		waitForUser("choose SC pieces to join. Centromere SC first");
		Dialog.create("choose SC pieces to join. Centromere SC first");
		Dialog.addNumber("centromere", 0);
		Dialog.addNumber("first", 0);
		Dialog.addNumber("second", 0);
		Dialog.show();
		cent_indx = Dialog.getNumber();
		first = Dialog.getNumber();;
		sec = Dialog.getNumber();;;
		Stitch(first, sec, cent_indx);
		roiManager("update");
		scCount++;
	} //go back to menu
	if(status1 == "delete Foci"){
		DeleteFoci1();
		roiManager("update");		
	}
	if (status1=="poke") {
		waitForUser("paused for poking around");
	}
	if (status1=="finish") {
					y=1;
			}
//add addFoci
						
}//end while loop				
var blobCount = 0;	
//SC rename  ridge detection items not being renamed
JPcount = 0;//this doesn't need to be globally set since they are all deleted
print("start red channel. sc count: "+ scCount + ". blobcount: "+blobCount+". stuff in manager: "+roiManager("count"));
for(i=centromereCount;i<roiManager("count");i++){
	roiManager("select",i);
	if (startsWith(Roi.getName(), "JP-")) {
		roiManager("delete");
		i--;
	}
	else {
		if (startsWith(Roi.getName(), "SC")) {
			scCount++;
			//roiManager("Rename", roiManager("index") + "SC "); // edit renamed above			
			roiManager("measure");
			sclength = getResult("Length",i);
			Roi.setProperty("SC Results length", sclength); // this is a property of the SC
			setResult("SC index", i, roiManager("index")); // link to SC roi index
			}
		}
	}
print("SC count: "+scCount);

//loop through centromeres, find overlapping SC, form blobjects
for(cen=0; cen < centromereCount+1;cen++){
	roiManager("Select",cen);
	if(matches(Roi.getName(), ".*centromere.*")) {
		makeBlob(cen);// first blob formation
		print("this is cen " + cen);
		roiManager("update");
		blobCount++;
		}
}

//check newly made blob properties
//print("finished centromere pairing. "+ blobCount+ "   is blobcount");	
//for(meh=0; meh < roiManager("count")-1; meh++){
//	roiManager("Select",meh);
//	print("internal property check :  "+Roi.getProperties());
//}

//make new blobs
//setTool('wand');
waitForUser("Make new blobs and edit"); //for createing blobs that the computer doesn't recognize and 
//joining seperated splines
y=100;
while(y>1){
	Dialog.create("Step 2: Blob Creation");
	Dialog.addChoice("Create more blobs?", newArray("new blob", "Stitch", "Cleave", "finish", "poke")); 
// add edit for stitching SC to make more blob
	Dialog.show();
	more_blobs = Dialog.getChoice();
	if(more_blobs=="new blob") {
		waitForUser("Step 3: Check elements to create new blob");
		Dialog.create("Assign Blob indeces");
		Dialog.addNumber("centromere index", 0);
		Dialog.addNumber("SC index", 0);//TODO, add more than 1 SC piece
		Dialog.show();
		cent = Dialog.getNumber();
		sc = Dialog.getNumber();;	
		makeBlob2(cent, sc);//might be throwing an error
//is obj_class set?		
		roiManager("update");
		blobCount++;		
		} 
//stitch should be applied to SC's not blob
	if(more_blobs=="Stitch"){
//this doesn't seem to be working
		waitForUser("choose SC pieces to join. Centromere SC first");
		Dialog.create("choose SC pieces to join. Centromere SC first");
		Dialog.addNumber("centromere", 0);
		Dialog.addNumber("first", 0);
		Dialog.addNumber("second", 0);
		Dialog.show();
		cent_indx = Dialog.getNumber();
		first = Dialog.getNumber();;
		sec = Dialog.getNumber();;;
		Stitch(first, sec, cent_indx);
		roiManager("update");
	} //go back to menu
	if(more_blobs=="Cleave"){
		waitForUser("click on point to cleave");
		Dialog.create("Cleave step. Choose line to cleave. Click on point to cleave.");
		Dialog.show();		
		setTool("point");		
		getSelectionCoordinates(cleave_pointx, cleave_pointy); // these cleavage points fill in correctly
		print("cleave point x "+ cleave_pointx[0]);
		print("cleave point y "+ cleave_pointy[0]);
		Dialog.create("enter roi index");
		Dialog.addNumber("roi index", 0);//parameter
		Dialog.show();
		roi = Dialog.getNumber();
			//delete choosen roi here -- and run re-sorting and renaming outside of the functions
		print("cleaving");
		Cleave(roi, cleave_pointx[0], cleave_pointy[0]);
		roiManager("update"); //updateDisplay()?		
	}
	if(more_blobs == "poke"){
//pause window to poke arround
		waitForUser("Paused to poke around");	
	}
	else if(more_blobs=="finish"){
  			y=0;
      }
}//end of manual blob creation
print("finished making new blobs");
print("start second approval match");//this prints, 
selectWindow("duplicate");
roiManager("Show None");//what is this line for?


//create Blobjects, blobs + foci
print("starting to add foci to blobs to make blobjects");
for(ber=roiManager("count")-1; ber > centromereCount+fociCount+scCount-1; ber--){ // keep this -1
	print("start foci adding, on blob "+ber);
	roiManager("Select", ber);
	SC4blob =Roi.getProperty("SC_index");
	roiManager("deselect");
	roiManager("Select", SC4blob);
	Roi.getCoordinates(SCx, SCy);
	print("initialized array");
	roiManager("deselect");
	blob_new1 = newArray(0);//what is this second array?	
	for(ff =centromereCount; ff < centromereCount+fociCount; ff++){//foci loop
//add condition to skip 'deleted foci'
		roiManager("Select", ff);
//if(matches(Roi.getName(), ".*centromere.*")) {		
		print("on foci count " + ff);//when loops through entire ff loop without foci, 	
		WA_output = walk_array(ff, SCx, SCy);//		
		roiManager("deselect");
		roiManager("Select", ber);
		OC = Roi.getProperty("obj_class");
	//	roiManager("deselect");
		if( (WA_output[1] != 0 ) && (OC == "blob") ){//will blob obj work? 	
			print("foci identification true");
			Array.print(WA_output);//last one is the foci				
		//	blob_new1 = newArray(ber, WA_output[4]);	//THIS array is filled!!!
		//	print("the first array should be filled");
			//Array.print(blob_new1);			 								
			Roi.setProperty("obj_class", "1CO");//ber selected				
			roiManager("Rename", roiManager("index")+"_"+"1CO"+"blobject");
			Roi.setProperty("foci1_index", WA_output[4]);//4 is roi
			Roi.setProperty("foci1_array_pos", WA_output[3]);//3 should be k	//OMG get ride of spaces in properties		
			print("1CO prox foci SC array pos assigned " + WA_output[3]);						
			roiManager("deselect");
			roiManager("Select", ff);
			roiManager("Set Color", "orange");//paired foci are identified as orange, 
			roiManager("Set Line Width", 1);
			roiManager("update");				
				}//end good WA and not 1CO									
		if(  (WA_output[1] != 0) && (OC == "1CO") ){				
//if WA filled, if already 1CO, if foci added in the wrong order
			first_ff_index = Roi.getProperty("foci1_index");
			first_ff_pos = Roi.getProperty("foci1_array_pos"); //this should be less than new ff WA[3]
			Roi.setProperty("obj_class", "2CO");
			roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
//loop needs to be down here since update 1CO foci property things need to be extracted		
			if(first_ff_pos > WA_output[3]){//if newer position is shorter/closer than old foci position, 
//older should be prox							
				print("swapping previous foci positions ect");
				print("previous 'distal array pos' (new WA_output) "+ WA_output[3]);
				Roi.setProperty("foci1_array_pos", WA_output[3]);//array
				Roi.setProperty("foci1_index",WA_output[4]);//roi
				Roi.setProperty("foci2_array_pos", first_ff_pos);//old 
				Roi.setProperty("foci2_index", first_ff_index);//	
				Roi.setProperty("obj_class", "2CO");											
				roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
				roiManager("update");	
				print("updated prox array pos "+ Roi.getProperty("foci1_array_pos"));
				print("updated 'distal array pos "+Roi.getProperty("foci2_array_pos") );				
				print("blob class set to 2CO");										
				FOCI2ADD = newArray(ber, WA_output[4]);
				blob_new1 = Array.concat(blob_new1, WA_output[4]);//4 is roi, 
			//roiManager("deselect");
			//roiManager("Select", 0);
				roiManager("deselect");
				roiManager("Select", ff);
				roiManager("Set Color", "orange");
				roiManager("Set Line Width", 1);
				roiManager("update");
			}
			if( (first_ff_pos < WA_output[3]) ){  
//if foci are added in order that aligns with prox and distal label, go through this loop		 				
				print("foci loop is in the right order");	
				Roi.setProperty("foci1_array_pos", first_ff_pos);//array
				Roi.setProperty("foci1_index",first_ff_index);
				Roi.setProperty("foci2_array_pos", WA_output[3]);//roi index should be 3
				Roi.setProperty("foci2_index", WA_output[4]);//roi position should be k, 4
				Roi.setProperty("obj_class", "2CO");
				roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
			//	roiManager("Rename", roiManager("index")+OC+"blobject");
				//Roi.setProperty("foci index", "NA");//4 is roi
				//Roi.setProperty("foci array pos", "NA");
				roiManager("update");
				print("distal foci SC indx assigned " + WA_output[3]);		
				print("blob class set to 2CO");									
				FOCI2ADD = newArray(ber, WA_output[4]);//this never seems to get 
				blob_new1 = Array.concat(blob_new1, WA_output[4]);//4 is roi, 
				
				roiManager("deselect");
				roiManager("Select", ff);
				roiManager("Set Color", "orange");
				roiManager("Set Line Width", 1);
				roiManager("update");	
				}		
		}//end already 1CO loop
//if there are more foci after 2CO. If WA_output is not empty, and blob is already 2CO, 	
		if(  (WA_output[1] != 0) && (OC == "2CO") ){
			first_ff_index = Roi.getProperty("foci1_index");
			first_ff_pos = Roi.getProperty("foci1_array_pos"); //this should be less than new ff WA[3]
			second_ff_index = Roi.getProperty("foci2_index");
			second_ff_pos = Roi.getProperty("foci2_array_pos");
			Roi.setProperty("obj_class", "3CO");
//rename index_3CO_blobject
			roiManager("Rename", roiManager("index")+"_"+"3CO"+"blobject");
//3 following loops determine the correct order of the add foci (prox, medial, distal)			
			if( ( WA_output[3] < first_ff_pos) && ( WA_output[3] < second_ff_pos)  ){  //output->1, foci1->2, foci2 -> 3	 					
				Roi.setProperty("foci1_array_pos", WA_output[3]);//array
				Roi.setProperty("foci1_index",WA_output[4]);				
				Roi.setProperty("foci2_array_pos", first_ff_pos);//roi index should be 3
				Roi.setProperty("foci2_index",first_ff_index);//roi position should be k, 4
				Roi.setProperty("foci3_array_pos", second_ff_pos);//roi index should be 3
				Roi.setProperty("foci3_index",second_ff_index);//roi position should be k, 4
				print("distal foci SC indx assigned " + WA_output[3]);									
				FOCI2ADD = newArray(ber, WA_output[4]);//this never seems to get 
				blob_new1 = Array.concat(blob_new1, WA_output[4]);//4 is roi, 
//foci to orange could be made into a function				
				roiManager("deselect");
				roiManager("Select", ff);
				roiManager("Set Color", "orange");
				roiManager("Set Line Width", 1);
				roiManager("update");	
				}			
			if( ( WA_output[3] > first_ff_pos) && ( WA_output[3] < second_ff_pos)  ){  //output->2, foci1->1, foci2 ->3	
				Roi.setProperty("foci2_array_pos", WA_output[3]);//array
				Roi.setProperty("foci2_index",WA_output[4]);
				Roi.setProperty("foci3_array_pos",second_ff_pos);
				Roi.setProperty("foci3_index",second_ff_index);
				print("distal foci SC indx assigned " + WA_output[3]);										
				FOCI2ADD = newArray(ber, WA_output[4]);//this never seems to get 
				blob_new1 = Array.concat(blob_new1, WA_output[4]);//4 is roi, 
				
				roiManager("deselect");
				roiManager("Select", ff);
				roiManager("Set Color", "orange");
				roiManager("Set Line Width", 1);
				roiManager("update");
			}		
			if( ( WA_output[3] > first_ff_pos) && ( WA_output[3] > second_ff_pos)  ){  //output->3, foci1->1, foci2->2	
				Roi.setProperty("foci3_array_pos",WA_output[3]);
				Roi.setProperty("foci3_index",WA_output[4]);
				print("distal foci SC indx assigned " + WA_output[3]);									
				FOCI2ADD = newArray(ber, WA_output[4]);//this never seems to get 
				blob_new1 = Array.concat(blob_new1, WA_output[4]);//4 is roi, 
				roiManager("deselect");
				roiManager("Select", ff);
				roiManager("Set Color", "orange");
				roiManager("Set Line Width", 1);
				roiManager("update");				
			}
		
		}//is blob 2CO blobject	
							
	}//end foci loop.  this should print for the biv at end of foci loop
	if(blob_new1.length >= 2){  //is a composite really needed to be made? properties of the indces and positions 
//might not require composite rois		
			print("foci for adding ");//foci for adding not printing
			Array.print(blob_new1);//this			
			makeComposite(blob_new1, ber);//error comes back with this line			
			roiManager("update");
			}//make composite loop							
}//end ber loop

//Dialog.create("Assign Blobject indeces to update");
//waitForUser("Step 4: edit blobjects. add ojects to roi manager");
counter = 10;
while(counter  < 50){
	Dialog.create("Step 3?: Blobject editing");
	Dialog.addChoice("", newArray("poke","Add Foci", "delete foci", "finish", "Cleave", "Stitch", "new blob", "mark bad blobject"));
	Dialog.show();
	EDIT_blobs = Dialog.getChoice();
	if(EDIT_blobs=="poke") {
		waitForUser("paused for poking around");
	}
	if(EDIT_blobs=="Add Foci") {
		AddFoci();//find a way to exit this part
		roiManager("update");
	}
	if(EDIT_blobs == "finish"){
		counter = 200;
		}
	if(EDIT_blobs == "mark bad blobject"){
//enter blobject index and rename 		
		Dialog.create("Marking Blob");
		Dialog.addNumber("blobject index", 0);
		Dialog.show();
		blobject_index = Dialog.getNumber();

		roiManager("Select", blobject_index);
		roiManager("Rename", roiManager("index")+"_"+"bad_blobject");
		roiManager("update");
		}
	if(EDIT_blobs == "delete foci"){
		print("entering delete foci function");
		DeleteFoci();
		roiManager("update");
//return blobject to		
		}	
	if(EDIT_blobs == "Cleave"){
		waitForUser("click on point to cleave");
		Dialog.create("Cleave step. Choose line to cleave. Click on point to cleave.");
		Dialog.show();		
		setTool("point");		
		getSelectionCoordinates(cleave_pointx, cleave_pointy);
		print("cleave point x "+ cleave_pointx[0]);
		print("cleave point y "+ cleave_pointy[0]);
		Dialog.create("enter roi index");
		Dialog.addNumber("roi index", 0);
		Dialog.show();
		roi = Dialog.getNumber();
		print("cleaving");
		Cleave(roi, cleave_pointx[0], cleave_pointy[0]);
		roiManager("update");		
		}
	if(EDIT_blobs == "Stitch"){
		waitForUser("choose SC pieces to join. Centromere SC first");
		Dialog.create("choose SC pieces to join. Centromere SC first");
		Dialog.addNumber("centromere", 0);
		Dialog.addNumber("first", 0);
		Dialog.addNumber("second", 0);
		Dialog.show();
		cent_indx = Dialog.getNumber();
		first = Dialog.getNumber();;
		sec = Dialog.getNumber();;;
		Stitch(first, sec, cent_indx);
		roiManager("update");
			} //go back to menu		
	if(EDIT_blobs == "new blob"){
		Dialog.create("Assign Blob indeces");
		Dialog.addNumber("centromere index", 0);
		Dialog.addNumber("SC index", 0);//TODO, add more than 1 SC piece
		Dialog.show();
		cent = Dialog.getNumber();
		sc = Dialog.getNumber();;	
		makeBlob2(cent, sc);//might be throwing an error
//is obj_class set?		
		roiManager("update");
		blobCount++;
		}			
}//end while loop

//Approval step//the above while, means that the finish selection needs to be made before the cycle is complete
//aprove step doesn't display the obj_class in the approval step
for(aprv2=roiManager("count")-1; aprv2 > centromereCount+fociCount+scCount-1; aprv2--){ //start at SC, keep the upper at -1
	roiManager("Select", aprv2); // this should make the selection
//get obj_class to report with apporval
	aprv2_obj = Roi.getProperty("obj_class");
	print("Confirm blobs. Checking blobs " + aprv2 +"  "+Roi.getName());
	waitForUser("Step 2: Blob Approval. Paused for adjustment."+ "\n"+
	""+"\n"+"");
	roiManager("Select", aprv2);
	if(matches(Roi.getName(), ".*blob.*")) {  
		roiManager("Select", aprv2); //make sure that this selection is visble
			Dialog.create("Blobject Manager");
			Dialog.addChoice(aprv2_obj + " : " + Roi.getName()+": ", newArray("Accept blob", "delete", "XY",
			"poke", "add foci", "delete foci"));
			Dialog.show();		
			status2 = Dialog.getChoice();
			if(status2 =="Accept blob") {
				roiManager("Select", aprv2);
				roiManager("Set Color", "blue");
				roiManager("Set Line Width", 0);
				roiManager("update");
			}
			if(status2 =="XY"){
				roiManager("Select", aprv2);
				Roi.setProperty("obj_class", "XY");//this label is not translating into the 2CO...	
				roiManager("Set Color", "green");
				roiManager("Set Line Width", 0);
				print('setting property to XY: '+ Roi.getProperty("obj_class") );
				roiManager("Rename", roiManager("index")+"_XY");
				
				roiManager("update");
			}
			if(status2 == "add foci"){ //do I really need add foci here?
				AddFoci();
				aprv2 = aprv2-2;//return counter to -1
				roiManager("update");
//if addfoci() remains at this step, it may not require the user input of roi index.
			}
			if(status2 =="Delete"){
				delete_array = Array.concat(aprv2);
				Roi.setProperty("obj_class", "delete");
				roiManager("update");
			}
			if(status2 == "delete foci"){
				DeleteFoci();
				//aprv2--;//return counter to -1
				aprv2 = aprv2-2;
				roiManager("update");
				}			
			}//end blob loop
		}//end approv loop

selectWindow("Junctions"); 
run("Close"); 
selectWindow("Results"); 
run("Close"); 
selectWindow("Summary"); 
run("Close"); 

//this is almost working -- close to printing out correctly
f = File.open("");//main output biv file
//f = File.open("/Users/April/Desktop/"+T+".txt"); // create unique file for each image -- with title of image.
//f = File.open

print(f,"image title"+"\t"+"blobject name"+"\t"+"SClength results"+"\t"+"SC length array"+
"\t"+"correct"+"\t" +"blobjectClass"+"\t"+"foci 1 SCarray index"+
"\t"+"foci 1 position"+"\t"+"foci 2 SCarray index"+"\t"+"foci 2 position"+"\t"+"IFD"+"\t"+"notes");
//File.close(f);
var SplineCount = 0;

//this loop doesn't have smaller loop for 3CO
for(final = roiManager("count")-1; final > centromereCount+fociCount+scCount-1; final--){
	roiManager("select", final);
	print("blob index is : "+final);
//i don't think that this loop is correctly going through the blobjects	
	print("roi test: "+Roi.getName()+"  :"+Roi.getProperties());//too many elements being printed
	obj_class = Roi.getProperty("obj_class");//objClass
	roiManager("deselect");
	sc_indx = Roi.getProperty("SC_index");//these can be called below
	roiManager("select", sc_indx);
	Roi.getCoordinates(scx, scy);	
//	if(obj_class != "delete"){ // deleted blobjects could be printed
		if(obj_class == "blob"){	
			prox_roi_indx = Roi.getProperty("foci1_index");
			prox_array_pos = Roi.getProperty("foci1_array_pos");//3 is 					
			rev_status = Roi.getProperty("reverse");
			SC_array_length = Roi.getProperty("SC_array_length");		
			distal_roi_indx = "NA";//since these variables are called for printing, 
			prox_f2C = "NA";//initialize this variable for printing
			distal_f2C ="NA";//they must be filled before the printing line.
			ifd = "NA";
			roiManager("select", final);
			PrintBivResults();
			File.close(f);
		}
		if(obj_class == "1CO"){	
			print("obj class is 1CO");
			roiManager("select", final);//get foci roi indeces		
			prox_roi_indx = Roi.getProperty("foci1_index");			
			prox_array_pos = Roi.getProperty("foci1_array_pos"); 					
			rev_status = Roi.getProperty("reverse");
			SC_array_length = Roi.getProperty("SC_array_length");
//sc, point1, point2, WA[3] is array point			
			distal_roi_indx = "NA";//since these variables are called for printing, 
			distal_f2C ="NA";//they must be filled before the printing line.
			ifd = "NA";
			prox_f2C = "NA";//prox_f2C should be initialized
//			distal_f2C = "NA";//they must be defined for 1CO so print function doesn't throw an error
			print("properties gathered ");//not sure what this will do			
			print("printing stats on " + final);			
			if(rev_status == "yes") {
//if rev_status is true, the indeces have to be adjusted before running splineMeasure
				print("within 'final' loop, rev status is yes, adjusting indeces");
				print("intiailly array_index pos is " + prox_array_pos);
//why in SC arry length empty			
				print("elements for the below math " + SC_array_length + " - " + prox_array_pos);
				adj_ary_index = abs( parseFloat(SC_array_length) - parseFloat(prox_array_pos) - 1); 
//point2 = abs(parseFloat(Scpx.length - point2 - 1));			
				print("intiailly array_index pos is "+prox_array_pos + " adjusted value is "+adj_ary_index);
				prox_f2C = splineMeasure(sc_indx, 0, adj_ary_index);//writing this after should override		
				SplineCount++;
				roiManager("select", final);
				PrintBivResults();
				File.close(f);
				}
			if(rev_status == "no"){
				print("about to run 1CO spline measure. parms: "+ sc_indx +" and "+ 0+" and " + prox_array_pos);			
//error thrpwn here
				prox_f2C = splineMeasure(sc_indx, 0, prox_array_pos);
//error being thrown here.. probably due to 		
				SplineCount++;
				roiManager("select", final);
				PrintBivResults();
				File.close(f);
			}					
			roiManager("deselect");
			}//end 1CO loop	
		if(obj_class == "2CO"){
			print("obj_class is 2CO");
			roiManager("select", final);			
			prox_roi_indx = Roi.getProperty("foci1_index");//i think these are empty?
			prox_array_pos = Roi.getProperty("foci1_array_pos"); 						
			distal_roi_indx = Roi.getProperty("foci2_index");//distal
			distal_array_pos = Roi.getProperty("foci2_array_pos");
			SC_array_length = Roi.getProperty("SC_array_length");
			print("this is distal pos  " +distal_array_pos);
			roiManager("select", final);
			sc_indx = Roi.getProperty("SC_index");
			rev_status = Roi.getProperty("reverse");									
			if(rev_status == "yes") {
//if rev_status is true, the indeces have to be adjusted before running splineMeasure
				print("within 'final' loop, rev status is yes, adjusting indeces");
				print("intiailly array_index pos is "+prox_array_pos);				
				adj_ary_index1 = abs(parseFloat(SC_array_length) - parseFloat(prox_array_pos) - 1); 
				print("intiailly array_index pos for 1 is "+prox_array_pos + " adjusted value is "+adj_ary_index1);
				prox_f2C = splineMeasure(sc_indx, 0, adj_ary_index1);//writing this after should override
				SplineCount++;
				print("variable check for 2nd foci. sc arr len prop: "+SC_array_length+
				" distal array index " +distal_array_pos);
				adj_ary_index2 = abs(parseFloat(SC_array_length) - parseFloat(distal_array_pos) - 1); 
				print("intiailly array_index pos for 2 is "+ distal_array_pos + " adjusted value is "+adj_ary_index2);				
				distal_f2C = splineMeasure(sc_indx, 0, adj_ary_index2);
				SplineCount++;
				ifd = splineMeasure(sc_indx, adj_ary_index1, adj_ary_index2);
				SplineCount++;
				roiManager("select", final);
				PrintBivResults();
				File.close(f);				
			}			
			if(rev_status == "no") {
				print("about to run spline measure. parms: "+ sc_indx +" and "+0+" and " + prox_array_pos);
//error thrown here				
				prox_f2C = splineMeasure(sc_indx, 0, prox_array_pos);
				
				SplineCount++;
				print("after spline. result is: "+ prox_f2C);//this is now printing
				print("about to run the second spline measure. parms: "+ sc_indx +" and "+0+" and " + distal_array_pos);
				distal_f2C = splineMeasure(sc_indx, 0, distal_array_pos);
				SplineCount++;
				print("after the second spline. result is: "+ distal_f2C);				
				ifd = splineMeasure(sc_indx, prox_array_pos, distal_array_pos);	
				SplineCount++;						
				print("checking ifd "+ ifd);
				print("printing stats on " + final);
				roiManager("select", final);
				PrintBivResults();
				File.close(f);			
				}
			}//2CO
			if(obj_class == "3CO"){ // initialize all the things for printing
				print("obj_class is 2CO");
			roiManager("select", final);			
			prox_roi_indx = Roi.getProperty("foci1_index");//i think these are empty?
			prox_array_pos = Roi.getProperty("foci1_array_pos"); 						
			distal_roi_indx = Roi.getProperty("foci2_index");//distal
			distal_array_pos = Roi.getProperty("foci2_array_pos");
//			medial_arry_pos						
			SC_array_length = Roi.getProperty("SC_array_length");
			print("this is distal pos  " +distal_array_pos);
			roiManager("select", final);
			sc_indx = Roi.getProperty("SC_index");
//rev status needed for correct spline drawing
			rev_status = Roi.getProperty("reverse");
				if(rev_status == "yes") {
					adj_ary_index1 = abs(parseFloat(SC_array_length) - parseFloat(prox_array_pos) - 1); 
					print("intiailly array_index pos for 1 is "+prox_array_pos + " adjusted value is "+adj_ary_index1);
					prox_f2C = splineMeasure(sc_indx, 0, adj_ary_index1);//writing this after should override
					SplineCount++;
					
					print("variable check for 2nd foci. sc arr len prop: "+SC_array_length+
					" distal array index " +distal_array_pos);
					
					adj_ary_index2 = abs(parseFloat(SC_array_length) - parseFloat(distal_array_pos) - 1); 
					print("intiailly array_index pos for 2 is "+ distal_array_pos + " adjusted value is "+adj_ary_index2);				
					distal_f2C = splineMeasure(sc_indx, 0, adj_ary_index2);
					SplineCount++;
					wait(500);//macro has been breaking around IFD calq, try slowing down
				
					print("about to run the second spline measure. parms: "+ sc_indx +" and "+adj_ary_index1+" and " + adj_ary_index2);

					ifd = splineMeasure(sc_indx, adj_ary_index1, adj_ary_index2);
					SplineCount++;
					roiManager("select", final);
					PrintBivResults();				
					}
				if(rev_status == "no") {	
					print("about to run spline measure. parms: "+ sc_indx +" and "+0+" and " + prox_array_pos);
				prox_f2C = splineMeasure(sc_indx, 0, prox_array_pos);
				SplineCount++;
				print("after spline. result is: "+ prox_f2C);//this is now printing
				print("about to run the second spline measure. parms: "+ sc_indx +" and "+0+" and " + distal_array_pos);
				distal_f2C = splineMeasure(sc_indx, 0, distal_array_pos);
			
				SplineCount++;
				print("after the second spline. result is: "+ distal_f2C);				
				wait(500);
				
				print("about to run the second spline measure. parms: "+ sc_indx +" and "+prox_array_pos+" and " + distal_array_pos);
				ifd = splineMeasure(sc_indx, prox_array_pos, distal_array_pos);	
				SplineCount++;						
				print("checking ifd "+ ifd);
				print("printing stats on " + final);
				roiManager("select", final);
				PrintBivResults();
				File.close(f);			
				}
		}//end 3CO loop
			if(obj_class == "XY"){
//I don't think this is printing
				print(f, T+"\t" + Roi.getName() + "\t" 
	 		+ Roi.getProperty("SC Results length") + "\t"
			 + Roi.getProperty("SC_array_length")+"\t"
			 + "\t"	 + obj_class);
			}	
			if(obj_class == "blob"){
				print("foci was not associate with this blob");
				}	
}//end blobject loop
File.close(f);

//close f file
//check all roi properties
wait(500);
for(bbb = 0; bbb < roiManager("count"); bbb++){
	roiManager("select", bbb);
	if(matches(Roi.getName(), ".*blobject.*")) {
		print("properties test: "+Roi.getName()+"  :"+Roi.getProperties());
	}
}

///functions
function printArray(a) {
      print("");
      for (i=0; i<a.length; i++)
          print(i+": "+a[i]);
  }
function reverseArray(a) {
      size = a.length;
      for (i=0; i<size/2; i++) {
          tmp = a[i];
          a[i] = a[size-i-1];
          a[size-i-1] = tmp;
       }
  }//end function  

function makeBlob(cen){
	print("entering makeblob");
	roiManager("Select", cen);
	Roi.setProperty("reverse", "no");//default
	Roi.getCoordinates(centx, centy);
	roiManager("deselect");
//need to set reverse property for this verison	
	for(noncen=centromereCount+fociCount; noncen < roiManager("count"); noncen++) { // make sure these counters will work in function format
		roiManager("Select", noncen); //select roi to test if SC
		if(matches(Roi.getName(), ".*SC.*")) { 
			Roi.getCoordinates(SCx, SCy);
				paired=false;
				for(k=0; k < centx.length && !paired; k++){  //k pixels in centromere
						if(Roi.contains(centx[k], centy[k])) { // this test is for if SC runs through centromere
		 						roiManager("deselect");
		 						
		 						roiManager("Select", cen);
								if(Roi.contains(SCx[5], SCy[5])) {  //change this to [5], since some ends of SC extend past centromere
									print(cen + " " + noncen + "SC array starts at centromere");
									Roi.setProperty("reverse", "no");//this is set for centromeres
									roiManager("update");//update required to set property in play
										}									
								if(Roi.contains(SCx[SCx.length-3], SCy[SCy.length-3])) { //if cent contains end of SC
									print(cen + " " + noncen + "centromere is at end of array. Reversing Arrays");
									SCx = Array.reverse(SCx);//
									SCy = Array.reverse(SCy);
									Roi.setProperty("reverse", "yes");//set for centromeres
									roiManager("update");
									}
		 					
		 						roiManager("Select", cen);
		 						reverse_status = Roi.getProperty("reverse");//centromere should still be selected

		 						roiManager("deselect");
		 						
		 						roiManager("select", noncen); //selecting the current sc
		 						Roi.setProperty("reverse", reverse_status);//sc should have reverse status, since that is the only roi spline measure selects		 						
		 						run("Measure");
								length1 = getResult('Length', nResults-1);							
								SClength = Roi.getProperty("SC Results length");//SC Results Length		 						
//test the printing for reverse status		 						
		 						print("reverse status in makeBlob for " + Roi.getName() +" is " +reverse_status);
		 						print("the SC length from the SC is "+SClength);
								roiManager("update");										 						
		 						blob_parts = Array.concat(cen, noncen);//noncen = SC
		 						roiManager("Select", blob_parts);//roiManager("Select", newArray(cen, noncen)) doesn't work
		   						roiManager("Combine");
								roiManager("Add");//new object
								roiManager("deselect");
								roiManager("Select", roiManager("count")-1); //select the new roi
								roiManager("Rename", roiManager("index")+"_blob");
								Roi.setProperty("SC_length", SClength);
								Roi.setProperty("SC_Results_length", length1);
								Roi.setProperty("SC_array_length", SCx.length); // SC array length  
								Roi.setProperty("SC_index", noncen);	
//this set-reverse property might not be working															
								Roi.setProperty("reverse", reverse_status);//setting reverse prop for blob, this needs to be checked each time SC coorindates are created			
								Roi.setProperty("obj_class", "blob");
								
								roiManager("update");
								noncen=1000; //break out of loop by overcounting 
								blobCount++;
								paired=true;
					        	}
			            }//k pixels in centromere   	
		         }//noncen name matches SC
			}//start cycling thru SCs 
}//end function

//function for making blobject when centromere and SC indeces are provided by user
function makeBlob2(cen, sc){
		roiManager("Select", newArray(cen, sc));// make sure if this is blank it still works
		roiManager("Combine");
		roiManager("Add");
		roiManager("Select", roiManager("count")-1);
		roiManager("Rename", roiManager("index")+"_blob"); 		
  		blobCount++;
  		roiManager("Select", sc);
  		run("Measure");
  		SClength = getResult('Length', nResults-1);//nResults was throwing everything off by 1?
  		Roi.getCoordinates(nSCx, nSCy);  		
//add code to test if SC array coordinates start in centromere		
		roiManager("Select", cent);
		if(Roi.contains(nSCx[5], nSCy[5])) { //change this index to 5th
			print(cen + " " + sc + "SC array starts at centromere");//no reverse needed
			Roi.setProperty("reverse", 'no');//centromere property
			roiManager("update");
			
		} if(Roi.contains(nSCx[nSCx.length-4], nSCy[nSCy.length-4])) { //change to index 4
			nSCx = Array.reverse(nSCx);
			nSCy = Array.reverse(nSCy);
//set reverse property
			Roi.setProperty("reverse", 'yes');//centromere property
			roiManager("update");
			print(cen + " " + sc + "centromere is at end of array. Array reversed with function");					
		}
//add an else loop so that the code doesn't break if roi doesn't work
//calling below properties from centromeres		
		bc = Roi.getProperty("obj_class");
		ifd = Roi.getProperty("IFD");
		pfp = Roi.getProperty("foci1_pos");//why are these called?
		dfp = Roi.getProperty("foci2_pos");
		rev_status = Roi.getProperty("reverse");	
  		roiManager("deselect");
//transfer reverse status to sc, so spline measures can check the array direction
		roiManager("Select", sc);
		Roi.setProperty("reverse", rev_status);	
		roiManager("deselect");		
  		roiManager("Select", roiManager("count")-1);//assign properties
		print("setting properties of new  blobject "+Roi.getName()); 
//set the same property for macro generated blobjects	
		Roi.setProperty("SC_array_length", nSCx.length);//this length value might be less accurate than the legnth from results
		Roi.setProperty("SC_Results_length", SClength);//SC length from results page
		Roi.setProperty("SC_index", sc);//maybe doing measure then assign	
  		Roi.setProperty("IFD", ifd);
  		Roi.setProperty("foci1_pos", pfp);
  		Roi.setProperty("foci2_pos", dfp);
  		Roi.setProperty("reverse", rev_status);
  		Roi.setProperty("obj_class", "blob");
  		roiManager("update");
    }//end makeBlob2 function

function Cleave(choosen_roi, CleavePointx, CleavePointy) { 
//after JPs are delted using another cleave, renders thing out of range
roiManager("Select",choosen_roi);//this get out of range
Roi.getSplineAnchors(Sx, Sy);//remember spline anchors are summary points
print("spline anchor length "+Sx.length);
roiManager("Select",choosen_roi);
NwAx = newArray(Sx.length);
NwAy = newArray(Sx.length);

counter = 0;
for (g=0; g < Sx.length; g++){ //g counter should start as 0
	counter++;
	found = isNear(cleave_pointx[0], cleave_pointy[0], Sx[g], Sy[g], 1); 
	if(found == false){
		NwAx[g] = Sx[g];
		NwAy[g] = Sy[g];
	}
	if(found== true){
		print(NwAx[g]);
		print("stop array");
		g=Sx.length; // this breaks out of the loop! but if 
	}      	
}
NwAx -1;//NwA arrays are no longer nessecary -- just the cleave point in array
NwAy -1;
piece1_NwAx = Array.trim(Sx, counter-1);//arry is trimed based on result of isNear
piece1_NwAy = Array.trim(Sy, counter-1);//old method NwAy

Roi.setPolylineSplineAnchors(piece1_NwAx, piece1_NwAy);
roiManager("add");// this draws splines, add vs add and draw
roiManager("Select",roiManager("count")-1);
roiManager("Rename", roiManager("index")+"SC_cleaved_piece");//think of a better name..
makeSelection("freeline",piece1_NwAx,piece1_NwAy);
roiManager("update");
wait(100);
roiManager("deselect");
//roiManager("update");

piece2_NwAx = Array.trim(Array.reverse(Sx), Sx.length-counter-1);//this creates the two pieces!!
piece2_NwAy = Array.trim(Array.reverse(Sy), Sx.length-counter-1);
Roi.setPolylineSplineAnchors(piece2_NwAx, piece2_NwAy); // this is doing something, don't think it is creating a new ROI
roiManager("add");// this draws splines
roiManager("Select",roiManager("count")-1);
roiManager("Rename", roiManager("index")+"SC_cleaved_piece");
makeSelection("freeline", piece2_NwAx, piece2_NwAy);
//roiManager("Select",choosen_roi);
//roiManager("delete");//this 
roiManager("update");
wait(100);
roiManager("Select",0);// see if this fixes the no actiev selection issue

}//end cleave function

function Stitch(SC1, SC2, cent){
	roiManager("Select", SC1);
//	Roi.getCoordinates(SCx1,SCy1);
	Roi.getSplineAnchors(Rspx, Rspy);
//based on centromere location, find order of spline array
	roiManager("deselect");
	
	roiManager("Select", cent);
//using set of summary points, to test centromere location and array direction
	cent_test = Roi.contains(Rspx[5], Rspy[5]); //some sc start outside the centronere, searching for 0, causes incorrect reversals
	if(cent_test == 1){ 
		print("array order matches centromere location");
} 	if(cent_test == 0){
		print("reversing SC array order");//why does SC array order matter here?
		Rspx = Array.reverse(Rspx);
		Rspy = Array.reverse(Rspy);
}
	roiManager("deselect");
	
	roiManager("Select", SC2);
//	Roi.getCoordinates(SCx2,SCy2);	
	Roi.getSplineAnchors(Sspx, Sspy);//spline coordinates of second  //test which sec SC end is near the fist SC
	second_end = isNear(Rspx[Rspx.length-1], Rspy[Rspy.length-1], Sspx[0], Sspy[0], 6);
//reversing things is due to stitching the previous SC arrays
	if(second_end == true){
		print("first end near sec begining"); // this is the correct ordering I want
		Cat_array_x = Array.concat(Rspx,Sspx); //first correct order, second correct order
		Cat_array_y = Array.concat(Rspy,Sspy);
	}
	if(second_end == false){
		print("first end near sec end");
		Sspx = Array.reverse(Sspx);
		Sspy = Array.reverse(Sspy);
		Cat_array_x = Array.concat(Rspx,Sspx);
		Cat_array_y = Array.concat(Rspy,Sspy); //
		wait(200);
	}
//use the above information to infor the concat ordering!!
	Roi.setPolylineSplineAnchors(Cat_array_x, Cat_array_y);
	roiManager("add");
	roiManager("Select", roiManager("Count")-1);//an error is thrown, when count+1
	roiManager("rename", roiManager("index") + "SC stitchtd");
	makeSelection("freeline", Cat_array_x, Cat_array_y);//make the full complete lines fullline
	roiManager("update");
	wait(200);
}//end Stitch function

function isNear(x1,y1,x2,y2, min_distance) {
    if( sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) < min_distance) {
        return true;
    } 
return false;
}//end isNear funciton

function SC_totals(){
SC_XY_total = 0;
SC_A_total = 0;
for(c=0;c<roiManager("count");c++) {
	roiManager("select", c);
	if(matches(Roi.getName(), ".*blobject.*")){
		obj_class = Roi.getProperty("obj_class");
		if(obj_class == "XY"){
			//sc length results aren'y set yet
			XY_rlength = Roi.getProperty("SC Results length");
			XY_length = Roi.getProperty("SC_array_length");
			SC_XY_total = XY_length + SC_XY_total;
		} 
		if(obj_class == "1CO"){
			//a_length = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC_array_length");
			//print(" 1CO math: " + a_length +" + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));	
	}
		if(obj_class == "2CO"){
			//aResult_length = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC_array_length");
			//print(" 2CO math: " + a_length + " + " + SC_A_total);
			SC_A_total = abs(parseFloat(a_length) + parseFloat(SC_A_total));
		}
		if(obj_class == "3CO"){
			//a_rlength = Roi.getProperty("SC Results length");
			a_length = Roi.getProperty("SC_array_length");
			SC_A_total = a_length + SC_A_total;
		  }		
	   }	   	
	}
     	print("autosomal SC calq: "+ SC_A_total);
	    print("XY SC total calq "+ SC_XY_total);
		sc_skel_array = newArray(SC_A_total, SC_XY_total);
		return sc_skel_array;
}//end SC total function

function makeComposite(array, blob){
	blob_foci = Array.concat(array, blob);
	roiManager("Select", blob_foci);
	roiManager("Combine"); // this function is merging foci into the blobject
	roiManager("deselect");
	roiManager("Select", blob);
//although this function not used much..
//think about incorporating obj_class into the blobject rename	
//compo
//	roiManager("Rename", roiManager("index")+"blobject"); //this rename makes this func less general
	roiManager("update");//renamed roi's maintain properties
}//end function

//walk_array should be modified for addFoci points
function walk_array(roi, array_x, array_y){
	roiManager("Select", roi);
	new_info = newArray(roi); 
	Roi.getCoordinates(roi_xpoints, roi_ypoints);//this should be length of 1, if point
	for(k=0; k < array_x.length; k++){ 

		if(roi_xpoints.length == 1) {
			if(isNear(roi_xpoints,roi_ypoints,array_x,array_y, 2)){
				new_info = newArray(array_x[k], array_y[k], k, roi);
				x_pos = array_x[k];
				y_pos = array_y[k];	
				}
			}
		else {	//else if the length is longer than 1, use roi.contains	
			if(Roi.contains(array_x[k], array_y[k])){			
			//print("match " + array_x[k] + " and "+array_y[k]);
				new_info = newArray(array_x[k], array_y[k], k, roi);
				x_pos = array_x[k];
				y_pos = array_y[k];		
				}//these values should update to the last values
			}
		}
		//array position, x and y		
		//info = newArray(k, x_pos, y_pos); // array indx, xposition, y position
		//info = List.getList();
		info = Array.concat(info, new_info);
		return info;
}//end function


//point array positions will not be correct if the SC needs to be reversed
//add 'optional' parameter of foci roi, since new walk function might be needed
//splineMeasure doesn't seem to be applied to 3CO blobs
function splineMeasure(sc, point1, point2){//make sure that 0 is first
	print("entering spline measure"); 
	roiManager("Select", sc);
	if(matches(Roi.getName(), ".*SC.*")) { // make sure the name is captitalized	
		Roi.getSplineAnchors(Scpx, Scpy);//getting spline anchors of the SC
		roiManager("Select", sc);
		rev_status = Roi.getProperty("reverse");
		if(rev_status == "yes"){ //this should be evaluating correctly
			print("within splineMeasure and rev status is 'yes' ");//this isn't printing
			print("the first points are is "+point1 +" and "+point2);
			Scpx = Array.reverse(Scpx); 
			Scpy = Array.reverse(Scpy);
		}
		NwAx = newArray(Scpx.length);
		NwAy = newArray(Scpx.length);//what is this used for?
		scx_trimd = newArray(0);
		scy_trimd = newArray(0);
		print("the full length is "+ Scpx.length);
		if( abs( parseFloat(point1)) > abs( parseFloat(point2)) ){ //if I get the SCarray reverse and foci order correct, this loop won't be needed.
			print("points are wrong order.  pnt 1, "+ point1+ " and pnt2, "+ point2);
			scx_trimd = Array.slice(Scpx, point2,point1);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point2,point1);
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");//splines must be added to RoiManager to measure 
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
			print("the results length " + RLength);
//			roiManager("delete");//commont out the delete and select new to remove the newly added apliens
//			roiManager("Select", 0);
			print("result length "+ RLength);
			wait(200);
			return RLength;//i think the return Rlength should be at end of each loop
		}
		if( abs( parseFloat(point1)) < abs(parseFloat(point2)) ){
			print("points are correct order, pnt 1, "+ point1+ " and pnt2, "+ point2);
			scx_trimd = Array.slice(Scpx, point1, point2);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point1, point2);
			print("spliced array length " + scx_trimd.length);//spliced is empty
//choose between end centromere/middle of centromere or begining of SC
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
			print("the results length " + RLength);
//			roiManager("delete");  // comment these out when macro starts behaving
//			roiManager("Select", 0);
			wait(200);
			print("result length "+ RLength);
//print("second trim "+ scy_trimd.length);		
			return RLength;
			
		}
	}//sc name
} // end of function

//these new foci do not have add position properties
function AddFoci(){
//get required information from user 1) point where to add foci 2) index of blob being affected
	waitForUser("point at object to add");
	setTool("point");
	waitForUser("enter the index for adding foci");
	Dialog.create("blob gaining foci");
	Dialog.addNumber("blobject index", 0);
	Dialog.show();
	roiManager("Add"); // this should add the selected point on the image
	roiManager("Select", roiManager("count")-1);// 
	roiManager("Set Color", "orange");
	roiManager("Set Line Width", 1);	
	roiManager("Rename", roiManager("index")+"foci");
	roiManager("update");
	roiManager("deselect");
	blob_index = Dialog.getNumber();//window for
	roiManager("Select", blob_index); //get properties from blob 1) object_class
	objclass = Roi.getProperty("obj_class");		
	SCindx = Roi.getProperty("SC_index");//get the SC index for WA, don't know if it's needed
	roiManager("deselect");
	roiManager("Select", SCindx);
	Roi.getCoordinates(SCx, SCy);
	WAout = walk_array( (roiManager("count")-1), SCx, SCy);//what is the foci
//walk_array failing to assign position properties
	print("within AddFoci, testing walkarray.");
	Array.print(WAout);
	wait(200);
//3 conditions for changing basic properties
	roiManager("deselect");
	if(objclass == "2CO"){	
		roiManager("Select", blob_index);
		print("updating 2CO properties to 3CO and foci3 index");
		Roi.setProperty("obj_class", "3CO");//3CO went thru, but index 3 didn't
		Roi.setProperty("foci3_index", roiManager("count")-1);
		Roi.setProperty("foci3_array_pos", WAout[3]);
		roiManager("Rename", roiManager("index")+"_"+"3CO"+"blobject");
	//roiManager("update");			
		}
	if(objclass == "1CO"){
		roiManager("Select", blob_index);	
		print("updating 1CO properties to 2CO and foci2 index");
		Roi.setProperty("obj_class", "2CO");
		Roi.setProperty("foci2_index", roiManager("count")-1);
		Roi.setProperty("foci2_array_pos", WAout[3]);//failing here
		roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
		//roiManager("update");
		}		
	if(objclass == "blob"){
		roiManager("Select", blob_index);
		print("updating blob properties to 1CO and foci1 index");
		Roi.setProperty("obj_class", "1CO");
		Roi.setProperty("foci1_index", roiManager("count")-1);
		Roi.setProperty("foci1_array_pos", WAout[3]);
		roiManager("Rename", roiManager("index")+"_"+"1CO"+"blobject");
		Roi.setProperty("foci1_array_pos", WAout[3]); 
		//roiManager("update");//this update will make it skip into the next loop	
		}
	roiManager("update");//don't update till out of those loops	
//the roi may not need to be combined -- as long as properties are correct		
	newcombo_array = newArray(blob_index, (roiManager("count")-1));//	
	roiManager("Select", newcombo_array);
	roiManager("Combine");//check that it is the blob that's make
//roiManager("add"); //i don't think this should be added. this would make a new roi instead of updating
//roiManager("Select", blob_index);//select orginal blob to rename
//roiManager("Rename", roiManager("index")+"new blobject"); //this rename makes this func less general
	roiManager("update");		
	}//end Addfoci

function PrintBivResults(){
//make sure that the below variables are initialized for both 1Cos and 2COs
//title is duplicate, not original
//several of these items dont get initialized then an error is thrown
print(f, T+"\t" + Roi.getName() + "\t" 
	 		+ Roi.getProperty("SC_Results_length") + "\t"
			 + Roi.getProperty("SC_array_length")+"\t"
//error with prox_f2C
			 + "\t"	 + obj_class + "\t"	 + prox_roi_indx + "\t"+ prox_f2C + "\t"
			 + distal_roi_indx + "\t"+ distal_f2C + "\t"  // 
			 + ifd );
			//File.close(f);
			wait(200);//try to delay code to fix file open error
			roiManager("deselect");
			}//end function

//create a PrintCellResults function

function DeleteFoci1(){ //simple delete foci function, not sure if it will be used
waitForUser("Add Foci index to delete");
Dialog.create("Foci to delete/rename");
Dialog.addNumber("Foci index", 0);
Dialog.show();
errfoci = Dialog.getNumber();
roiManager("select", errfoci);
roiManager("Rename", "delete" + Roi.getName() );
}//end function loop		

function DeleteFoci(){
waitForUser("Add Foci index to delete. Add blobject with foci");
Dialog.create("blob gaining foci");
Dialog.addNumber("Foci index", 0);
Dialog.addNumber("blobject index index", 0);;
Dialog.show();
errfoci = Dialog.getNumber();
blob_index = Dialog.getNumber();;
roiManager("select", errfoci);
roiManager("Rename", "delete" + Roi.getName() );
roiManager("Set Color", "yellow");//set color to unpaired
roiManager("Set Line Width", 0);	
roiManager("update");
roiManager("deselect");
roiManager("select", blob_index);
//get properties for running through the correct loops

objclass = Roi.getProperty("obj_class");		
	if(objclass == "1CO"){
//change class to blob, change foc1_index to NA, change foci1 array pos to NA
		Roi.setProperty("obj_class", 'blob');
		Roi.setProperty("foci1_index", 'NA');
		Roi.setProperty("foci1_array_pos", 'NA');
		roiManager("Rename", roiManager("index")+"_"+"0CO"+"blobject");
		roiManager("update");
	}
	
	if(objclass == "2CO"){ // if the blobject within which a foci is deleted
		print("inside deletefoci, object is 2CO");
		Roi.setProperty("obj_class", '1CO');
//determine if foci which is being deleted is foci1 or foci2
		foci1_indx = Roi.getProperty("foci1_index");
		foci2_indx = Roi.getProperty("foci2_index");
//foci1 or foci2 matches errfoci, 
  		if(foci2_indx == errfoci){ // set foci2 properties to NA
			print("foci 2 should be deleted");
			Roi.setProperty("foci2_index", 'NA');
			Roi.setProperty("foci2_array_pos", 'NA');
			roiManager("Rename", roiManager("index")+"_"+"1CO"+"blobject");
			roiManager("update");
  		}
  		if(foci1_indx == errfoci){ 
  			print("foci 1 should be deleted");
  			foci2_array_pos = Roi.getProperty("foci2_array_pos");	
// , set foci1 to current foci2 values, set foci values as NA		
			Roi.setProperty("foci1_index", foci1_indx);
			Roi.setProperty("foci1_array_pos", foci2_array_pos);
			Roi.setProperty("foci2_index", "NA");
			Roi.setProperty("foci2_array_pos", "NA");//i don't think property needs to be here
			roiManager("Rename", roiManager("index")+"_"+"1CO"+"blobject");			
  			roiManager("update");
  			}
		}
	if(objclass == "3CO"){
		print("inside deletefoci, object is 3CO");
		Roi.setProperty("obj_class", '2CO');
		foci1_indx = Roi.getProperty("foci1_index");	
		foci2_indx = Roi.getProperty("foci2_index");
		foci3_indx = Roi.getProperty("foci3_index");
		if(foci3_indx == errfoci){ //3 deleted, rest stay the same
			print("foci 3 should be deleted");
			Roi.setProperty("foci3_index", 'NA');
			Roi.setProperty("foci3_array_pos", 'NA');
			roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
			roiManager("update");
  		}
  		if(foci2_indx == errfoci){ //3 changed to 2, 1 stays the same
			print("foci 2 should be deleted"); // order doesn't really matter, 
			foci3_array_pos = Roi.getProperty("foci3_array_pos");
			Roi.setProperty("foci2_index", foci3_indx);
			Roi.setProperty("foci2_array_pos", foci3_array_pos);
			Roi.setProperty("foci3_index", 'NA');
			Roi.setProperty("foci3_array_pos", 'NA');//change 1 to 3
			roiManager("Rename", roiManager("index")+"_"+"2CO"+"blobject");
			roiManager("update");
		}
		if(foci1_indx == errfoci){ //3 changed to 1 (is simplest)
			print("foci 1 should be deleted");
			foci2_array_pos = Roi.getProperty("foci3_array_pos");// , set foci1 to current foci2 values, set foci values as NA
			Roi.setProperty("foci1_index", foci3_indx);
			Roi.setProperty("foci1_array_pos", foci3_array_pos);
			Roi.setProperty("foci3_index", 'NA');
			Roi.setProperty("foci3_array_pos", 'NA');
			roiManager("Rename", roiManager("index")+"_"+"1CO"+"blobject");			
  			roiManager("update");
  			}
		}
		
}//end deleteFoci function loop
	