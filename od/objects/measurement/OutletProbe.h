#pragma once

#include <od/objects/Outlet.h>
#include <od/objects/measurement/FifoProbe.h>

namespace od
{

  // LOCAL PATCH (US-15): lets Lua measure the recent signal on an outlet
  // (e.g. an external input jack) from the UI thread, the same way MiniScope
  // taps an outlet through a FifoProbe from the audio thread's pool.
  class OutletProbe
  {
  public:
    OutletProbe();
    virtual ~OutletProbe();

    void watch(Outlet *outlet);
    void release();

    // Recomputes mean and peak-to-peak over the most recent samples.
    void update();
    float mean();
    float peakToPeak();

  protected:
    Outlet *mpOutlet = 0;
    FifoProbe *mpProbe = 0;
    float mMean = 0.0f;
    float mPeakToPeak = 0.0f;
  };

} /* namespace od */
