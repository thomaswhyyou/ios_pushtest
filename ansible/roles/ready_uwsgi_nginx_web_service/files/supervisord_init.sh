#! /bin/sh
#
########### Mashed up with:
# http://bazaar.launchpad.net/~ubuntu-branches/ubuntu/trusty/supervisor/trusty/view/head:/debian/supervisor.init;
# https://github.com/thomaswhyyou/ansible-tutorial/blob/master/devops/templates/supervisord.sh
###########
#
# skeleton  example file to build /etc/init.d/ scripts.
#       This file should be used to construct scripts for /etc/init.d.
#
#       Written by Miquel van Smoorenburg <miquels@cistron.nl>.
#       Modified for Debian
#       by Ian Murdock <imurdock@gnu.ai.mit.edu>.
#               Further changes by Javier Fernandez-Sanguino <jfs@debian.org>
#
# Version:  @(#)skeleton  1.9  26-Feb-2001  miquels@cistron.nl
#
### BEGIN INIT INFO
# Provides:          supervisor
# Required-Start:    $remote_fs $network $named
# Required-Stop:     $remote_fs $network $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop supervisor
# Description:       Start/stop supervisor daemon and its configured
#                    subprocesses.
### END INIT INFO

. /lib/lsb/init-functions

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/supervisord
SUPERVISORCTL=/usr/local/bin/supervisorctl
NAME=supervisord
DESC=supervisor

test -x $DAEMON || exit 0

LOGDIR=/var/log/supervisor
PIDFILE=/var/run/$NAME.pid
DODTIME=5                   # Time to wait for the server to die, in seconds
                            # If this value is set too low you might not
                            # let some servers to die gracefully and
                            # 'restart' will not work

# Include supervisor defaults if available
if [ -f /etc/default/$NAME ] ; then
    . /etc/default/$NAME
fi
DAEMON_OPTS="-c /etc/supervisord.conf $DAEMON_OPTS"

set -e

running_pid()
{
    # Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$2
    [ -z "$pid" ] && return 1
    [ ! -d /proc/$pid ] &&  return 1
    (cat /proc/$pid/cmdline | tr "\000" "\n"|grep -q $name) || return 1
    return 0
}

running()
{
# Check if the process is running looking at /proc
# (works for all users)

    # No pidfile, probably no daemon present
    [ ! -f "$PIDFILE" ] && return 1
    # Obtain the pid and check it against the binary name
    pid=`cat $PIDFILE`
    running_pid $pid $DAEMON || return 1
    return 0
}

force_stop() {
# Forcefully kill the process
    [ ! -f "$PIDFILE" ] && return
    if running ; then
        kill -15 $pid
        # Is it really dead?
        [ -n "$DODTIME" ] && sleep "$DODTIME"s
        if running ; then
            kill -9 $pid
            [ -n "$DODTIME" ] && sleep "$DODTIME"s
            if running ; then
                echo "Cannot kill $LABEL (pid=$pid)!"
                exit 1
            fi
        fi
    fi
    rm -f $PIDFILE
    return 0
}

do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started

    if $SUPERVISORCTL status | grep -q "unix:///tmp/supervisor.sock no such file"; then
        $SUPERVISORD $DAEMON_OPTS
        echo "supervisord started successfully"
        return 0
    fi

    if $SUPERVISORCTL status | grep -qv "unix:///tmp/supervisor.sock no such file"; then
        echo "supervisord is already running"
        return 1
    fi

    echo "could not start supervisord"
    return 2
}

do_stop() {
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    if $SUPERVISORCTL status | grep -q "unix:///tmp/supervisor.sock no such file"; then
        echo "supervisord already stopped"
        return 1
    else
        if $SUPERVISORCTL shutdown | grep -q "Shut down"; then
            while $SUPERVISORCTL shutdown | grep -q "already shutting down"
            do
                sleep 1
            done
            echo 'supervisor shutdown successfully'
            return 0
        else
            echo "could not stop supervisord"
            return 2
        fi
    fi
}

case "$1" in
  start)
    echo -n "Starting $DESC: "
    start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON -- $DAEMON_OPTS
    test -f $PIDFILE || sleep 1
        if running ; then
            echo "$NAME."
        else
            echo " ERROR."
        fi
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    do_stop
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac

    # echo -n "Stopping $DESC: "
    # start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
    # echo "$NAME."
    ;;
  force-stop)
    echo -n "Forcefully stopping $DESC: "
        force_stop
        if ! running ; then
            echo "$NAME."
        else
            echo " ERROR."
        fi
    ;;
  #reload)
    #
    #   If the daemon can reload its config files on the fly
    #   for example by sending it SIGHUP, do it here.
    #
    #   If the daemon responds to changes in its config file
    #   directly anyway, make this a do-nothing entry.
    #
    # echo "Reloading $DESC configuration files."
    # start-stop-daemon --stop --signal 1 --quiet --pidfile \
    #   /var/run/$NAME.pid --exec $DAEMON
  #;;
  restart|force-reload)
    log_daemon_msg "Restarting $NAME"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
            0) log_end_msg 0 ;;
            1) log_end_msg 1 ;; # Old process is still running
            *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
        ;;
    esac

    # echo -n "Restarting $DESC: "
    # start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
    # [ -n "$DODTIME" ] && sleep $DODTIME
    # start-stop-daemon --start --quiet --pidfile $PIDFILE --startas $DAEMON -- $DAEMON_OPTS
    # echo "$NAME."
    ;;
  status)
    if running ;  then
        $SUPERVISORCTL status
        echo
    else
        echo "not running."
        exit 1
    fi
    ;;
  *)
    N=/etc/init.d/$NAME
    # echo "Usage: $N {start|stop|restart|reload|force-reload}" >&2
    echo "Usage: $N {start|stop|restart|force-reload|status|force-stop}" >&2
    exit 1
    ;;
esac

exit 0
