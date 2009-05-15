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
#include <time.h>
#include <signal.h>

#include <iaxclient.h>

int initialized = 0;
int debug       = 0;
int audio       = 0;
int busy        = 0;
int fail        = 1;

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
	fprintf(stdout, "Usage: %s -s [server] -u [user] -p <pass> -o [output] -n [number] -c <callerid> -l <seconds> [-D]\n", argv[0]);
	exit(1);
}
 
int state_event_callback(struct iaxc_ev_call_state call) {
	if(call.state & IAXC_CALL_STATE_BUSY) busy = 1;
	if(call.state & IAXC_CALL_STATE_COMPLETE) fail = 0;
	call_state = call.state;
/*
	if(debug) {
		fprintf(stdout, "STATE: ");
		if(call.state & IAXC_CALL_STATE_FREE)
			fprintf(stdout, "F");
		
		if(call.state & IAXC_CALL_STATE_ACTIVE)
			fprintf(stdout, "A");
		
		if(call.state & IAXC_CALL_STATE_OUTGOING)
			fprintf(stdout, "O");
		
		if(call.state & IAXC_CALL_STATE_RINGING)
			fprintf(stdout, "R");	
	
		if(call.state & IAXC_CALL_STATE_COMPLETE)
			fprintf(stdout, "C");	
	
		if(call.state & IAXC_CALL_STATE_SELECTED)
			fprintf(stdout, "S");
		
		if(call.state & IAXC_CALL_STATE_BUSY)
			fprintf(stdout, "B");		
	
		if(call.state & IAXC_CALL_STATE_TRANSFER)
			fprintf(stdout, "T");		
				
		fprintf(stdout, "\n");
		fflush(stdout);
	}
*/
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
			// fprintf(stdout, "TEXT: %s\n", e.ev.text.message);
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

	char *iax_host = NULL;
	char *iax_user = NULL;
	char *iax_pass = "";
	char *iax_num = NULL;
	char *iax_cid = "15555555555";
	char *iax_name = "";
	int iax_sec = 20;
	int call_id = 0;
	char dest[1024];
	time_t stime, etime;
	
	int c;
	extern char *optarg;
	extern int optind, optopt;

	while ((c = getopt(argc, argv, ":hs:u:p:c:o:n:l:N:DA")) != -1) {
		switch(c) {
			case 'h':
				usage(argv);
				break;
			case 's':
				iax_host = optarg;
				break;
			case 'u':
				iax_user = optarg;
				break;
			case 'p':
				iax_pass = optarg;
				break;
			case 'c':
				iax_cid = optarg;
				break;
			case 'o':
				iax_out = optarg;
				break;
			case 'n':
				iax_num = optarg;
				break;
			case 'l':
				iax_sec = atoi(optarg);
				break;
			case 'N':
				iax_name = optarg;
				break;
			case 'D':
				debug = 1;
				break;
			case 'A':
				audio = 1;
				break;			
		}
	}
	
	if(! (iax_host && iax_user && iax_num && iax_out)) usage(argv);

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
	
	/* forcible disable pulse audio if the audio flag is not set (-A) */
	if(! audio) setenv("PULSE_SERVER", "0.0.0.0", 1);
	
	if(debug) fprintf(stderr, ">> INITIALIZING\n");
	if ( iaxc_initialize(1) ) {
		fprintf(stdout, "error: Could not initialize iaxclient!\n");
		exit(0);
	}
	
	initialized = 1;
	if(debug) fprintf(stderr, ">> INITIALIZED\n");
	
	iaxc_set_audio_output(audio ? 0 : 1);
	iaxc_set_callerid (iax_name, iax_cid);
	iaxc_set_formats(IAXC_FORMAT_ULAW | IAXC_FORMAT_ALAW, IAXC_FORMAT_ULAW | IAXC_FORMAT_ALAW);
	
	// Causes problems for some asterix servers, not sure why yet
	// iaxc_set_silence_threshold(silence_threshold);

	if(debug) fprintf(stderr, ">> STARTING PROCESSING THREAD\n");
	iaxc_set_event_callback(iaxc_callback);	
	iaxc_start_processing_thread();
	if(debug) fprintf(stderr, ">> STARTED PROCESSING THREAD\n");

	iaxc_set_audio_prefs(IAXC_AUDIO_PREF_RECV_REMOTE_RAW);

	if(debug) fprintf(stderr, ">> REGISTERING\n")	;
	reg_id  = iaxc_register(iax_user, iax_pass, iax_host);
	if(debug) fprintf(stderr, ">> REGISTERED: %d\n", reg_id);

	if(debug) fprintf(stderr, ">> CALLING\n");
	call_id = iaxc_call(dest);
	if(debug) fprintf(stderr, ">> CALLED: %d\n", call_id);
	
	stime = time(NULL);
	etime = 0;
	
	if(debug) fprintf(stderr, ">> WAITING\n");	
	if(call_id >= 0) {
		iaxc_select_call(call_id);
		while( (unsigned int)(time(NULL))-(unsigned int)stime < iax_sec) {
			if(call_state & IAXC_CALL_STATE_COMPLETE && ! etime) etime = time(NULL);
			if(call_state & IAXC_CALL_STATE_BUSY) break;
			if(iaxc_first_free_call() == call_id) break;
			iaxc_millisleep(250);
		}
	} else {
		fail = 1;
	}
	
	if(debug) fprintf(stderr, ">> DONE\n");
	
	if(! etime) time(&etime);
	
	fprintf(stdout, "COMPLETED %s BYTES=%d FILE=%s FAIL=%d BUSY=%d RINGTIME=%d\n", 
		iax_num, 
		call_bytes,
		iax_out,
		fail,
		busy,
		(unsigned int)(etime) - (unsigned int)(stime)
	);

	iaxc_dump_all_calls();
	return(0);
}

/*

Note about ring times vs ring counts: 
  http://en.wikipedia.org/wiki/Ringtone#Ringing_signal
	The ringing pattern is known as ring cadence. This only applies to POTS fixed phones, where 
	the high voltage ring signal is switched on and off to create the ringing pattern. In North
	America, the standard ring cadence is "2-4", or two seconds of ringing followed by four 
	seconds of silence. In Australia and the UK, the standard ring cadence is 400 ms on, 200 ms
	off, 400 ms on, 2000 ms off. These patterns may vary from region to region, and other 
	patterns are used in different countries around the world.

ring count US = ringtime / 6.0 
ring count UK = ringtime / 3.0
*/
