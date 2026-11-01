#include <od/objects/measurement/OutletProbe.h>
#include <od/AudioThread.h>
#include <od/tasks/Task.h>
#include <od/config.h>
#include <hal/concurrency/Mutex.h>
#include <limits.h>
#include <vector>
#include <algorithm>

namespace od
{

  // Runs every watching OutletProbe once per frame, after the tasks that
  // produce the external sources.
  class OutletProbeTask : public Task
  {
  public:
    OutletProbeTask() : Task("OutletProbeTask")
    {
    }

    virtual void process(float *inputs, float *outputs)
    {
      mMutex.enter();
      for (OutletProbe *probe : mProbes)
      {
        probe->accumulate();
      }
      mMutex.leave();
    }

    void add(OutletProbe *probe)
    {
      mMutex.enter();
      mProbes.push_back(probe);
      mMutex.leave();
    }

    void remove(OutletProbe *probe)
    {
      mMutex.enter();
      mProbes.erase(std::remove(mProbes.begin(), mProbes.end(), probe),
                    mProbes.end());
      mMutex.leave();
    }

    Mutex mMutex;

  private:
    std::vector<OutletProbe *> mProbes;
  };

  static OutletProbeTask *getTask()
  {
    static OutletProbeTask *task = 0;
    if (task == 0)
    {
      task = new OutletProbeTask();
      task->attach();
      AudioThread::addTask(task, INT_MIN + 1);
    }
    return task;
  }

  OutletProbe::OutletProbe()
  {
    // Heap-allocated and reference counted, so a pending (dis)connection in
    // the audio thread's queue keeps it alive after this probe is deleted.
    mpInput = new Inlet("In");
    mpInput->attach();
  }

  OutletProbe::~OutletProbe()
  {
    release();
    mpInput->release();
  }

  void OutletProbe::watch(Outlet *outlet)
  {
    release();
    if (outlet == 0)
      return;
    mSum = 0.0f;
    mCount = 0;
    AudioThread::connect(outlet, mpInput);
    getTask()->add(this);
    mWatching = true;
  }

  void OutletProbe::release()
  {
    if (mWatching)
    {
      getTask()->remove(this);
      AudioThread::disconnect(mpInput);
      mWatching = false;
    }
    mMean = 0.0f;
    mPeakToPeak = 0.0f;
  }

  void OutletProbe::accumulate()
  {
    // Skip frames until the queued connection has been made.
    if (!mpInput->isConnected())
      return;
    float *in = mpInput->buffer();
    float sum = 0.0f;
    float lo = in[0];
    float hi = in[0];
    for (int i = 0; i < FRAMELENGTH; i++)
    {
      float x = in[i];
      sum += x;
      if (x < lo)
        lo = x;
      if (x > hi)
        hi = x;
    }
    if (mCount == 0)
    {
      mMin = lo;
      mMax = hi;
    }
    else
    {
      if (lo < mMin)
        mMin = lo;
      if (hi > mMax)
        mMax = hi;
    }
    mSum += sum;
    mCount += FRAMELENGTH;
  }

  void OutletProbe::update()
  {
    if (!mWatching)
      return;
    OutletProbeTask *task = getTask();
    task->mMutex.enter();
    if (mCount > 0)
    {
      mMean = mSum / mCount;
      mPeakToPeak = mMax - mMin;
      mSum = 0.0f;
      mCount = 0;
    }
    task->mMutex.leave();
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
