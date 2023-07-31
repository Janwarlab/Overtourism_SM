/**
* Name: Overtourism Santa Marta OVSM0
* Based on the internal template Road Traffic.
* The purpose of the model is to illustrate the spatial and temporal distribution of population and tourists in the
city of Santa Marta, according to different levels in the number of tourists who visit it, illustrating the moment
in which the city is in a situation of overtourism; and to analyze the results of proposed management strategies.
* It has four scenarios: 
* 1. Whitout strategies in OVSM0.
* 2. Growth in the number of touristic site (strategy 1 S1) in OVSM1.
* 3. Change of site to visit according to level of touristic density (strategy 2 S2) in OVSM2.
* 4. Mixed of S1 and S2 in OVSM3. 
* Author: Janwar Moreno
*/



model OVSMO

/* The purpose of the model is to illustrate the spatial and temporal distribution of population and tourists in the
city of Santa Marta, according to different levels in the number of tourists who visit it, illustrating the moment
in which the city is in a situation of overtourism; and to analyze the results of proposed management strategies.
* It has four scenarios: 
* 1. Whitout strategies in OVSM0.
* 2. Growth in the number of touristic site (strategy 1 S1) in OVSM1.
* 3. Change of site to visit according to level of touristic density (strategy 2 S2) in OVSM2.
* 4. Mixed of S1 and S2 in OVSM3. */


