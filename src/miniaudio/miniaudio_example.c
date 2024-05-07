#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include <stdio.h>

#ifdef __EMSCRIPTEN__
void main_loop__em()
{
}
#endif

int counts = 0;

void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
{
    MA_ASSERT(pDevice->capture.format == pDevice->playback.format);
    MA_ASSERT(pDevice->capture.channels == pDevice->playback.channels);

    /* In this example the format and channel count are the same for both input and output which means we can just memcpy(). */
    MA_COPY_MEMORY(
            pOutput,
            pInput,
            frameCount * ma_get_bytes_per_frame(
                pDevice->capture.format,
                pDevice->capture.channels)
            );
    counts++;
    if(counts % 10 == 0) {
        printf("%d\n", counts);
    }

}

int main(int argc, char** argv)
{
    char c;
    c = getchar();
    printf("hello %c \n", c);

    ma_result result;
    ma_device_config deviceConfig;
    ma_device device;

    deviceConfig = ma_device_config_init(ma_device_type_duplex);
    deviceConfig.capture.pDeviceID  = NULL;
    deviceConfig.capture.format     = ma_format_s16;
    deviceConfig.capture.channels   = 2;
    deviceConfig.capture.shareMode  = ma_share_mode_shared;
    deviceConfig.playback.pDeviceID = NULL;
    deviceConfig.playback.format    = ma_format_s16;
    deviceConfig.playback.channels  = 2;
    deviceConfig.dataCallback       = data_callback;
    result = ma_device_init(NULL, &deviceConfig, &device);
    if (result != MA_SUCCESS) {
        return result;
    }

#ifdef __EMSCRIPTEN__
    getchar();
#endif

    ma_device_start(&device);

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(main_loop__em, 0, 1);
#else
    printf("Press Enter to quit...\n");
    getchar();
    //sleep(3);

#endif

    ma_device_uninit(&device);

    (void)argc;
    (void)argv;
    return 0;
}
