//
//  ClientClass.h
//  Alpha Terrier
//  Header file for ClientLocation and associated functions
//
#ifndef CLIENTCLASS_H
#ifdef __cplusplus
extern "C" {
#endif
    const int LOCATIONCOUNT = 4;
    
    int get_frz(int);
    
    void freeze_loc(int);
    
    void unfreeze_loc(int);
    
    bool still_frozen_loc(int);
    
    int get_latc(int);
    
    int get_longc(int);
    
    double distance_from_loc(int, double, double);
    
#ifdef __cplusplus
}
#endif
#endif