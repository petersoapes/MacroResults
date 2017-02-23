//16feb17
//print results from aborted roi set
//prompt user to open folder saved roi set
//paste the loop of roiManager with printing results
//how does this avoid other errors?
run("Set Scale...", "distance=0 known=0 global");//remove previous scales
T = getTitle;
f = File.open("");//main output biv file
//f = File.open("/Users/April/Desktop/"+T+".txt"); // create unique file for each image -- with title of image.
//f = File.open

print(f,"image title"+"\t"+"blobject name"+"\t"+"SClength results"+"\t"+"SC length array"+
"\t"+"correct"+"\t" +"blobjectClass"+"\t"+"foci 1 SCarray index"+
"\t"+"foci 1 position"+"\t"+"foci 2 SCarray index"+"\t"+"foci 2 position"+"\t"+ "medial foci position" + "\t"
+"IFD" +"\t" +"IFD2" +"\t" + "rev stat"+"\t"+"notes");
//File.close(f);

//counts of rois in the roimanager are calculated to make for loop more efficient
var splineCount = 0;
var fociCount = 0;
var blobCount = 0;
var scCount = 0;
var centCount = 0;
var endfociCount= 0;
for(final = roiManager("count")-1; final > 1; final--){
	roiManager("select", final);
	if(matches(Roi.getName(), ".*0001.*")) { 
		splineCount++;
	}
	if(matches(Roi.getName(), ".*foci.*")) { 
		endfociCount++;//foci can be added after
	}
	if(matches(Roi.getName(), ".*foci .*")) { 
		fociCount++;//foci can be added after
	}
	if(matches(Roi.getName(), ".*blob.*")) { 
		blobCount++;
	}
	if(matches(Roi.getName(), ".*SC.*")) { 
		scCount++;
	}
	if(matches(Roi.getName(), ".*centromere.*")) { 
		centCount++;
	}
}
print("counts: endfoci "+endfociCount + ". and blob " + blobCount );
print("counts: cent count "+centCount + ". and fociCount " + fociCount +". and scCount "+scCount);
print("roimanager count "+roiManager("count") );

//find a way to limit the counts
for(final = centCount+fociCount+scCount-5; final < roiManager("count")-1; final++){
	roiManager("select", final);
	print("index is: "+final);
//i don't think that this loop is correctly going through the blobjects	
	print("roi test: "+Roi.getName()+": "+Roi.getProperties());//too many elements being printed
//	Roi.getProperties();
	//print(Roi.getProperties());
	obj_class = Roi.getProperty("obj_class");//objClass
	roiManager("deselect");
	sc_indx = Roi.getProperty("SC_index");//these can be called below
	roiManager("select", sc_indx);
	Roi.getCoordinates(scx, scy);
	roiManager("deselect");
//	if(obj_class 
//	roiManager("select", final);
//	if(obj_class != "delete"){ // deleted blobjects could be printed
//checking object class creates a cue for what properties to call		
		if(obj_class == "blob"){
			prox_roi_indx = Roi.getProperty("foci1_index");
			prox_array_pos = Roi.getProperty("foci1_array pos");//3 is 					
			rev_status = Roi.getProperty("reverse");
			SC_array_length = Roi.getProperty("SC_array_length");
			distal_roi_indx = "NA";//since these variables are called for printing, 
			prox_f2C = "NA";//initialize this variable for printing
			distal_f2C ="NA";//they must be filled before the printing line.
			ifd = "NA";
			med_index = "NA";
			med_array_pos = "NA";
			ifd2 = "NA";
			mid_f2C = "NA";
			roiManager("select", final);
			PrintBivResults();
		//	File.close(f);
		}

		if(obj_class == "1CO"){	
			print("obj class is 1CO");
			roiManager("select", final);
			sc_index = Roi.getProperty("SC_index");
			prox_roi_indx = Roi.getProperty("foci1_index");
			prox_array_pos = Roi.getProperty("foci1_array_pos");
			rev_status = Roi.getProperty("reverse");
			SC_array_length = Roi.getProperty("SC_array_length");
			distal_roi_indx = "NA";
			distal_f2C ="NA";
			ifd = "NA";
			//med_index = "NA";
			mid_f2C = "NA";
			ifd2 = "NA";
			if(prox_array_pos != 0) {			
				prox_f2C = splineMeasure(sc_index, 0, prox_array_pos);
			}
			if(prox_array_pos == 0){
				print("prox_array_pos came up empty");//seems like there is a correlation with this 
//and printing spline and not blobject name
			}
			print("properties gathered ");
			print("printing stats on " + final);
			roiManager("select", final);
			PrintBivResults();
			//File.close(f);
			roiManager("deselect");
			}
			if(obj_class == "XY"){
				roiManager("select", final);
				rev_status = Roi.getProperty("reverse");
				mid_f2C = "NA";
				ifd2 = "NA";
				distal_roi_indx = "NA";
				distal_f2C ="NA";
				ifd = "NA";
				prox_roi_indx= "NA";
				prox_f2C= "NA";
				PrintBivResults();
			}
			if(obj_class == "2CO"){
			print("obj_class is 2CO");
			roiManager("select", final);
			prox_roi_indx = Roi.getProperty("foci1_index");
			prox_array_pos = Roi.getProperty("foci1_array_pos");
			distal_roi_indx = Roi.getProperty("foci2_index");
			distal_array_pos = Roi.getProperty("foci2_array_pos");
			SC_array_length = Roi.getProperty("SC_array_length");
			mid_f2C = "NA";
			ifd2 = "NA";
			wait(500);
			print("this is distal pos  " + distal_array_pos);
			print("this is the prox pos  " + prox_array_pos);
			if(abs( parseFloat(prox_array_pos)) > abs( parseFloat(distal_array_pos))){ //if I get the SCarray reverse and foci order correct, this loop won't be needed.
			print("heads up, points are wrong order.  pnt 1, "+ distal_array_pos+ " and pnt2, "+ prox_array_pos);
			}
			roiManager("select", final);
			sc_indx = Roi.getProperty("SC_index");
			rev_status = Roi.getProperty("reverse");
			prox_f2C = splineMeasure(sc_indx, 0, prox_array_pos);
			distal_f2C	= splineMeasure(sc_indx, 0, distal_array_pos);
			ifd = splineMeasure(sc_indx, prox_array_pos, distal_array_pos);
			roiManager("select", final);
			PrintBivResults();
		//	File.close(f);
			}
			
			if(obj_class == "3CO"){
			print("obj_class is 3CO");
			roiManager("select", final);
			prox_roi_indx = Roi.getProperty("foci1_index");
			prox_array_pos = Roi.getProperty("foci1_array_pos");
			distal_roi_indx = Roi.getProperty("foci2_index");
			distal_array_pos = Roi.getProperty("foci2_array_pos");
			
			mid_roi_indx = Roi.getProperty("foci3_index");
			mid_array_pos = Roi.getProperty("foci3_array_pos");
			
			SC_array_length = Roi.getProperty("SC_array_length");
			wait(500);
			print("this is distal pos  " + distal_array_pos);
			print("this is the prox pos  " + prox_array_pos);
			roiManager("select", final);
			sc_indx = Roi.getProperty("SC_index");
			rev_status = Roi.getProperty("reverse");
			prox_f2C = splineMeasure(sc_indx, 0, prox_array_pos);
			med_f2C = splineMeasure(sc_indx, 0, mid_array_pos);
			distal_f2C = splineMeasure(sc_indx, 0, distal_array_pos);
			ifd = splineMeasure(sc_indx, prox_array_pos, mid_array_pos);//prox to med
			ifd2 = splineMeasure(sc_indx, mid_array_pos, distal_array_pos); //med to distal
			
			roiManager("select", final);
			PrintBivResults();
		//	File.close(f);
			}				
}//end blobject loop
wait(700);
File.close(f);

