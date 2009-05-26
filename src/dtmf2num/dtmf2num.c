/*
    Copyright 2008 Luigi Auriemma

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

    http://www.gnu.org/licenses/gpl.txt
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/stat.h>
#include "mywav.h"
#include "dsp.c"
//#include "resample2.c"



typedef int8_t      i8;
typedef uint8_t     u8;
typedef int16_t     i16;
typedef uint16_t    u16;
typedef int32_t     i32;
typedef uint32_t    u32;



#define VER     "0.1c"



int mywav_fri24(FILE *fd, uint32_t *num);
i16 *do_samples(FILE *fd, int wavsize, int *ret_samples, int bits);
int do_mono(i16 *smp, int samples, int ch);
void do_dcbias(i16 *smp, int samples);
void do_normalize(i16 *smp, int samples);
int do_8000(i16 *smp, int samples, int *freq);
void my_err(u8 *err);
void std_err(void);



int main(int argc, char *argv[]) {
    digit_detect_state_t dtmf;
    mywav_fmtchunk  fmt;
    struct  stat    xstat;
    FILE    *fd;
    int     i,
            wavsize,
            samples,
            writeback,
            raw      = 0,
            optimize = 1;
    i16     *smp;
    u8      *fname,
            *outfile = NULL;

    setbuf(stdin,  NULL);
    setbuf(stdout, NULL);

    fputs("\n"
        "DTMF2NUM "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@autistici.org\n"
        "web:    aluigi.org\n"
        "\n", stderr);

    if(argc < 2) {
        printf("\n"
            "Usage: %s [options] <file.WAV>\n"
            "\n"
            "Options:\n"
            "-r F C B  consider the file as raw headerless PCM data, you must specify the\n"
            "          Frequency, Channels and Bits like -r 44100 2 16\n"
            "-o        disable the automatic optimizations: DC bias adjust and normalize.\n"
            "          use this option only if your file is already clean and normalized\n"
            "-w FILE   debug option for dumping the handled samples from the memory to FILE\n"
            "\n", argv[0]);
        exit(1);
    }

    argc--;
    for(i = 1; i < argc; i++) {
        if(((argv[i][0] != '-') && (argv[i][0] != '/')) || (strlen(argv[i]) != 2)) {
            printf("\nError: wrong argument (%s)\n", argv[i]);
            exit(1);
        }
        switch(argv[i][1]) {
            case 'r': {
                memset(&fmt, 0, sizeof(fmt));
                if(!argv[++i]) exit(1);
                fmt.dwSamplesPerSec = atoi(argv[i]);
                if(!argv[++i]) exit(1);
                fmt.wChannels       = atoi(argv[i]);
                if(!argv[++i]) exit(1);
                fmt.wBitsPerSample  = atoi(argv[i]);
                fmt.wFormatTag      = 1;
                raw = 1;
                } break;
            case 'o': {
                optimize = 0;
                } break;
            case 'w': {
                if(!argv[++i]) exit(1);
                outfile = argv[i];
                } break;
            default: {
                printf("\nError: wrong option (%s)\n", argv[i]);
                exit(1);
            }
        }
    }

    fname = argv[argc];

    if(!strcmp(fname, "-")) {
        printf("- open stdin\n");
        fd = stdin;
    } else {
        printf("- open %s\n", fname);
        fd = fopen(fname, "rb");
        if(!fd) std_err();
    }

    if(raw) {
        fstat(fileno(fd), &xstat);
        wavsize = xstat.st_size;
    } else {
        wavsize = mywav_data(fd, &fmt);
    }
    fprintf(stderr,
        "  wave size      %u\n"
        "  format tag     %hu\n"
        "  channels:      %hu\n"
        "  samples/sec:   %u\n"
        "  avg/bytes/sec: %u\n"
        "  block align:   %hu\n"
        "  bits:          %hu\n",
        wavsize,
        fmt.wFormatTag,
        fmt.wChannels,
        fmt.dwSamplesPerSec,
        fmt.dwAvgBytesPerSec,
        fmt.wBlockAlign,
        fmt.wBitsPerSample);

    if(wavsize <= 0) my_err("corrupted WAVE file");
    if(fmt.wFormatTag != 1) my_err("only the classical PCM WAVE files are supported");

    smp = do_samples(fd, wavsize, &samples, fmt.wBitsPerSample);
    fprintf(stderr, "  samples:       %d\n", samples);
    if(fd != stdin) fclose(fd);

    samples = do_mono(smp, samples, fmt.wChannels);
    if(optimize) {
        do_dcbias(smp, samples);
        do_normalize(smp, samples);
    }
    samples = do_8000(smp, samples, &fmt.dwSamplesPerSec);

    fmt.wFormatTag       = 0x0001;
    fmt.wChannels        = 1;
    fmt.wBitsPerSample   = 16;
    fmt.wBlockAlign      = (fmt.wBitsPerSample >> 3) * fmt.wChannels;
    fmt.dwAvgBytesPerSec = fmt.dwSamplesPerSec * fmt.wBlockAlign;
    wavsize              = samples * sizeof(* smp);

    if(outfile) {
        fprintf(stderr, "- dump %s\n", outfile);
        fd = fopen(outfile, "wb");
        if(!fd) std_err();
        mywav_writehead(fd, &fmt, wavsize, NULL, 0);
        fwrite(smp, 1, wavsize, fd);
        fclose(fd);
    }

    SAMPLE_RATE = fmt.dwSamplesPerSec;

    ast_digit_detect_init(&dtmf, DSP_DIGITMODE_MF);
    mf_detect(&dtmf, smp, samples, DSP_DIGITMODE_NOQUELCH, &writeback);
    printf("\n- MF numbers:    %s\n", dtmf.digits[0] ? dtmf.digits : "none");

    ast_digit_detect_init(&dtmf, DSP_DIGITMODE_DTMF);
    dtmf_detect(&dtmf, smp, samples, DSP_DIGITMODE_NOQUELCH, &writeback);
    printf("\n- DTMF numbers:  %s\n", dtmf.digits[0] ? dtmf.digits : "none");

    return(0);
}



int mywav_fri24(FILE *fd, uint32_t *num) {
    uint32_t    ret;
    uint8_t     tmp;

    if(fread(&tmp, 1, 1, fd) != 1) return(-1);  ret = tmp;
    if(fread(&tmp, 1, 1, fd) != 1) return(-1);  ret |= (tmp << 8);
    if(fread(&tmp, 1, 1, fd) != 1) return(-1);  ret |= (tmp << 16);
    *num = ret;
    return(0);
}



i16 *do_samples(FILE *fd, int wavsize, int *ret_samples, int bits) {
    i32     tmp32;
    int     i   = 0,
            samples;
    i16     *smp;
    i8      tmp8;

    samples = wavsize / (bits >> 3);
    smp = malloc(sizeof(* smp) * samples);
    if(!smp) std_err();

    if(bits == 8) {
        for(i = 0; i < samples; i++) {
            if(mywav_fri08(fd, &tmp8) < 0) break;
            smp[i] = (tmp8 << 8) - 32768;
        }

    } else if(bits == 16) {
        for(i = 0; i < samples; i++) {
            if(mywav_fri16(fd, &smp[i]) < 0) break;
        }

    } else if(bits == 24) {
        for(i = 0; i < samples; i++) {
            if(mywav_fri24(fd, &tmp32) < 0) break;
            smp[i] = tmp32 >> 8;
        }

    } else if(bits == 32) {
        for(i = 0; i < samples; i++) {
            if(mywav_fri32(fd, &tmp32) < 0) break;
            smp[i] = tmp32 >> 16;
        }

    } else {
        my_err("number of bits used in the WAVE file not supported");
    }
    *ret_samples = i;
    return(smp);
}



int do_mono(i16 *smp, int samples, int ch) {
    i32     tmp;    // max 65535 channels
    int     i,
            j;

    if(!ch) my_err("the WAVE file doesn't have channels");
    if(ch == 1) return(samples);

    for(i = 0; samples > 0; i++) {
        tmp = 0;
        for(j = 0; j < ch; j++) {
            tmp += smp[(i * ch) + j];
        }
        smp[i] = tmp / ch;
        samples -= ch;
    }
    return(i);
}



void do_dcbias(i16 *smp, int samples) {
    int     i;
    i16     bias,
            maxneg,
            maxpos;

    maxneg = 32767;
    maxpos = -32768;
    for(i = 0; i < samples; i++) {
        if(smp[i] < maxneg) {
            maxneg = smp[i];
        } else if(smp[i] > maxpos) {
            maxpos = smp[i];
        }
    }

    bias = (maxneg + maxpos) / 2;
    fprintf(stderr, "  bias adjust:   %d\n", bias);

    for(i = 0; i < samples; i++) {
        smp[i] -= bias;
    }
}



void do_normalize(i16 *smp, int samples) {
    int     i;
    i16     bias,
            maxneg,
            maxpos;

    maxneg = 0;
    maxpos = 0;
    for(i = 0; i < samples; i++) {
        if(smp[i] < maxneg) {
            maxneg = smp[i];
        } else if(smp[i] > maxpos) {
            maxpos = smp[i];
        }
    }

    fprintf(stderr, "  volume peaks:  %d %d\n", maxneg, maxpos);

    if(maxneg < 0) maxneg = (-maxneg) - 1;
    if(maxneg > maxpos) {
        bias = maxneg;
    } else {
        bias = maxpos;
    }
    if(bias == 32767) return;

    fprintf(stderr, "  normalize:     %d\n", 32767 - bias);

    for(i = 0; i < samples; i++) {
        smp[i] = (smp[i] * 32767) / bias;
    }
}



int do_8000(i16 *smp, int samples, int *freq) {
    void    *res;
    int     consumed;

    if(*freq <= 8000) return(samples);

    fprintf(stderr, "  resampling to: 8000hz\n");
    res = av_resample_init(8000, *freq, 16, 10, 0, 0.8);
    samples = av_resample(res, smp, smp, &consumed, samples, samples, 1);
    av_resample_close(res);

    *freq = 8000;
    return(samples);
}



void my_err(u8 *err) {
    fprintf(stderr, "\nError: %s\n", err);
    exit(1);
}



void std_err(void) {
    perror("\nError");
    exit(1);
}


