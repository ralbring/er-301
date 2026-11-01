#include <od/objects/measurement/OutletProbe.h>
#include <od/AudioThread.h>

// Number of (decimated) samples to evaluate, roughly the last 50 ms.
#define OUTLETPROBE_WINDOW 1200

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
    int n = (int)mpProbe->size();
    if (n > OUTLETPROBE_WINDOW)
      n = OUTLETPROBE_WINDOW;
    if (n == 0)
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
