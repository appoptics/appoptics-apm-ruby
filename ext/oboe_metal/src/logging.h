// Copyright (c) 2020 SolarWinds, LLC.
// All rights reserved.

#ifndef LOGGING_H
#define LOGGING_H

#include <iostream>
#include <sstream>

#include "profiling.h"

extern "C" int oboe_gettimeofday(struct timeval *tv);

class Logging {
   public:
    static bool log_profile_entry(string &prof_op_id, pid_t tid, long interval);
    static bool log_profile_exit(string &prof_op_id, pid_t tid, long *omitted, int num_omitted);
    static bool log_profile_snapshot(string &prof_op_id,
                                     long timestamp,
                                     std::vector<FrameData> const &new_frames,
                                     long exited_frames,
                                     long total_frames,
                                     long *omitted,
                                     int num_omitted,
                                     pid_t tid);

   private:
    static Event *createEvent(string &prof_op_id, bool entry_event = false);
    static bool log_profile_event(Event *event);
};

#endif  //LOGGING_H
