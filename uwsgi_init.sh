#!/bin/bash
# -*-Shell-script-*-
#
#/**
# * Title    : Python uWSGI daemon init script"
# * Auther   : Alex, Lee
# * Created  : 07-20-2018
# * Modified : 07-20-2018
# * E-mail   : cine0831@gmail.com
#**/
#
#set -e
#set -x

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/home/venv_fileupload/bin
DAEMON=/home/python_virtualenv/bin/uwsgi 
RUN_DIR=/var/run/uwsgi
LOG_DIR=/home/log/vendor/fileupload
VASSALS_DIR=/home/vendor/fileupload/uwsgi/vassals
NAME=uwsgi
DESC=uwsgi-emperor
OWNER=nobody
GROUP=nobody

[[ -x $DAEMON ]] || exit 0
[[ -d $RUN_DIR ]] || mkdir $RUN_DIR && chown $OWNER:$GROUP $RUN_DIR
[[ -d $LOG_DIR ]] || mkdir $LOG_DIR && chown $OWNER:$GROUP $LOG_DIR

do_pid_check()
{
    local PIDFILE=$1
    [[ -f $PIDFILE ]] || return 0
    local PID=$(cat $PIDFILE)
    for p in $(pgrep $NAME); do
        [[ $p == $PID ]] && return 1
    done
    return 0
}


do_start()
{
    local PIDFILE=$RUN_DIR/$NAME.pid
    local START_OPTS=" \
        --emperor $VASSALS_DIR \
        --pidfile $PIDFILE \
        --master \
        --uid nobody \
        --gid nobody \
        --daemonize $LOG_DIR/uwsgi_emperor.log"
    if do_pid_check $PIDFILE; then
        $DAEMON $START_OPTS
    else
        echo "Already running!"
    fi
}

send_sig()
{
    local PIDFILE=$RUN_DIR/$NAME.pid
    set +e
    [[ -f $PIDFILE ]] && kill $1 $(cat $PIDFILE) > /dev/null 2>&1
    set -e
}

wait_and_clean_pidfile()
{
    local PIDFILE=$RUN_DIR/$NAME.pid
    until do_pid_check $PIDFILE; do
        echo -n "";
    done
    rm -f $PIDFILE
}

do_stop()
{
    send_sig -3
    wait_and_clean_pidfile
}

do_reload()
{
    send_sig -1
}

do_force_reload()
{
    send_sig -15
}

get_status()
{
    send_sig -10
}

case "$1" in
    start)
        echo "Starting $DESC: "
        do_start
        echo "$NAME."
        ;;
    stop)
        echo -n "Stopping $DESC: "
        do_stop
        echo "$NAME."
        ;;
    reload)
        echo -n "Reloading $DESC: "
        do_reload
        echo "$NAME."
        ;;
    force-reload)
        echo -n "Force-reloading $DESC: "
        do_force_reload
        echo "$NAME."
       ;;
    restart)
        echo  "Restarting $DESC: "
        do_stop
        sleep 1
        do_start
        echo "$NAME."
        ;;
    status)
        get_status
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|reload|force-reload|status}">&2
        exit 1
        ;;
esac
