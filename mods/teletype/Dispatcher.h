#pragma once

#include <od/tasks/Task.h>
#include <hal/timing.h>

namespace teletype
{

  class Dispatcher : public od::Task
  {
  public:
    Dispatcher();
    virtual ~Dispatcher();

    void enable(uint32_t address);
    void disable();
    void setDefaultSlew(int ms);
    // resets everything
    void hardReset();
    // preserves settings like pulse time and polarity
    void softReset();

    // LOCAL PATCH (US-15): count of SC.CV/SC.TR value commands received and
    // the port each last addressed, so the UI can see which port is driven.
    int getCVEventCount();
    int getLastCVPort();
    int getTREventCount();
    int getLastTRPort();

#ifndef SWIGLUA
    void process(float *inputs, float *outputs);

    void fillTRFrame(int port, float *out);
    float fillCVFrame(int port, float *out, float lastValue);

    // TR commands
    void commandTRSet(int delay, int port, int level);
    void commandTRToggle(int delay, int port);
    void commandTRPulse(int delay, int port);
    void commandTRPulseTime(int port, int ms);
    void commandTRPolarity(int delay, int port, bool polarity);

    // CV commands
    void commandCV(int delay, int port, int value);
    void commandCVSlew(int port, int ms);
    void commandCVSet(int delay, int port, int value);
    void commandCVOffset(int delay, int port, int value);

    static const int PortCount = 101;
    static const int MaxPort = PortCount - 1;
    static const int MinPort = 1;
    static const int NullPort = 0;

    // TR state
    float mTRLevel0[PortCount];
    float mTRLevel1[PortCount];
    int mTRDelays[PortCount];
    bool mTRPolarity[PortCount];
    int mTRPulseTime[PortCount];
    int mTRPulseRemaining[PortCount];
    bool mTRPulseActive[PortCount];

    // CV state
    float mCVTarget[PortCount];
    float mCVCurrent[PortCount];
    int mCVDelays[PortCount];
    float mCVOffset[PortCount];
    float mCVMaxDiff[PortCount];
    bool mCVSlewEnabled[PortCount];
#endif

  protected:
    tick_t mLastTimestamp;
    double mSamplesPerTick;
    int mDefaultSlewTimeMs = 2;
    bool mEnabled = false;
    volatile int mCVEventCount = 0;
    volatile int mLastCVPort = 0;
    volatile int mTREventCount = 0;
    volatile int mLastTRPort = 0;

    void noteCVEvent(int port);
    void noteTREvent(int port);

    void updateTR();
    void updateCV();
    int ticksToSamples(tick_t nticks);
  };

} // namespace teletype