global {
// Shape inputs
file shape_file_MUNDO <- file("../includes/MUNDO.shp");
file shape_file_MZ <- file("../includes/MZZIT.shp");
file shape_file_ROAD <- file("../includes/ROAD.shp");
geometry shape <- envelope(shape_file_MUNDO);

// Time of each cycle in minutes
float step <-  1 #h;
 
// Model start time
date starting_date <- date("2018-01-01-06");


// Parameters for the resident species that recreate
int h_rec_start <- 7;
int h_rec_end <- 20;
int T_recreo <- 1;

// The minimum and maximum speed can be used by tourists and residents
float min_speed <- 1.0 #km / #h;
float max_speed <- 60.0 #km / #h;
float prom_vel <- 30.0 #km / #h; // The average speed of Santa Marta stimated by Roda(2012) was taken.

// Parameters for the ROAD
// Clean road
bool clean_data <- true;
float tolerance <- 30.0;
bool split_lines <- true;
bool reduce_to_main_connected_components;
list<list<point>> connected_components;
list<rgb>colors;
graph the_graph;

// Parameters for tourists
int MinTuristas <- 2033; // Lower limit of the tourists number from january 2018.
int MaxTuristas <- 3033; // Upper limit of the tourists number from january 2018.
int NTuristas <- rnd(MinTuristas,MaxTuristas); // This is the tourist number.
float Msize_group <- 3.786; // We will use NTuristas for residents who recreate.
int group <- int(NTuristas / Msize_group);
int min_in_start <- 5;
// The maximum entry is determined by the time of entry into the lodging
float P_DstaySM <- 3.71;
float Min_HstaySM <- 4.0;
float Max_DstaySM <- 15.0;
int Min_Hlodging <- 18;
int Max_Hlodging <- 23;
int Min_Hndrecreation <- 6;
int Max_Hndrecreation <- 10;
// Group size and probability (1=8%, 2= 25% ,3=33% ,4=17%,5=8% y 6=8%). Usaremos el mismo para residentes que se recrean
// SITUR: this distributio has an average group size = 3.79 with standar deviation = 0.34; this value is equivalent to 
// the average of the maximum group. 
list<int> lsizegroup <- [1,1,1,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,6,7,8,9,10];  

   
     // Parameters for blocks (MZ) with touristic use and public space
     float espput_pc <- 15.0; // Minimum square meters per person.
     list<MZ> LMZEP; // List of MZ of public space.
     list<float> LAMZEP; // List of areas of MZ with public space.
     float AMZEP; // Area of MZ with public space.
     list<MZ> LMSEP; // List of MZ that exceed the limits of public space.
     list<float> LAMSEP; // List of MZ´s area that exceed the limits of public space.
     
     int MZEP; // Number of MZ with public space.
     int MZSUPEP; // Number of MZ that exceed the limits of public space.
     float AMSEP; // Area of the MZ that exceed the limits of public space.
     
     
     float PSUPEP;
     float PASUPEP;
      // Stop the simulation at one year (365*24=8760 hours)
     reflex stop_simulation when: (cycle = 8760) {do pause;}
     
      reflex Espacio_p when: every (8760 #hour) {
     LMZEP <- MZ where (each.EP=1);
     MZEP <- length (LMZEP);
     LAMZEP <- LMZEP collect each.area;
     AMZEP <- sum(LAMZEP); // Total area of public space
     MZ5 <- MZ where (each.T5=1);}
     
     reflex renovar_mes when: every (780 #hour) {
      if (current_date.month=1){MinTuristas <- 2033; MaxTuristas <- 3033; P_DstaySM <- 3.71;
      lsizegroup <- [1,1,1,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,6,7,8,9,10];}
      else if (current_date.month=2){MinTuristas <- 1656; MaxTuristas <- 2656; P_DstaySM <- 5.61;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,3,4,5,6,7,8,9,10]; }
      else if (current_date.month=3){MinTuristas <- 1778; MaxTuristas <- 2778; P_DstaySM <- 5.07;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,3,4,4,4,4,5,6,7,8,9,10];}
      else if (current_date.month=4){MinTuristas <- 1721; MaxTuristas <- 2721; P_DstaySM <- 5.14;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,3,4,5,6,7,8,9,10];}
      else if (current_date.month=5){MinTuristas <- 1648; MaxTuristas <- 2648; P_DstaySM <- 4.9;
      lsizegroup <- [1,1,2,2,2,3,3,3,4,5,6,7,8,9,10];}
      else if (current_date.month=6){MinTuristas <- 2217; MaxTuristas <- 3217; P_DstaySM <- 5.25;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,3,4,5,6,7,8,9,10];}
      else if (current_date.month=7){MinTuristas <- 2309; MaxTuristas <- 3309; P_DstaySM <- 4.45;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,4,4,5,6,7,8,9,10]; }
      else if (current_date.month=8){MinTuristas <- 2249; MaxTuristas <- 3249; P_DstaySM <- 5.23;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,3,4,5,6,7,8,9,10];}
      else if (current_date.month=9){MinTuristas <- 2193; MaxTuristas <- 3193; P_DstaySM <- 4.34;
      lsizegroup <- [1,1,2,2,2,3,3,3,4,5,6,7,8,9,10];   }
      else if (current_date.month=10){MinTuristas <- 2331; MaxTuristas <- 3331; P_DstaySM <- 4.75;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,7,8,9,10];     }
      else if (current_date.month=11){MinTuristas <- 2962; MaxTuristas <- 3962; P_DstaySM <- 4.77;
      lsizegroup <- [1,1,1,2,2,2,3,3,3,4,4,4,4,5,5,5,5,5,6,7,8,9,10];     }
      else if (current_date.month=12){MinTuristas <- 3471; MaxTuristas <- 4471; P_DstaySM <- 6.18;}
          lsizegroup <- [1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,5,5,6,6,6,6,6,6,7,8,9,10];     }
             
     reflex sup_ep {
      LMSEP <- LMZEP where (each.EPP_t<espput_pc);
      MZSUPEP <- length(LMSEP);
      PSUPEP <- (MZSUPEP / MZEP)*100; // Porcentaje
      LAMSEP <- LMSEP collect each.area;
        AMSEP <- sum(LAMSEP);
        PASUPEP <- (AMSEP/ AMZEP)*100;}
     
           
       
 // Global informatio of the city
 
 // Area of the world in square kilometers
 float AREA <- 358.050202; // World
   // Area of ZIT in square kilometers
 float AREACH <- 1.265969; float AREARD <- 1.314046; float AREASG <- 0.624201; float AREAMT <- 0.389845; float AREAPC <- 1.043762;
 float AREABEHO <- 0.692048; float AREADJ <- 1.452585; float AREACT <- 0.541947; float AREATAGA <- 1.500178; float AREAMC <- 0.786624;
 
 
  list<MZ> MZCH; list<MZ> MZRD; list<MZ> MZSG; list<MZ> MZMT; list<MZ> MZPC; list<MZ> MZBEHO;
  list<MZ> MZDJ; list<MZ> MZCT; list<MZ> MZTAGA; list<MZ> MZMC;
 
 reflex Def_ZIT when: every (8760 #hour) {
 // Agents in ZIT
  // MZ for ZIT
  MZCH <- MZ where (each.CH=1); MZRD <- MZ where (each.RD=1); MZSG <- MZ where (each.SG=1); MZMT <- MZ where (each.MT=1);
  MZPC <- MZ where (each.PC=1); MZBEHO <- MZ where (each.BEHO=1); MZDJ <- MZ where (each.DJ=1); MZCT <- MZ where (each.CT=1);
  MZTAGA <- MZ where (each.TAGA=1); MZMC <- MZ where (each.MC=1);}
       
 // Population density in each step by ZIT (in square kilometers)
 
       // List of agents by ZIT
       list<int> LINCH <- MZCH collect each.agent_in update: MZCH collect each.agent_in;
       list<int> LINRD <- MZRD collect each.agent_in update: MZRD collect each.agent_in;
       list<int> LINSG <- MZSG collect each.agent_in update: MZSG collect each.agent_in;
       list<int> LINMT <- MZMT collect each.agent_in update: MZMT collect each.agent_in;
       list<int> LINPC <- MZPC collect each.agent_in update: MZPC collect each.agent_in;
       list<int> LINBEHO <- MZBEHO collect each.agent_in update: MZBEHO collect each.agent_in;
       list<int> LINDJ <- MZDJ collect each.agent_in update: MZDJ collect each.agent_in;
       list<int> LINCT <- MZCT collect each.agent_in update: MZCT collect each.agent_in;
       list<int> LINTAGA <- MZTAGA collect each.agent_in update: MZTAGA collect each.agent_in;
       list<int> LINMC <- MZMC collect each.agent_in update: MZMC collect each.agent_in;
       
       // Total density by ZIT hours
       float DP_CH <- sum(LINCH) / AREACH update: sum(LINCH) / AREACH;
       float DP_RD <- sum(LINRD) / AREARD update: sum(LINRD) / AREARD;
       float DP_SG <- sum(LINSG) / AREASG update: sum(LINSG) / AREASG;
       float DP_MT <- sum(LINMT) / AREAMT update: sum(LINMT) / AREAMT;
       float DP_PC <- sum(LINPC) / AREAPC update: sum(LINPC) / AREAPC;
       float DP_BEHO <- sum(LINBEHO) / AREABEHO update: sum(LINBEHO) / AREABEHO;
       float DP_DJ <- sum(LINDJ) / AREADJ update: sum(LINDJ) / AREADJ;
       float DP_CT <- sum(LINCT) / AREACT update: sum(LINCT) / AREACT;
       float DP_TAGA <- sum(LINTAGA) / AREATAGA update: sum(LINTAGA) / AREATAGA;
       float DP_MC <- sum(LINMC) / AREAMC update: sum(LINMC) / AREAMC;
       
           
  // Cumulative density by ZIT (Accumulated visits/ area ZIT)
 
  // Tourists by ZIT
       list<int> LTCH <- MZCH collect each.TOURIST_INTS update: MZCH collect each.TOURIST_INTS;
       list<int> LTRD <- MZRD collect each.TOURIST_INTS update: MZRD collect each.TOURIST_INTS;
       list<int> LTSG <- MZSG collect each.TOURIST_INTS update: MZSG collect each.TOURIST_INTS;
       list<int> LTMT <- MZMT collect each.TOURIST_INTS update: MZMT collect each.TOURIST_INTS;
       list<int> LTPC <- MZPC collect each.TOURIST_INTS update: MZPC collect each.TOURIST_INTS;
       list<int> LTBEHO <- MZBEHO collect each.TOURIST_INTS update: MZBEHO collect each.TOURIST_INTS;
       list<int> LTDJ <- MZDJ collect each.TOURIST_INTS update: MZDJ collect each.TOURIST_INTS;
       list<int> LTCT <- MZCT collect each.TOURIST_INTS update: MZCT collect each.TOURIST_INTS;
       list<int> LTTAGA <- MZTAGA collect each.TOURIST_INTS update: MZTAGA collect each.TOURIST_INTS;
       list<int> LTMC <- MZMC collect each.TOURIST_INTS update: MZMC collect each.TOURIST_INTS;
 
       // Cumulative Density_wt by ZIT
       
       float DPA_CH <- sum(LTCH) /AREACH update:sum(LTCH) /AREACH;
       float DPA_RD <- sum(LTRD) /AREARD update:sum(LTRD) /AREARD;
       float DPA_SG <- sum(LTSG) /AREASG update:sum(LTSG) /AREASG;
       float DPA_MT <- sum(LTMT) /AREAMT update:sum(LTMT) /AREAMT;
       float DPA_PC <- sum(LTPC) /AREAPC update:sum(LTPC) /AREAPC;
       float DPA_BEHO <- sum(LTBEHO) /AREABEHO update:sum(LTBEHO) /AREABEHO;
       float DPA_DJ <- sum(LTDJ) /AREADJ update:sum(LTDJ) /AREADJ;
       float DPA_CT <- sum(LTCT) /AREACT update:sum(LTCT) /AREACT;
       float DPA_TAGA <- sum(LTTAGA) /AREATAGA update:sum(LTTAGA) /AREATAGA;
       float DPA_MC <- sum(LTMC) /AREAMC update:sum(LTMC) /AREAMC;
       
       
       
