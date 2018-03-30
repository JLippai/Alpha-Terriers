//
//  ButtonFunctions.h
//  Alpha Terrier
//
//  Header file for functions in ButtonFunctions.cpp
#ifndef BUTTONFUNCTIONS_H
#ifdef __cplusplus
extern "C" {
#endif
    int inrange(double, double);
    
    int challenge(int*, int*);
    
    int answer_fallout(int, int, int, int, int);
    
    int get_current_time();
    
#ifdef __cplusplus
}
#endif
#endif