/*
 * Asterisk -- An open source telephony toolkit.
 *
 * Copyright (C) 1999 - 2005, Digium, Inc.
 *
 * Mark Spencer <markster@digium.com>
 *
 * Goertzel routines are borrowed from Steve Underwood's tremendous work on the
 * DTMF detector.
 *
 * See http://www.asterisk.org for more information about
 * the Asterisk project. Please do not directly contact
 * any of the maintainers of this project for assistance;
 * the project provides a web site, mailing lists and IRC
 * channels for your use.
 *
 * This program is free software, distributed under the terms of
 * the GNU General Public License Version 2. See the LICENSE file
 * at the top of the source tree.
 */

/*! \file
 *
 * \brief Convenience Signal Processing routines
 *
 * \author Mark Spencer <markster@digium.com>
 * \author Steve Underwood <steveu@coppice.org>
 */

/* Some routines from tone_detect.c by Steven Underwood as published under the zapata library */
/*
	tone_detect.c - General telephony tone detection, and specific
					detection of DTMF.

	Copyright (C) 2001  Steve Underwood <steveu@coppice.org>

	Despite my general liking of the GPL, I place this code in the
	public domain for the benefit of all mankind - even the slimy
	ones who might try to proprietize my work and use it to my
	detriment.
*/

/*
  modifications for decoding also damaged audio by Luigi auriemma "// aluigi work-around"
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <malloc.h>

#define	DSP_DIGITMODE_DTMF			0				/*!< Detect DTMF digits */
#define DSP_DIGITMODE_MF			1				/*!< Detect MF digits */

#define DSP_DIGITMODE_NOQUELCH		(1 << 8)		/*!< Do not quelch DTMF from in-band */
#define DSP_DIGITMODE_RELAXDTMF		(1 << 11)		/*!< "Radio" mode (relaxed DTMF) */

#define	MAX_DTMF_DIGITS		1024

/* Basic DTMF specs:
 *
 * Minimum tone on = 40ms
 * Minimum tone off = 50ms
 * Maximum digit rate = 10 per second
 * Normal twist <= 8dB accepted
 * Reverse twist <= 4dB accepted
 * S/N >= 15dB will detect OK
 * Attenuation <= 26dB will detect OK
 * Frequency tolerance +- 1.5% will detect, +-3.5% will reject
 */

//#define DTMF_THRESHOLD		8.0e7
#define DTMF_THRESHOLD      800000000.0 // aluigi work-around
#define DTMF_NORMAL_TWIST	6.3     /* 8dB */
#ifdef	RADIO_RELAX
#define DTMF_REVERSE_TWIST          ((digitmode & DSP_DIGITMODE_RELAXDTMF) ? 6.5 : 2.5)     /* 4dB normal */
#else
#define DTMF_REVERSE_TWIST          ((digitmode & DSP_DIGITMODE_RELAXDTMF) ? 4.0 : 2.5)     /* 4dB normal */
#endif
#define DTMF_RELATIVE_PEAK_ROW	6.3     /* 8dB */
#define DTMF_RELATIVE_PEAK_COL	6.3     /* 8dB */
#define DTMF_2ND_HARMONIC_ROW       ((digitmode & DSP_DIGITMODE_RELAXDTMF) ? 1.7 : 2.5)     /* 4dB normal */
#define DTMF_2ND_HARMONIC_COL	63.1    /* 18dB */
#define DTMF_TO_TOTAL_ENERGY	42.0

//#define BELL_MF_THRESHOLD	1.6e9
#define BELL_MF_THRESHOLD   DTMF_THRESHOLD  // aluigi work-around
#define BELL_MF_TWIST		4.0     /* 6dB */
#define BELL_MF_RELATIVE_PEAK	12.6    /* 11dB */

static int SAMPLE_RATE = 8000;

typedef struct {
	int v2;
	int v3;
	int chunky;
	int fac;
	int samples;
} goertzel_state_t;

typedef struct {
	int value;
	int power;
} goertzel_result_t;

typedef struct
{
	goertzel_state_t row_out[4];
	goertzel_state_t col_out[4];
	int lasthit;
	int current_hit;
	float energy;
	int current_sample;
} dtmf_detect_state_t;

typedef struct
{
	goertzel_state_t tone_out[6];
	int current_hit;
	int hits[5];
	int current_sample;
} mf_detect_state_t;

typedef struct
{
	char digits[MAX_DTMF_DIGITS + 1];
	int current_digits;
	int detected_digits;
	int lost_digits;

	union {
		dtmf_detect_state_t dtmf;
		mf_detect_state_t mf;
	} td;
} digit_detect_state_t;