// Total tourists in the top 5 attractions, for concentration indicator
 list<MZ> MZ5 <- MZ where (each.T5=1);
 int TT5_stock;
 list<int> LTT5_fi;
 list<int> LStock_visitas<- MZ collect (each.TOURIST_INTS);
 int Stock_visitas <- sum (LStock_visitas);
 
 
 int TuristasIN_stock <- 1;
 int TuristasIN_fi;
 float DPV_stock;
 float DPV_fi;
 float APV_fi;
 float APV_stock;
 float APV_stockT <- float(RES_ti);
 
 // Total residents in each period: residents are assumed to remain constant
 int RES_ti <- 453527;
 
 
// Area in square meters of the 20 attractions according to TRIP Advisor
 float TATOP20 <- 597119.346;
 
 
  // Algorithm for daily aggregate indicators (cut of 1:00 a.m.)
    // Gross calculation
   reflex change_NTUR when: current_date.hour = 1 {
       list<TURISTAS> turistas_noc <- TURISTAS where (each.counted=false);
       list<int> NewTuristas <- turistas_noc collect each.size_group;
       TuristasIN_fi <- sum(NewTuristas);
       TuristasIN_stock <- TuristasIN_stock + TuristasIN_fi;
       
       
         // Added dayly diagnostic indicators
               
       // to calculate DPV
       list<float> NewDPV <- turistas_noc collect each.DPV_i;
       DPV_fi <- sum(NewDPV);
       DPV_stock <- DPV_stock + DPV_fi;
       APV_fi <- DPV_fi/365;
       APV_stock <- (DPV_stock/365) + APV_fi;
       APV_stockT <- APV_stock + RES_ti;      
       intensidad_wt <- TuristasIN_stock / RES_ti;
       intensidad_OVSM <- APV_stock / RES_ti;
       densidad_wt <- TuristasIN_stock / (TATOP20/1000000); // Km2
       densidad_OVSM <- APV_stock / AREA;
       ask TURISTAS {counted <- true;}} // End daily reflex
           
