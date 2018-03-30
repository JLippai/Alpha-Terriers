// Alpha Terrier
// ClientLocation class
// stores all information about a specific location (building)
// Including frozen status of client at the location
// As well as methods for adjusting these properties


#include <iostream>
#include <sys/time.h>
#include <stdio.h>
#include <array>
#include <cmath>
#include "ClientClass.h"
using namespace std;

//  ClientLocation class is instantiated with the coordinates of the building and has the ability to be frozen and unfrozen;
//  it keeps track of timestamps to enable unfreezing after two minutes, and it has built in functions for calclating the distance from the building's location using GPS coordinates
class ClientLocation
{
public:
    ClientLocation(const double& x, const double& y){
        frz_start = -1;
        lat = x;
        longt = y;
    }
    
    //getters
    
    
    long int get_frztime(){
        return frz_start;
    }
    
    int get_lat(){
        return lat;
    }
    int get_long(){
        return longt;
    }
    
    // "setters" - note that a frz_time of -1 is equivalent to not being frozen at the location
    void freeze(){
        struct timeval cur_time;
        gettimeofday(&cur_time, NULL);
        int timestamp = cur_time.tv_sec;
        frz_start = timestamp;
    }
    void unfreeze(){
        frz_start = -1;
    }
    bool still_frozen(){
        struct timeval cur_time;
        gettimeofday(&cur_time, NULL);
        return (cur_time.tv_sec - frz_start) < 120;
    }
    
    double distance_from(const double& latcoord, const double& longcoord) const{
        return sqrt((lat-latcoord)*(lat-latcoord) + (longt-longcoord)*(longt-longcoord));
    }
    
private:
    int frz_start; // timeofday format
    double lat;
    double longt;
};

// Each location is instantiated here
ClientLocation pho(42.349324, -71.106176);
ClientLocation epc(42.349899, -71.107995);
ClientLocation gsu(42.350852, -71.108848);
ClientLocation cas(42.350460, -71.105742);

// We sto
array<ClientLocation*, LOCATIONCOUNT> locationArray = {&pho, &epc, &gsu, &cas};


// Functions invoking the ClientLocation methods for a specified object pointed to in locationArray - this is what is visible to the rest of the program through Objective C through the header file


int get_frz(int locationID){
    return locationArray[locationID]->get_frztime();
}

void freeze_loc(int locationID){
    locationArray[locationID]->freeze();
}

void unfreeze_loc(int locationID){
    locationArray[locationID]->unfreeze();
}

bool still_frozen_loc(int locationID){
    return locationArray[locationID]->still_frozen();
}

int get_latc(int locationID){
    return locationArray[locationID]->get_lat();
}

int get_longc(int locationID){
    return locationArray[locationID]->get_long();
}

double distance_from_loc(int locationID, double latcoord, double longcoord){
    return locationArray[locationID]->distance_from(latcoord, longcoord);
}