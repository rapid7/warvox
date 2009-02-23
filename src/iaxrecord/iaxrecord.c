/*
 * IAXRecord: a utility for recording audio on an outbound IAX call
 *
 * Copyright (C) 2009, H D Moore <hdm[at]metasploit.com>
 *
 * Based on simpleclient from the IAXClient distribution
 *
 * Copyright (C) 1999, Linux Support Services, Inc.
 *
 * Mark Spencer <markster@linux-support.net>
 *
 * This program is free software, distributed under the terms of
 * the GNU General Public License
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>

#include <iaxclient.h>

int initialized = 0;
int debug       = 0;

float silence_threshold = 0.0f;
int call_state  = 0;
int call_trace  = -1;
int call_done   = 0;
int call_bytes  = 0;
char *iax_out;
int reg_id;

void cleanup(void) {
	if ( reg_id ) {
		iaxc_unregister(reg_id);
		reg_id = 0;
	}
	if ( initialized ) {
		iaxc_stop_processing_thread();		
		iaxc_shutdown();
		initialized = 0;
	}
}

void signal_handler(int signum) {
	if ( signum == SIGTERM || signum == SIGINT ) {
		cleanup();
		exit(0);
	}
}

void usage(char **argv) {
	fprintf(stdout, "Usage: %s [server] [user] [pass] [cid] [output] [number] <seconds>\n", argv[0]);
	exit(1);
}
 
int state_event_callback(struct iaxc_ev_call_state call) {
	call_state = call.state;
    return 0;
}

int audio_event_callback( struct iaxc_ev_audio audio) {
	if(call_state & IAXC_CALL_STATE_COMPLETE) {
		if(call_trace == -1) call_trace = open(iax_out, O_CREAT|O_TRUNC|O_WRONLY, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
		if(call_trace != -1) {
			if(debug) printf("audio data: format=%d encoded=%d size=%d state=%d\n", audio.format, audio.encoded, audio.size, call_state);
			write(call_trace, audio.data, audio.size);
			call_bytes += audio.size;
		}
	}
	return 0;
}

int iaxc_callback(iaxc_event e) {
    switch(e.type) {
		case IAXC_EVENT_TEXT:
			return ( debug ? 0 : 1 );
			break;
        case IAXC_EVENT_STATE:
            return state_event_callback(e.ev.call);
			break;
		case IAXC_EVENT_AUDIO:
			return audio_event_callback(e.ev.audio);
			break;
        default:
            return 0;
			break;
    }
}

		
int main(int argc, char **argv) {

	char *iax_host;
	char *iax_user;
	char *iax_pass;
	char *iax_num;
	char *iax_cid;
	int iax_sec = 20;
	int call_id = 0;
	int i;
	char dest[1024];
	
	if(argc < 7) usage(argv);
	iax_host = argv[1];
	iax_user = argv[2];
	iax_pass = argv[3];
	iax_cid  = argv[4];
	iax_out  = argv[5];
	iax_num  = argv[6];
	
	if(argc > 7) iax_sec = atoi(argv[7]);

	snprintf(dest, sizeof(dest), "%s:%s@%s/%s", iax_user, iax_pass, iax_host, iax_num);
	iaxc_set_video_prefs(IAXC_VIDEO_PREF_CAPTURE_DISABLE | IAXC_VIDEO_PREF_SEND_DISABLE);
	iaxc_set_audio_prefs(IAXC_AUDIO_PREF_SEND_DISABLE);

	if(! debug) {
		fclose(stderr);
		stderr = fopen("/dev/null", "w");
	}
	
	fprintf(stdout, "STARTED %s BYTES=%d FILE=%s\n", iax_num, call_bytes, iax_out);
		
	/* activate the exit handler */
	atexit(cleanup);

	/* install signal handler to catch CRTL-Cs */
	signal(SIGINT, signal_handler);
	signal(SIGTERM, signal_handler);
			
	if ( iaxc_initialize(1) ) {
		fprintf(stdout, "error: Could not initialize iaxclient!\n");
		exit(0);
	}
	
	initialized = 1;

	iaxc_set_callerid ("", iax_cid);
	iaxc_set_formats(IAXC_FORMAT_ULAW | IAXC_FORMAT_ALAW, IAXC_FORMAT_ULAW | IAXC_FORMAT_ALAW);
	
	// Causes problems for some asterix servers, not sure why yet
	// iaxc_set_silence_threshold(silence_threshold);

	iaxc_set_event_callback(iaxc_callback);	
	iaxc_start_processing_thread();
	iaxc_set_audio_output(debug ? 0 : 1);
	
	iaxc_set_audio_prefs(IAXC_AUDIO_PREF_RECV_REMOTE_RAW);
	
	reg_id  = iaxc_register(iax_user, iax_pass, iax_host);
	if(debug) fprintf(stderr, " RegID: %d\n", reg_id);
	
	call_id = iaxc_call(dest);
	if(debug) fprintf(stderr, "CallID: %d\n", call_id);
	
	if(call_id >= 0) {
		iaxc_select_call(call_id);
		for(i=0; i< (iax_sec*1000*2); i+= 500) {
			if(iaxc_first_free_call() == call_id) break;
			iaxc_millisleep(500);
		}
	}

	fprintf(stdout, "COMPLETED %s BYTES=%d FILE=%s\n", iax_num, call_bytes, iax_out);
	return(0);
}
