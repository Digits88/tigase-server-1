#!/bin/bash
#
# This is Tigase (http://www.tigase.org) server startup file.
#
# First parameter is a command (start, stop and so on...),
# second parameters is parameters file - the file where from
# environment variables are read like:
# JAVA_HOME
# JAVA_OPTIONS
# CLASSPATH
# TIGASE_HOME
# TIGASE_CONSOLE_LOG
# TIGASE_PID
# TIGASE_CONFIG
#
# If not given the script will try to search for the file and if
# not found default parameters will be used.

function usage()
{
  echo "Usage: $0 {start|stop|run|restart|check} params-file.conf"
  exit 1
}

if [ -z "${2}" ] ; then
  DEF_PARAMS="tigase.conf"
  # Gentoo style config location
  if [ -f "/etc/conf.d/${DEF_PARAMS}" ] ; then
		TIGASE_PARAMS="/etc/conf.d/${DEF_PARAMS}"
  elif [ -f "/etc/${DEF_PARAMS}" ] ; then
		TIGASE_PARAMS="/etc/${DEF_PARAMS}"
  elif [ -f "/etc/tigase/${DEF_PARAMS}" ] ; then
		TIGASE_PARAMS="/etc/tigase/${DEF_PARAMS}"
  else
		TIGASE_PARAMS=""
  fi
else
  TIGASE_PARAMS=${2}
fi

[[ -f "${TIGASE_PARAMS}" ]] && . ${TIGASE_PARAMS}

if [ -z "${JAVA_HOME}" ] ; then
  echo "JAVA_HOME is not set."
  echo "Please set it to correct value before starting the sever."
  exit 1
fi
if [ -z "${TIGASE_HOME}" ] ; then
  TIGASE_HOME=`dirname ${0}`
  TIGASE_HOME=`dirname ${TIGASE_HOME}`
  TIGASE_JAR=""
  for j in ${TIGASE_HOME}/jars/tigase-server*.jar ; do
		if [ -f ${j} ] ; then
	    TIGASE_JAR=${j}
	    break
		fi
  done
  if [ -z ${TIGASE_JAR} ] ; then
		echo "TIGASE_HOME is not set."
		echo "Please set it to correct value before starting the sever."
		exit 1
  fi
fi
if [ -z "${TIGASE_CONSOLE_LOG}" ] ; then
  if [ -w "${TIGASE_HOME}/logs/" ] ; then
		TIGASE_CONSOLE_LOG="${TIGASE_HOME}/logs/tigase-console.log"
  else
		TIGASE_CONSOLE_LOG="/dev/null"
  fi
fi
if [ -z "${TIGASE_PID}" ] ; then
  if [ -w "${TIGASE_HOME}/logs/" ] ; then
		TIGASE_PID="${TIGASE_HOME}/logs/tigase.pid"
  else
		if [ -w "/var/run/" ] ; then
	    TIGASE_PID="/var/run/tigase.pid"
		else
	    TIGASE_PID="/var/tmp/tigase.pid"
		fi
  fi
fi
if [ -z "${TIGASE_CONFIG}" ] ; then
  DEF_CONF="tigase-server.xml"
  # Gentoo style config location
  if [ -f "/etc/conf.d/${DEF_CONF}" ] ; then
		TIGASE_CONFIG="/etc/conf.d/${DEF_CONF}"
  elif [ -f "/etc/${DEF_CONF}" ] ; then
		TIGASE_CONFIG="/etc/${DEF_CONF}"
  elif [ -f "/etc/tigase/${DEF_CONF}" ] ; then
		TIGASE_CONFIG="/etc/tigase/${DEF_CONF}"
  elif [ -f "${TIGASE_HOME}/etc/${DEF_CONF}" ] ; then
		TIGASE_CONFIG="${TIGASE_HOME}/etc/${DEF_CONF}"
  else
		TIGASE_CONFIG="${TIGASE_HOME}/etc/${DEF_CONF}"
		echo "Can't find server configuration file."
		echo "Should be set in TIGASE_CONFIG variable"
		echo "Creating new configuration file in location:"
		echo "${TIGASE_CONFIG}"
  fi
fi

[[ -z "${TIGASE_RUN}" ]] && \
  TIGASE_RUN="tigase.server.XMPPServer -c ${TIGASE_CONFIG}  ${TIGASE_OPTIONS}"

[[ -z "${JAVA}" ]] && JAVA="${JAVA_HOME}/bin/java"

[[ -z "${CLASSPATH}" ]] || CLASSPATH="${CLASSPATH}:"

CLASSPATH="${CLASSPATH}${TIGASE_JAR}"

for lib in ${TIGASE_HOME}/libs/* ; do
  CLASSPATH="${CLASSPATH}:$lib"
done

TIGASE_CMD="${JAVA} ${JAVA_OPTIONS} -cp ${CLASSPATH} ${TIGASE_RUN}"

cd "${TIGASE_HOME}"

case "${1}" in
  start)
    echo "Starting Tigase: "

    if [ -f ${TIGASE_PID} ]
    then
      echo "Already Running!!"
      exit 1
    fi

    echo "STARTED Tigase `date`" >> ${TIGASE_CONSOLE_LOG}

    nohup sh -c "exec $TIGASE_CMD >>${TIGASE_CONSOLE_LOG} 2>&1" >/dev/null &
    echo $! > $TIGASE_PID
    echo "Tigase running pid="`cat $TIGASE_PID`
    ;;

  stop)
    PID=`cat $TIGASE_PID 2>/dev/null`
    echo "Shutting down Tigase: $PID"
    kill $PID 2>/dev/null
    sleep 2
    kill -9 $PID 2>/dev/null
    rm -f $TIGASE_PID
    echo "STOPPED `date`" >>${TIGASE_CONSOLE_LOG}
    ;;

  restart)
    $0 stop $2
    sleep 5
    $0 start $2
    ;;

  run)
    echo "Running Tigase: "

    if [ -f $TIGASE_PID ]
    then
      echo "Already Running!!"
      exit 1
    fi

    sh -c "exec $TIGASE_CMD"
    ;;

  check)
    echo "Checking arguments to Tigase: "
    echo "TIGASE_HOME     =  $TIGASE_HOME"
    echo "TIGASE_PARAMS   =  $TIGASE_PARAMS"
    echo "TIGASE_CONFIG   =  $TIGASE_CONFIG"
    echo "TIGASE_RUN      =  $TIGASE_RUN"
    echo "TIGASE_PID      =  $TIGASE_PID"
		echo "TIGASE_OPTIONS  =  $TIGASE_OPTIONS"
    echo "JAVA_OPTIONS    =  $JAVA_OPTIONS"
    echo "JAVA            =  $JAVA"
    echo "JAVA_CMD        =  $JAVA_CMD"
    echo "CLASSPATH       =  $CLASSPATH"
    echo "TIGASE_CMD      =  $TIGASE_CMD"
    echo "TIGASE_CONSOLE_LOG  =  $TIGASE_CONSOLE_LOG"
    echo

    if [ -f ${TIGASE_PID} ]
    then
      echo "Tigase running pid="`cat ${TIGASE_PID}`
      exit 0
    fi
    exit 1
    ;;
  zap)
		rm -f $TIGASE_PID
		;;

	*)
    usage
		;;
esac