// Daily diagnostic indicators
float intensidad_wt;
float intensidad_pt;
float intensidad_OVSM;
float densidad_wt;
float densidad_pt;
float densidad_OVSM;
float concentracion_wt;


// To Graph
  // Intensity wt
float intensidad_wt1 <- 1.0; float intensidad_wt2 <- 1.7; float intensidad_wt3 <- 2.7; float intensidad_wt4 <- 5.3;
// Intensity pt
float intensidad_pt1 <- 3.18; float intensidad_pt2 <- 4.49; float intensidad_pt3 <- 6.3; float intensidad_pt4 <- 9.58;
// Density wt
float densidad_wt1 <- 75000.0; float densidad_wt2 <- 200000.0; float densidad_wt3 <- 475000.0; float densidad_wt4 <- 930000.0;
// Density pt
float densidad_pt1 <- 407.0; float densidad_pt2 <- 719.0; float densidad_pt3 <- 1174.0; float densidad_pt4 <- 2278.0;
// Concentration wt
float concentracion_wt1 <- 22.0; float concentracion_wt2 <- 28.0; float concentracion_wt3 <- 32.0; float concentracion_wt4 <- 36.0;



// Groups in lodgings to stimate lodging night
int QY_stock <- 0;
int Qy <- 0;
// Group number staying.  
reflex time_to_reserving when: current_date.hour = 17 {
list<TURISTAS> LQY <- TURISTAS where (each.objective="lodging");
list<int> LsQY <- LQY collect each.size_group;
Qy <- sum(LsQY);
QY_stock <- QY_stock + Qy;
// Daily diagnostic indicators
intensidad_pt <- QY_stock / RES_ti;  
densidad_pt <- QY_stock / AREA; // Km2

// To calculate concentratio
        LTT5_fi <- MZ5 collect each.TOURIST_INTS; // Sum of visits in the top 5.
        TT5_stock <- sum(LTT5_fi);
        LStock_visitas <- MZ collect (each.TOURIST_INTS);
        Stock_visitas <- sum (LStock_visitas);
       
            // Concentration
            concentracion_wt <- (TT5_stock / Stock_visitas)*100;} // End reflex time_to_ reserving
 
