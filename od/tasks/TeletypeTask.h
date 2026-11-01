#pragma once

#include <od/tasks/Task.h>
#include <od/objects/Outlet.h>
#include <hal/timing.h>

namespace od
{

  // LOCAL PATCH (US-15): the teletype i2c dispatcher from the teletype mod,
  // built into the firmware. Received CV/TR ports are exposed as outlets that
  // the UI offers as external sources (groups "TT CV" and "TT TR").

  class TeletypeTask : public Task
  {
  public:
    TeletypeTask();
    virtual ~TeletypeTask();

    void enable(uint32_t address);
    void disable();
    void setDefaultSlew(int ms);
    // resets everything
    void hardReset();
    // preserves settings like pulse time and polarity
    void softReset();

    // port is 1-based, as in SC.CV/SC.TR (1 to MaxPort)
    Outlet *getCVOutlet(int port);
    Outlet *getTROutlet(int port);
    bool isEnabled();

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

    // one outlet per port, index 0 (NullPort) unused
    Outlet *mCVOutlets[PortCount];
    Outlet *mTROutlets[PortCount];
    float mCVOutletValues[PortCount];

    void fillOutlets();

    void updateTR();
    void updateCV();
    int ticksToSamples(tick_t nticks);
  };

} // namespace od