function splineMeasure(sc, point1, point2){//make sure that 0 is first
	print("entering spline measure. pnt1: "+point1 + " pnt2: "+point2);
	roiManager("Select", sc);
	if(matches(Roi.getName(), ".*SC.*")) { // make sure the name is captitalized	
		print("SC is .." + sc);
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
		if( parseFloat(point1) > abs( parseFloat(point2))){ //if I get the SCarray reverse and foci order correct, this loop won't be needed.
			print("points are wrong order.  pnt 1, "+ point1+ " and pnt2, "+ point2);
			scx_trimd = Array.slice(Scpx, point2, point1);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point2, point1);
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");//splines must be added to RoiManager to measure 
			splineCount++;
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
			print("the results length " + RLength);
//			roiManager("delete");//commont out the delete and select new to remove the newly added apliens
//			roiManager("Select", 0);
			print("result length "+ RLength);
			return RLength;//i think the return Rlength should be at end of each loop
		}
		if(abs( parseFloat(point1)) < abs( parseFloat(point2))){
			print("points are correct order, pnt 1, "+ point1+ " and pnt2, "+ point2);
			scx_trimd = Array.slice(Scpx, point1, point2);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point1, point2);
			print("spliced array length " + scx_trimd.length);//spliced is empty
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");
			splineCount++;
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
			print("the results length " + RLength);
//			roiManager("delete");  // comment these out when macro starts behaving
//			roiManager("Select", 0);
			print("result length "+ RLength);
//print("second trim "+ scy_trimd.length);		
			return RLength;
		}
		else{
		print("ended Spline Measure without result");
		RLength = "NA";
		return RLength;
		}
	}//sc name
} // end of function

function PrintBivResults(){
	print(f, T+"\t" + Roi.getName() + "\t" 
	 		+ Roi.getProperty("SC_Results_length") + "\t"
			 + Roi.getProperty("SC_array_length")+"\t"
//error with prox_f2C
			 + "\t"	 + obj_class + "\t"	 + prox_roi_indx + "\t"+ prox_f2C + "\t"
			 + distal_roi_indx + "\t"+  distal_f2C + "\t" +mid_f2C + "\t"
			 + ifd + "\t" + ifd2 + "\t"
			 + rev_status);
			//File.close(f);
			wait(300);			
			roiManager("deselect");
			}//end function