static float dtmf_row[] =
{
	697.0,  770.0,  852.0,  941.0
};
static float dtmf_col[] =
{
	1209.0, 1336.0, 1477.0, 1633.0
};

static float mf_tones[] =
{
	700.0, 900.0, 1100.0, 1300.0, 1500.0, 1700.0
};

static char dtmf_positions[] = "123A" "456B" "789C" "*0#D";

static char bell_mf_positions[] = "1247C-358A--69*---0B----#";

static inline void goertzel_sample(goertzel_state_t *s, short sample)
{
	int v1;
	
	v1 = s->v2;
	s->v2 = s->v3;
	
	s->v3 = (s->fac * s->v2) >> 15;
	s->v3 = s->v3 - v1 + (sample >> s->chunky);
	if (abs(s->v3) > 32768) {
		s->chunky++;
		s->v3 = s->v3 >> 1;
		s->v2 = s->v2 >> 1;
		v1 = v1 >> 1;
	}
}

static inline void goertzel_update(goertzel_state_t *s, short *samps, int count)
{
	int i;
	
	for (i=0;i<count;i++) 
		goertzel_sample(s, samps[i]);
}

static inline float goertzel_result(goertzel_state_t *s)
{
	goertzel_result_t r;
	r.value = (s->v3 * s->v3) + (s->v2 * s->v2);
	r.value -= ((s->v2 * s->v3) >> 15) * s->fac;
	r.power = s->chunky * 2;
	return (float)r.value * (float)(1 << r.power);
}

static inline void goertzel_init(goertzel_state_t *s, float freq, int samples)
{
	s->v2 = s->v3 = s->chunky = 0.0;
	s->fac = (int)(32768.0 * 2.0 * cos(2.0 * M_PI * freq / SAMPLE_RATE));
	s->samples = samples;
}

static inline void goertzel_reset(goertzel_state_t *s)
{
	s->v2 = s->v3 = s->chunky = 0.0;
}

static void ast_dtmf_detect_init (dtmf_detect_state_t *s)
{
	int i;

	s->lasthit = 0;
	s->current_hit = 0;
	for (i = 0;  i < 4;  i++) {
		goertzel_init (&s->row_out[i], dtmf_row[i], 102);
		goertzel_init (&s->col_out[i], dtmf_col[i], 102);
		s->energy = 0.0;
	}
	s->current_sample = 0;
}

static void ast_mf_detect_init (mf_detect_state_t *s)
{
	int i;
	s->hits[0] = s->hits[1] = s->hits[2] = s->hits[3] = s->hits[4] = 0;
	for (i = 0;  i < 6;  i++) {
		goertzel_init (&s->tone_out[i], mf_tones[i], 160);
	}
	s->current_sample = 0;
	s->current_hit = 0;
}

static void ast_digit_detect_init(digit_detect_state_t *s, int mf)
{
	s->current_digits = 0;
	s->detected_digits = 0;
	s->lost_digits = 0;
	s->digits[0] = '\0';

	if (mf)
		ast_mf_detect_init(&s->td.mf);
	else
		ast_dtmf_detect_init(&s->td.dtmf);
}

static void store_digit(digit_detect_state_t *s, char digit)
{
	s->detected_digits++;
	if (s->current_digits < MAX_DTMF_DIGITS) {
		s->digits[s->current_digits++] = digit;
		s->digits[s->current_digits] = '\0';
	} else {
		//ast_log(LOG_WARNING, "Digit lost due to full buffer\n");
		s->lost_digits++;
	}
}

