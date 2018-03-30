//
//  ButtonFunctions.cpp
//  MySampleApp
//
//  Created by Joshua Lippai on 4/24/16.
//  Copyright © 2016 Amazon. All rights reserved.
//

#include "ButtonFunctions.h"
#include "ClientClass.h"
#include <iostream>
#include <sys/time.h>
#include <stdio.h>
#include <cmath>

using namespace std;
//returns index of the location closest to according to ccordlat and coordlong
int inrange(double coordlat, double coordlong){
    int min_idx = 0;
    for (int i = 0; i < LOCATIONCOUNT; i++){
        if (distance_from_loc(i, coordlat, coordlong) < distance_from_loc(min_idx, coordlat, coordlong))
            min_idx = i;
    }
    return min_idx;
}

// Picks a question to display
int challenge(int* t1_sec, int* t1_usec){
    struct timeval t1;
    srand(time(NULL));
    int q = 1 + (rand() % 11);
    gettimeofday(&t1, NULL);
    *t1_sec = t1.tv_sec;
    *t1_usec = t1.tv_usec;
    return q;
}
// Runs when an answer is submitted; checks if correct and acts accordingly, including returning the time the answer was answered in
int answer_fallout(int response, int q, int t1_sec, int t1_usec, int locationID){
    if (response == q){
        struct timeval t2;
        gettimeofday(&t2, NULL);
        int milliseconds = (t2.tv_sec - t1_sec) * 1000 + (t2.tv_usec - t1_usec)/1000;
        return milliseconds;
    }
    else{
        freeze_loc(locationID);
        return -1;
    }
}

int get_current_time(){ // ADD
    struct timeval cur_time;
    gettimeofday(&cur_time, NULL);
    int timestamp = cur_time.tv_sec;
    return timestamp;
}