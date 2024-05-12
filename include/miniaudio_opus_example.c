#include <stdio.h>
#include <stdlib.h>
#include <opus/opus.h>

// brew install opus
// gcc -O3 -o miniaudio_opus_example miniaudio_opus_example.c -I/opt/homebrew/Cellar/opus/1.5.2/include -L/opt/homebrew/Cellar/opus/1.5.2/lib -lm -lpthread -lopus && ./miniaudio_opus_example
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

// Opus encoder and decoder global instances
OpusEncoder *encoder = NULL;
OpusDecoder *decoder = NULL;

// Audio callback function for processing
void data_callback(ma_device *pDevice, void *pOutput, const void *pInput, ma_uint32 frameCount) {
    static short buffer[48000 * 2]; // Temporary buffer for PCM data
    unsigned char encodedData[4096]; // Buffer for encoded data
    opus_int32 encodedBytes;
    int frameSize = 960; // Opus frame size

    // Convert float PCM to int16 (required by Opus)
    ma_pcm_f32_to_s16(buffer, pInput, frameCount * pDevice->capture.channels, ma_dither_mode_none);

    // Encode
    encodedBytes = opus_encode(encoder, buffer, frameSize, encodedData, sizeof(encodedData));
    if (encodedBytes < 0) {
        printf("Encode failed: %s\n", opus_strerror(encodedBytes));
        return;
    }

    // Decode
    int samples = opus_decode(decoder, encodedData, encodedBytes, buffer, frameSize, 0);
    if (samples < 0) {
        printf("Decode failed: %s\n", opus_strerror(samples));
        return;
    }

    // Convert back to float for playback
    ma_pcm_s16_to_f32(pOutput, buffer, samples * pDevice->playback.channels, ma_dither_mode_none);
}

// Setup function for Opus encoder and decoder
int setup_opus(int sampleRate, int channels) {
    int err;

    encoder = opus_encoder_create(sampleRate, channels, OPUS_APPLICATION_AUDIO, &err);
    if (err != OPUS_OK) {
        printf("Failed to create Opus encoder: %s\n", opus_strerror(err));
        return -1;
    }

    decoder = opus_decoder_create(sampleRate, channels, &err);
    if (err != OPUS_OK) {
        printf("Failed to create Opus decoder: %s\n", opus_strerror(err));
        return -1;
    }

    return 0;
}

// Setup function for miniAudio device
int setup_audio(ma_device *device) {
    ma_result result;
    ma_device_config deviceConfig;

    deviceConfig = ma_device_config_init(ma_device_type_duplex);
    deviceConfig.capture.format   = ma_format_f32;
    deviceConfig.capture.channels = 2;
    deviceConfig.playback.format   = ma_format_f32;
    deviceConfig.playback.channels = 2;
    deviceConfig.sampleRate = 48000;
    deviceConfig.dataCallback = data_callback;

    result = ma_device_init(NULL, &deviceConfig, device);
    if (result != MA_SUCCESS) {
        printf("Failed to initialize audio device.\n");
        return -1;
    }

    return 0;
}

// Main function to setup and run the audio device
int main() {
    ma_device device;

    if (setup_audio(&device) < 0) {
        return -1;
    }

    if (setup_opus(device.playback.internalSampleRate, device.playback.channels) < 0) {
        return -1;
    }

    if (ma_device_start(&device) != MA_SUCCESS) {
        printf("Failed to start device.\n");
        return -1;
    }

    printf("Device is running... Press Enter to quit.\n");
    getchar();

    ma_device_uninit(&device);
    opus_encoder_destroy(encoder);
    opus_decoder_destroy(decoder);

    return 0;
}