static int dtmf_detect(digit_detect_state_t *s, int16_t amp[], int samples, 
		 int digitmode, int *writeback)
{
	float row_energy[4];
	float col_energy[4];
	float famp;
	int i;
	int j;
	int sample;
	int best_row;
	int best_col;
	int hit;
	int limit;

	hit = 0;
	for (sample = 0;  sample < samples;  sample = limit) {
		/* 102 is optimised to meet the DTMF specs. */
		if ((samples - sample) >= (102 - s->td.dtmf.current_sample))
			limit = sample + (102 - s->td.dtmf.current_sample);
		else
			limit = samples;
		/* The following unrolled loop takes only 35% (rough estimate) of the 
		   time of a rolled loop on the machine on which it was developed */
		for (j = sample; j < limit; j++) {
			famp = amp[j];
			s->td.dtmf.energy += famp*famp;
			/* With GCC 2.95, the following unrolled code seems to take about 35%
			   (rough estimate) as long as a neat little 0-3 loop */
			goertzel_sample(s->td.dtmf.row_out, amp[j]);
			goertzel_sample(s->td.dtmf.col_out, amp[j]);
			goertzel_sample(s->td.dtmf.row_out + 1, amp[j]);
			goertzel_sample(s->td.dtmf.col_out + 1, amp[j]);
			goertzel_sample(s->td.dtmf.row_out + 2, amp[j]);
			goertzel_sample(s->td.dtmf.col_out + 2, amp[j]);
			goertzel_sample(s->td.dtmf.row_out + 3, amp[j]);
			goertzel_sample(s->td.dtmf.col_out + 3, amp[j]);
		}
		s->td.dtmf.current_sample += (limit - sample);
		if (s->td.dtmf.current_sample < 102) {
			if (hit && !((digitmode & DSP_DIGITMODE_NOQUELCH))) {
				/* If we had a hit last time, go ahead and clear this out since likely it
				   will be another hit */
				for (i=sample;i<limit;i++) 
					amp[i] = 0;
				*writeback = 1;
			}
			continue;
		}
		/* We are at the end of a DTMF detection block */
		/* Find the peak row and the peak column */
		row_energy[0] = goertzel_result (&s->td.dtmf.row_out[0]);
		col_energy[0] = goertzel_result (&s->td.dtmf.col_out[0]);

		for (best_row = best_col = 0, i = 1;  i < 4;  i++) {
			row_energy[i] = goertzel_result (&s->td.dtmf.row_out[i]);
			if (row_energy[i] > row_energy[best_row])
				best_row = i;
			col_energy[i] = goertzel_result (&s->td.dtmf.col_out[i]);
			if (col_energy[i] > col_energy[best_col])
				best_col = i;
		}
		hit = 0;

		/* Basic signal level test and the twist test */
		if (row_energy[best_row] >= DTMF_THRESHOLD && 
		    col_energy[best_col] >= DTMF_THRESHOLD &&
//		    col_energy[best_col] < row_energy[best_row] *DTMF_REVERSE_TWIST &&          // aluigi work-around
		    col_energy[best_col]*DTMF_NORMAL_TWIST > row_energy[best_row]) {
			/* Relative peak test */
			for (i = 0;  i < 4;  i++) {
				if ((i != best_col &&
				    col_energy[i]*DTMF_RELATIVE_PEAK_COL > col_energy[best_col]) ||
				    (i != best_row 
				     && row_energy[i]*DTMF_RELATIVE_PEAK_ROW > row_energy[best_row])) {
					break;
				}
			}
			/* ... and fraction of total energy test */
			if (i >= 4 /*&&
			    (row_energy[best_row] + col_energy[best_col]) > DTMF_TO_TOTAL_ENERGY*s->td.dtmf.energy*/) {     // aluigi work-around
				/* Got a hit */
				hit = dtmf_positions[(best_row << 2) + best_col];
				if (!(digitmode & DSP_DIGITMODE_NOQUELCH)) {
					/* Zero out frame data if this is part DTMF */
					for (i=sample;i<limit;i++) 
						amp[i] = 0;
					*writeback = 1;
				}
			}
		} 

		/* The logic in the next test is:
		   For digits we need two successive identical clean detects, with
		   something different preceeding it. This can work with
		   back to back differing digits. More importantly, it
		   can work with nasty phones that give a very wobbly start
		   to a digit */
		if (hit != s->td.dtmf.current_hit) {
			if (hit && s->td.dtmf.lasthit == hit) {
				s->td.dtmf.current_hit = hit;
				store_digit(s, hit);
			} else if (s->td.dtmf.lasthit != s->td.dtmf.current_hit) {
				s->td.dtmf.current_hit = 0;
			}
		}
		s->td.dtmf.lasthit = hit;

		/* Reinitialise the detector for the next block */
		for (i = 0;  i < 4;  i++) {
			goertzel_reset(&s->td.dtmf.row_out[i]);
			goertzel_reset(&s->td.dtmf.col_out[i]);
		}
		s->td.dtmf.energy = 0.0;
		s->td.dtmf.current_sample = 0;
	}
	return (s->td.dtmf.current_hit);	/* return the debounced hit */
}

/* MF goertzel size */
#define MF_GSIZE 120

