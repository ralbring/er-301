#pragma once

#include <od/objects/Inlet.h>
#include <od/objects/Outlet.h>

namespace od
{

  // LOCAL PATCH (US-15): lets Lua measure the signal on an outlet (e.g. an
  // external input jack or a teletype port) from the UI thread. The audio
  // thread accumulates min/max/sum of every frame; update() turns the samples
  // since the previous update into mean and peak-to-peak. Unlike FifoProbe
  // this does not draw from the limited probe pool, so many outlets can be
  // watched at once.
  class OutletProbe
  {
  public:
    OutletProbe();
    virtual ~OutletProbe();

    void watch(Outlet *outlet);
    void release();

    void update();
    float mean();
    float peakToPeak();

#ifndef SWIGLUA
    // called from the audio thread
    void accumulate();
#endif

  protected:
    Inlet *mpInput = 0;
    bool mWatching = false;
    float mSum = 0.0f;
    float mMin = 0.0f;
    float mMax = 0.0f;
    int mCount = 0;
    float mMean = 0.0f;
    float mPeakToPeak = 0.0f;
  };

} /* namespace od */
