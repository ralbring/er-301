#include <od/objects/measurement/OutletProbe.h>
#include <od/AudioThread.h>

// Minimum number of (decimated) samples to evaluate per update, and extra
// samples to cover jitter between updates.
#define OUTLETPROBE_MIN_WINDOW 256
#define OUTLETPROBE_MARGIN 128

namespace od
{

  OutletProbe::OutletProbe()
  {
  }

  OutletProbe::~OutletProbe()
  {
    release();
  }

  void OutletProbe::watch(Outlet *outlet)
  {
    release();
    if (outlet == 0)
      return;
    mpOutlet = outlet;
    mpOutlet->attach();
    mpProbe = AudioThread::getFifoProbe();
    if (mpProbe)
    {
      mpProbe->reset();
      AudioThread::connect(mpOutlet, &mpProbe->mInput);
    }
    mLastUpdate = ticks();
    mFirstUpdate = true;
  }

  void OutletProbe::release()
  {
    if (mpProbe)
    {
      AudioThread::disconnect(&mpProbe->mInput);
      AudioThread::releaseFifoProbe(mpProbe);
      mpProbe = 0;
    }
    if (mpOutlet)
    {
      mpOutlet->release();
      mpOutlet = 0;
    }
    mMean = 0.0f;
    mPeakToPeak = 0.0f;
  }

  void OutletProbe::update()
  {
    if (mpProbe == 0)
      return;
    tick_t now = ticks();
    float elapsed = ticks2secs(now - mLastUpdate);
    mLastUpdate = now;
    int size = (int)mpProbe->size();
    // The first update must not reach back into the probe's cleared buffer.
    int n = (int)(elapsed * mpProbe->getRate()) +
            (mFirstUpdate ? -OUTLETPROBE_MARGIN : OUTLETPROBE_MARGIN);
    mFirstUpdate = false;
    if (n < OUTLETPROBE_MIN_WINDOW)
      n = OUTLETPROBE_MIN_WINDOW;
    if (n > size)
      n = size;
    if (n <= 0)
      return;
    float *values = mpProbe->get(n);
    float sum = 0.0f;
    float lo = values[0];
    float hi = values[0];
    for (int i = 0; i < n; i++)
    {
      float x = values[i];
      sum += x;
      if (x < lo)
        lo = x;
      if (x > hi)
        hi = x;
    }
    mMean = sum / n;
    mPeakToPeak = hi - lo;
  }

  float OutletProbe::mean()
  {
    return mMean;
  }

  float OutletProbe::peakToPeak()
  {
    return mPeakToPeak;
  }

} /* namespace od */