static int mf_detect(digit_detect_state_t *s, int16_t amp[],
	int samples, int digitmode, int *writeback)
{
	float energy[6];
	int best;
	int second_best;
	float famp;
	int i;
	int j;
	int sample;
	int hit;
	int limit;

	hit = 0;
	for (sample = 0;  sample < samples;  sample = limit) {
		/* 80 is optimised to meet the MF specs. */
		if ((samples - sample) >= (MF_GSIZE - s->td.mf.current_sample))
			limit = sample + (MF_GSIZE - s->td.mf.current_sample);
		else
			limit = samples;
		/* The following unrolled loop takes only 35% (rough estimate) of the 
		   time of a rolled loop on the machine on which it was developed */
		for (j = sample;  j < limit;  j++) {
			famp = amp[j];
			/* With GCC 2.95, the following unrolled code seems to take about 35%
			   (rough estimate) as long as a neat little 0-3 loop */
			goertzel_sample(s->td.mf.tone_out, amp[j]);
			goertzel_sample(s->td.mf.tone_out + 1, amp[j]);
			goertzel_sample(s->td.mf.tone_out + 2, amp[j]);
			goertzel_sample(s->td.mf.tone_out + 3, amp[j]);
			goertzel_sample(s->td.mf.tone_out + 4, amp[j]);
			goertzel_sample(s->td.mf.tone_out + 5, amp[j]);
		}
		s->td.mf.current_sample += (limit - sample);
		if (s->td.mf.current_sample < MF_GSIZE) {
			if (hit && !((digitmode & DSP_DIGITMODE_NOQUELCH))) {
				/* If we had a hit last time, go ahead and clear this out since likely it
				   will be another hit */
				for (i=sample;i<limit;i++) 
					amp[i] = 0;
				*writeback = 1;
			}
			continue;
		}
		/* We're at the end of an MF detection block.  */
		/* Find the two highest energies. The spec says to look for
		   two tones and two tones only. Taking this literally -ie
		   only two tones pass the minimum threshold - doesn't work
		   well. The sinc function mess, due to rectangular windowing
		   ensure that! Find the two highest energies and ensure they
		   are considerably stronger than any of the others. */
		energy[0] = goertzel_result(&s->td.mf.tone_out[0]);
		energy[1] = goertzel_result(&s->td.mf.tone_out[1]);
		if (energy[0] > energy[1]) {
			best = 0;
			second_best = 1;
		} else {
			best = 1;
			second_best = 0;
		}
		/*endif*/
		for (i=2;i<6;i++) {
			energy[i] = goertzel_result(&s->td.mf.tone_out[i]);
			if (energy[i] >= energy[best]) {
				second_best = best;
				best = i;
			} else if (energy[i] >= energy[second_best]) {
				second_best = i;
			}
		}
		/* Basic signal level and twist tests */
		hit = 0;
		if (energy[best] >= BELL_MF_THRESHOLD && energy[second_best] >= BELL_MF_THRESHOLD
//	            && energy[best] < energy[second_best]*BELL_MF_TWIST         // aluigi work-around
	            && energy[best]*BELL_MF_TWIST > energy[second_best]) {
			/* Relative peak test */
			hit = -1;
			for (i=0;i<6;i++) {
				if (i != best && i != second_best) {
					if (energy[i]*BELL_MF_RELATIVE_PEAK >= energy[second_best]) {
						/* The best two are not clearly the best */
						hit = 0;
						break;
					}
				}
			}
		}
		if (hit) {
			/* Get the values into ascending order */
			if (second_best < best) {
				i = best;
				best = second_best;
				second_best = i;
			}
			best = best*5 + second_best - 1;
			hit = bell_mf_positions[best];
			/* Look for two successive similar results */
			/* The logic in the next test is:
			   For KP we need 4 successive identical clean detects, with
			   two blocks of something different preceeding it. For anything
			   else we need two successive identical clean detects, with
			   two blocks of something different preceeding it. */
			if (hit == s->td.mf.hits[4] && hit == s->td.mf.hits[3] &&
			   ((hit != '*' && hit != s->td.mf.hits[2] && hit != s->td.mf.hits[1])||
			    (hit == '*' && hit == s->td.mf.hits[2] && hit != s->td.mf.hits[1] && 
			    hit != s->td.mf.hits[0]))) {
				store_digit(s, hit);
			}
		}


		if (hit != s->td.mf.hits[4] && hit != s->td.mf.hits[3]) {
			/* Two successive block without a hit terminate current digit */
			s->td.mf.current_hit = 0;
		}

		s->td.mf.hits[0] = s->td.mf.hits[1];
		s->td.mf.hits[1] = s->td.mf.hits[2];
		s->td.mf.hits[2] = s->td.mf.hits[3];
		s->td.mf.hits[3] = s->td.mf.hits[4];
		s->td.mf.hits[4] = hit;
		/* Reinitialise the detector for the next block */
		for (i = 0;  i < 6;  i++)
			goertzel_reset(&s->td.mf.tone_out[i]);
		s->td.mf.current_sample = 0;
	}

	return (s->td.mf.current_hit); /* return the debounced hit */
}
