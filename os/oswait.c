/*
Copyright 1987-2012 Robert B. K. Dewar and Mark Emmer.

This file is part of Macro SPITBOL.

    Macro SPITBOL is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Macro SPITBOL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Macro SPITBOL.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
    oswait( pid )

    oswait() waits for the termination of the process with id pid.

    Parameters:
        pid     prcoess id
    Returns:
    nothing
*/

#include "port.h"
#if PIPES

#if UNIX
#include <signal.h>
#endif /* UNIX */

#if WINNT
#include <process.h>
#if _MSC_VER
extern int wait (int *status);
#endif
#endif

void
oswait (pid)
     int pid;
{
  int deadpid, status;
  struct chfcb *chptr;
#if UNIX
  SigType (*hstat) Params ((int)),
    (*istat) Params ((int)), (*qstat) Params ((int));

  istat = signal (SIGINT, SIG_IGN);
  qstat = signal (SIGQUIT, SIG_IGN);
  hstat = signal (SIGHUP, SIG_IGN);
#endif

  while ((deadpid = wait (&status)) != pid && deadpid != -1)
    {
      for (chptr = get_min_value (r_fcb, struct chfcb *); chptr != 0;
	   chptr = MK_MP (chptr->nxt, struct chfcb *))
	{
	  if (deadpid == MK_MP (MK_MP (chptr->fcp, struct fcblk *)->iob,
				struct ioblk *)->pid)
	    {
	      MK_MP (MK_MP (chptr->fcp, struct fcblk *)->iob,
		     struct ioblk *)->flg2 |= IO_DED;
	      break;
	    }
	}
    }

#if UNIX
  signal (SIGINT, istat);
  signal (SIGQUIT, qstat);
  signal (SIGHUP, hstat);
#endif /* UNIX */
}
#endif /* PIPES */