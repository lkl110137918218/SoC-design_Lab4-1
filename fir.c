#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	for (int i = 0; i < N; i++) {
        inputbuffer[i] = 0;
        outputsignal[i] = 0;
    	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	//write down your fir
	for (int i = 0; i < N; i++) {
        // Update the input buffer by shifting values
        for (int j = N - 1; j > 0; j--) {
            inputbuffer[j] = inputbuffer[j - 1];
        }
        inputbuffer[0] = inputsignal[i];

        // Perform FIR filtering
        int result = 0;
        for (int j = 0; j < N; j++) {
            result += taps[j] * inputbuffer[j];
        }
        outputsignal[i] = result;
    	}
	return outputsignal;
}
		