init {
create MZ from: shape_file_MZ with: [INOUT::int(read("INOUT")), LODGING::int(read("VTZITHB")), UT::int(read("UT")), AT::int(read("AT")), Playa::int(read("Playa")),
Parque::int(read("Parque")), SN::int(read("SN")), EPCH::int(read("EPCH")), Comercial::int(read("Comercial")), ROD::int(read("ROD")), BH::int(read("BH")),
PB::int(read("PB")), TG::int(read("TG")), EP::int(read("EP")), T20::int(read("T20")), T5::int(read("T5")), Personas::int(read("Personas")), area::float(read("AREA")), CH::int(read("MZZIT0")), RD::int(read("MZZIT1")), SG::int(read("MZZIT2")), MT::int(read("MZZIT3")),
PC::int(read("MZZIT4")), BEHO::int(read("MZZIT5")), DJ::int(read("MZZIT6")), CT::int(read("MZZIT9")), TAGA::int(read("MZZIT10")), MC::int(read("MZZIT11"))]
{if (UT=1) {color <- #green;}}

 //Create roads
list<geometry> clean_lines <- clean_data ? clean_network (shape_file_ROAD.contents,tolerance,split_lines,reduce_to_main_connected_components) : shape_file_ROAD.contents;
create ROAD from: clean_lines;
the_graph <- as_edge_graph(ROAD);


// Lista of lodging sit
list<MZ> lodgings <- MZ where (each.LODGING=1);

// Taking into account the distribution by beaches of ProRodadero, the lists are generated
// Rodadero beach 240 times
list<MZ> SITSRD <- MZ where (each.ROD=1);
list<MZ> Rodadero <-
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD;

// Playa Blanca
list<MZ> SITSPB <- MZ where (each.PB=1);
list<MZ> Playa_blanca <-
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB;

// Playa Bello Horizonte
list<MZ> SITSBH <- MZ where (each.BH=1);
list<MZ> Bello_horizonte <-
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH +
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH;

// Playa de Taganga
list<MZ> SITSTG <- MZ where (each.TG=1);
list<MZ> Taganga <-
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG;

// List of beaches
list<MZ> SITSPBR <- MZ where (each.UT=1 and each.Playa=1);
list<MZ> SITSPN <- SITSPBR - SITSRD - SITSPB - SITSTG; // Lista de playas que excluye a las contadas arriba, evita doble registro.
list<MZ> playas <- SITSPN + SITSPN + SITSPN + SITSPN + SITSPN;

// Lista de sitios culturales e históricos
list<MZ> SITSHM <- MZ where (each.UT=1 and each.EPCH=1);
list<MZ> SITSH <- SITSHM + SITSHM + SITSHM;

// Lista de sitios comerciales (como centros comerciales)
list<MZ> SITSCOM <- MZ where (each.UT=1 and each.Comercial=1);

// Lista de Sitios Naturales
list<MZ> SITSSN <- MZ where (each.UT=1 and each.SN=1);
list<MZ> SNAT <- SITSSN + SITSSN;

// Parques
list<MZ> Parques <- MZ where (each.UT=1 and each.Parque=1);


/*  Generar lista de lugares a visitar
Es la lista que agrega todos los sitios: con mayores probabilidades para los que más se repiten según
 información observada en situr-Magdalena
 Parametros para SIT
 Parametro peso de visitas (información usada para ponderar los sitios y el lugar de visita)
 
 * Para las playas identificar:
 * Rodadero= 48
 * Playa blanca=9
 * Bello Horizonte = 4
 * Taganga = 5;
 * Otras playas = 15;
 EPCH <- 8;
 Parque Naturales, cascadas y rios SN <- 7: esto es para asignar a Minca
 Calles y parques <- 2;
 CC <- 1;
*/

list MZSITS <- Rodadero + Playa_blanca + Bello_horizonte + Taganga + playas + SITSH + SITSCOM + SNAT + Parques;


create TURISTAS number: group {
speed <- truncated_gauss(prom_vel, min_speed, max_speed);
IN_place <- one_of (MZ where (each.INOUT=1));
lodging_place <- one_of(lodgings);
objective <- "recreation";
location <- any_location_in (IN_place);
hstaySM <- truncated_gauss(P_DstaySM*24, Min_HstaySM, Max_DstaySM*24);
hinlodging <- rnd(Min_Hlodging,Max_Hlodging);
startin <- rnd(min_in_start, hinlodging-1);
startout <- startin + hstaySM;
hnd_recreation <- rnd(Min_Hndrecreation,Max_Hndrecreation);
SIT_place <- one_of (MZSITS);
hrest_goout <- startout;
size_group <- one_of(lsizegroup);
counted <- false;
DPV_i <- (hstaySM * size_group)/24;
} // Cierra el init de turistas
} // Terminan el init global
 
 
reflex new_tourist when: current_date.hour = 23 {
NTuristas <- rnd(MinTuristas,MaxTuristas);
group <- int(NTuristas / Msize_group);

create TURISTAS number: group {
speed <- truncated_gauss(prom_vel, min_speed, max_speed);
IN_place <- one_of (MZ where (each.INOUT=1));
lodging_place <- one_of (MZ where (each.LODGING=1));
objective <- "recreation";
location <- any_location_in (IN_place);
// todo se pasa a horas
hstaySM <- truncated_gauss(P_DstaySM*24, (P_DstaySM*24) - Min_HstaySM, Max_DstaySM*24);
hinlodging <- rnd(Min_Hlodging,Max_Hlodging);
startin <- rnd(min_in_start, hinlodging-1);
startout <- startin + hstaySM;
hnd_recreation <- rnd(Min_Hndrecreation,Max_Hndrecreation);
counted <- false;

// Playa Rodadero
list<MZ> SITSRD <- MZ where (each.ROD=1);
list<MZ> Rodadero <-
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD;

// Playa Blanca
list<MZ> SITSPB <- MZ where (each.PB=1);
list<MZ> Playa_blanca <-
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB;

// Playa Bello Horizonte
list<MZ> SITSBH <- MZ where (each.BH=1);
list<MZ> Bello_horizonte <-
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH +
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH;

// Playa de Taganga
list<MZ> SITSTG <- MZ where (each.TG=1);
list<MZ> Taganga <-
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG;

// Lista de Playas
list<MZ> SITSPBR <- MZ where (each.UT=1 and each.Playa=1);
list<MZ> SITSPN <- SITSPBR - SITSRD - SITSPB - SITSTG; // Lista de playas que excluye a las contadas arriba, evita doble registro.
list<MZ> playas <- SITSPN + SITSPN + SITSPN + SITSPN + SITSPN;

// Lista de sitios culturales e históricos
list<MZ> SITSHM <- MZ where (each.UT=1 and each.EPCH=1);
list<MZ> SITSH <- SITSHM + SITSHM + SITSHM;

// Lista de sitios comerciales (como centros comerciales)
list<MZ> SITSCOM <- MZ where (each.UT=1 and each.Comercial=1);

// Lista de Sitios Naturales
list<MZ> SITSSN <- MZ where (each.UT=1 and each.SN=1);
list<MZ> SNAT <- SITSSN + SITSSN;

// Parques
list<MZ> Parques <- MZ where (each.UT=1 and each.Parque=1);


list MZSITS <- Rodadero + Playa_blanca + Bello_horizonte + Taganga + playas + SITSH + SITSCOM + SNAT + Parques;

SIT_place <- one_of (MZSITS);
hrest_goout <- startout;
size_group <- one_of(lsizegroup);
DPV_i <- (hstaySM * size_group)/24;
} } // Cierra el reflex new_tourist
} // Cierra el global

species MZ {
int Personas min:1; // Número de personas residentes en la MZ
int INOUT;
int LODGING;
int EP; // Espacio Público = 1
float area; // Esta en metros cuadrados.
float DP_0 <- Personas / area;
float DP_t <- agent_in / area update: agent_in / area; // Densidad poblacional en cada periodo
float EPP_t <- 1/DP_t update: 1/DP_t;

float delta_DP <- DP_t / DP_0 update: DP_t / DP_0;
rgb color <- #green  ;

// ZIT
int CH; int RD; int SG; int MT; int PC; int BEHO; int DJ; int CT; int TAGA; int MC;

// Información de los residentes que se mueven por recreación
int NR_REC <- int(Personas*(T_recreo/100)) min: 0; // Población que se mueve por recreación
int group_RREC <- int(NR_REC / Msize_group);
int AT;
int UT;
int Playa;
int Parque;
int SN;
int EPCH;
int Comercial;
int ROD;
int BH;
int PB;
int TG;
int T20;
int T5;

// Número de residentes que no se mueven por recreación
 int NR_NOREC <- Personas - NR_REC;
 
// Número de turistas en cada manzana para densidad poblacional en cada periodo
int TOURIST_IN min:0;

// Para Concentración se suma el stock de visitas al lugar

int TOURIST_INTS;


int agent_in <- TOURIST_IN + NR_REC + NR_NOREC update: TOURIST_IN + NR_REC + NR_NOREC; // Agentes en la MZ

aspect base {draw shape color: delta_DP <= 1 ? color: (delta_DP <= 3 ? #yellow: (delta_DP <= 100 ? #orange:#red)) border: #green;}

init {

create R_REC number: group_RREC {
color <- #red;
 size_groupRR <- one_of (lsizegroup);
 speed <- truncated_gauss(prom_vel, min_speed, max_speed);
start_rec <- rnd(h_rec_start, h_rec_end - 1);
end_rec <- rnd(start_rec, h_rec_end);
living_place <- host;
SIT_placeD <- one_of (MZ where (each.UT=1));
objective <- "resting";
location <- any_location_in (living_place);}}

species R_REC skills: [moving]{
int size_groupRR <- one_of (lsizegroup) update: one_of (lsizegroup);
rgb color <- #red;
MZ living_place <- nil;
MZ SIT_placeD <- one_of (MZ where (each.UT=1));
reflex change_SIT when: current_date.hour=4 {
SIT_placeD <- one_of (MZ where (each.UT=1));}

int start_rec;
int end_rec;
string objective;
point the_target <- nil;

reflex time_to_rec when: current_date.hour = start_rec and objective = "resting" {objective <- "recreating";
the_target <- any_location_in (SIT_placeD);
ask SIT_placeD {
NR_REC <- NR_REC + myself.size_groupRR;}
ask living_place {
NR_REC <- NR_REC - myself.size_groupRR;}}

reflex time_to_go_home when: current_date.hour = end_rec and objective = "recreating"{objective <- "resting";
the_target <- any_location_in (living_place);
ask living_place {
NR_REC <- NR_REC + myself.size_groupRR;}
ask SIT_placeD {
NR_REC <- NR_REC - myself.size_groupRR;}}

reflex move when: the_target != nil {
path path_followed <- goto(target: the_target, on:the_graph, return_path:true);
list<geometry> segments <- path_followed.segments;
if the_target = location {the_target <- nil;}}
aspect base {draw circle (size_groupRR) color: color border: #black;}}



} // Termina MZ

species ROAD  {
rgb color <- #black;
aspect base {
draw shape color: color ;
}
}


species TURISTAS skills:[moving]{
rgb color <- #blue;
int size_group;
MZ IN_place;
MZ lodging_place;
MZ SIT_place;
float hstaySM;
int hinlodging;
int startin;
float startout;
float hrest_goout min:0.0 max: startout update: hrest_goout - 1;
string objective;
int hnd_recreation;
point the_target <- nil;
bool counted;
float DPV_i;

reflex new_SIT when: current_date.hour = 4 {
// Playa Rodadero
list<MZ> SITSRD <- MZ where (each.ROD=1);
list<MZ> Rodadero <-
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD +
SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD + SITSRD;

// Playa Blanca
list<MZ> SITSPB <- MZ where (each.PB=1);
list<MZ> Playa_blanca <-
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB +
SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB + SITSPB;

// Playa Bello Horizonte
list<MZ> SITSBH <- MZ where (each.BH=1);
list<MZ> Bello_horizonte <-
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH +
SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH + SITSBH;

// Playa de Taganga
list<MZ> SITSTG <- MZ where (each.TG=1);
list<MZ> Taganga <-
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG + SITSTG +
SITSTG + SITSTG + SITSTG + SITSTG + SITSTG;

// Lista de Playas
list<MZ> SITSPBR <- MZ where (each.UT=1 and each.Playa=1);
list<MZ> SITSPN <- SITSPBR - SITSRD - SITSPB - SITSTG; // Lista de playas que excluye a las contadas arriba, evita doble registro.
list<MZ> playas <- SITSPN + SITSPN + SITSPN + SITSPN + SITSPN;

// Lista de sitios culturales e históricos
list<MZ> SITSHM <- MZ where (each.UT=1 and each.EPCH=1);
list<MZ> SITSH <- SITSHM + SITSHM + SITSHM;

// Lista de sitios comerciales (como centros comerciales)
list<MZ> SITSCOM <- MZ where (each.UT=1 and each.Comercial=1);

// Lista de Sitios Naturales
list<MZ> SITSSN <- MZ where (each.UT=1 and each.SN=1);
list<MZ> SNAT <- SITSSN + SITSSN;

// Parques
list<MZ> Parques <- MZ where (each.UT=1 and each.Parque=1);

list MZSITS <- Rodadero + Playa_blanca + Bello_horizonte + Taganga + playas + SITSH + SITSCOM + SNAT + Parques;

SIT_place <- one_of (MZSITS);
}

reflex time_to_recreation when: current_date.hour = startin and objective = "recreation" {
if (hrest_goout>=24){objective <- "lodging";} else if (hrest_goout<24){objective <- "goout";}
the_target <- any_location_in (SIT_place);
ask SIT_place {TOURIST_IN <- TOURIST_IN + myself.size_group;
TOURIST_INTS <- TOURIST_INTS + myself.size_group;
}}


reflex time_to_out when: hrest_goout = 0.0 and objective = "ndrecreation" {
objective <- "bye";
the_target <- any_location_in (IN_place);
ask lodging_place {TOURIST_IN <- TOURIST_IN - myself.size_group;}
}

reflex time_to_out when: hrest_goout = 0.0 and objective = "goout" {
objective <- "bye";
the_target <- any_location_in (IN_place);
ask SIT_place {TOURIST_IN <- TOURIST_IN - myself.size_group;}
}

reflex time_to_lodging when: current_date.hour = hinlodging and objective ="lodging" {
objective <- "ndrecreation";
the_target <- any_location_in (lodging_place);
ask lodging_place {TOURIST_IN <- TOURIST_IN + myself.size_group;}
ask SIT_place {TOURIST_IN <- TOURIST_IN - myself.size_group;}
}

reflex time_to_ndrecreation when: current_date.hour = hnd_recreation and objective ="ndrecreation"{
if (hrest_goout>=24){objective <- "lodging";} else if (hrest_goout<24){objective <- "goout";}
the_target <- any_location_in (SIT_place);
ask SIT_place {TOURIST_IN <- TOURIST_IN + myself.size_group;
TOURIST_INTS <- TOURIST_INTS + myself.size_group;}
ask lodging_place {TOURIST_IN <- TOURIST_IN - myself.size_group;}
}


reflex move when: the_target !=nil {
path path_followed <- goto(target: the_target, on:the_graph, return_path: true);
list<geometry> segments <- path_followed.segments;
if the_target = location {
the_target <- nil;}}


reflex die when: objective = "bye" and the_target = nil {
do die;
}

aspect base {draw circle (size_group) color: color border: #black;
}}

experiment OVSME0 type: gui {
   
    // Parametros de residentes
    parameter "Tasa de Recreo:" var: T_recreo category: "Residentes" min:0 max:100;  
   
    // Parametros de turistas
    parameter "Max_EP_Turista" var: espput_pc category: "Turistas" min:0.0;
   
    // Parametro Intervalo Turistas
   parameter "Mínimo N Turistas" var: MinTuristas category: "Turistas";
   parameter "Máximo N Turistas" var: MaxTuristas category: "Turistas";
   
    output {  
         
    display Santa_Marta type: java2D {
    species MZ transparency: 0.5 aspect: base {species R_REC aspect: base;}
    species ROAD aspect: base;
    species TURISTAS aspect:base;
    }
 
layout #split toolbars: false;      

display Turistas_fi refresh: every(24#h){chart "Turistas_fi" type: series background: #white
{data "Turistas_fi" value: TuristasIN_fi color: #black; } }
display Intensidad_wt refresh: every(24#h){chart "Intensidad_wt" type: series background: #white
{data "Intensidad_wt" value: intensidad_wt color:#blue;
data "Q1" value: intensidad_wt1 color: #green;
data "Q2" value: intensidad_wt2 color: #yellow;
data "Q3" value: intensidad_wt3 color: #orange;
data "Q4" value: intensidad_wt4 color: #red;}}


display Intensidad_pt refresh: every(24#h){chart "Intensidad_pt" type: series background: #white
{data "Intensidad_pt" value: intensidad_pt color:#blue;
data "Q1" value: intensidad_pt1 color: #green;
data "Q2" value: intensidad_pt2 color: #yellow;
data "Q3" value: intensidad_pt3 color: #orange;
data "Q4" value: intensidad_pt4 color: #red;}}
display Densidad_wt refresh: every(24#h){chart "Densidad_wt" type: series background: #white
{data "Densidad_wt" value: densidad_wt color:#blue;
data "Q1" value: densidad_wt1 color: #green;
data "Q2" value: densidad_wt2 color: #yellow;
data "Q3" value: densidad_wt3 color: #orange;
data "Q4" value: densidad_wt4 color: #red;}}
display Densidad_pt refresh: every(24#h){chart "Densidad_pt" type: series background: #white
{data "Densidad_pt" value: densidad_pt color:#blue;
data "Q1" value: densidad_pt1 color: #green;
data "Q2" value: densidad_pt2 color: #yellow;
data "Q3" value: densidad_pt3 color: #orange;
data "Q4" value: densidad_pt4 color: #red;}}

display Concentracion_wt refresh: every(24#h){chart "Concentración_wt" type: series background: #white
{data "Concentración_wt" value: concentracion_wt color:#blue;
data "Q1" value: concentracion_wt1 color: #green;
data "Q2" value: concentracion_wt2 color: #yellow;
data "Q3" value: concentracion_wt3 color: #orange;
data "Q4" value: concentracion_wt4 color: #red;}}

display MZ_SUPEP {chart "Porcentaje de MZ y áreas por debajo del LCA" type:series background: #white
{data "% MZ_SEP" value: PSUPEP color: #green;
data " % A_MZ_SEP" value: PASUPEP color: #blue;}}

 
display DPZIT {chart "Densidad por horas (Personas / KM^2)" type: series background: #white
{data "CH" value: DP_CH color: #green;
data "RD" value: DP_RD color: #yellow;
data "SG" value: DP_SG color: #orange;
data "MT" value: DP_MT color: #red;
data "PC" value: DP_PC color: #black;
data "BEHO" value: DP_BEHO color: #lime;
data "DJ" value: DP_DJ color: #slategrey;
data "CT" value: DP_CT color: #cornflowerblue;
data "TAGA" value: DP_TAGA color: #indigo;
data "MC" value: DP_MC color: #teal;}}

}}